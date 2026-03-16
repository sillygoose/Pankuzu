import ExternalAccessory
import CoreLocation
import OSLog

import DokoTypes
import DokoLogging
import DokoSharing
import DokoPacketManager
import ObdLinkCore
import DokoVehicleManager

enum ObdLinkError: Error, LocalizedError {
  case accessoryNotFound(String)
  case sessionFailed
  case inputStreamNotAvailable
  case outputStreamNotAvailable
  case missingDisconnectUserInfo
  case accessorySerialNumberMismatch(String, String)

  var errorDescription: String {
    switch self {
    case .accessoryNotFound(let protocolString):
      "No protocol '\(protocolString)'"
    case .sessionFailed:
      "Failed to create EA session"
    case .inputStreamNotAvailable:
      "Failed to create session input stream"
    case .outputStreamNotAvailable:
      "Failed to create session output stream"
    case .missingDisconnectUserInfo:
      "Missing disconnect UserInfo"
    case .accessorySerialNumberMismatch(let expected, let found):
      "Serial number mismatch: expected '\(expected)', found '\(found)'"
    }
  }
}

@MainActor
public final class ObdLinkManager: NSObject, @MainActor StreamDelegate {
  private let logger = Logger(subsystem: "com.unchan.doko", category: "ObdLinkManager")

  public static let shared = ObdLinkManager()

  private let protocolString = "com.obdlink"

  private var obdResponseStream: AsyncStream<String>!
  private var obdResponseStreamContinuation: AsyncStream<String>.Continuation!
  private var commandProcessingTaskHandle: Task<Void, Never>?

  private var responseBuffer = Data()
  private var accessory: EAAccessory?
  private var session: EASession?

  @Shared(.connectedAccessoryName) var connectedAccessoryName
  @Shared(.connectedAccessorySerialNumber) var connectedAccessorySerialNumber
  @Shared(.connectedVehicleInterface) var connectedVehicleInterface
  @Shared(.backgroundMode) var backgroundMode
  @Shared(.accessorySerialNumber) var accessorySerialNumber
  
  private override init() {
    super.init()

    EAAccessoryManager.shared().registerForLocalNotifications()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(connectAccessory),
      name: .EAAccessoryDidConnect,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(disconnectAccessory),
      name: .EAAccessoryDidDisconnect,
      object: nil
    )
    startBackgroundModeObservation()
  }

  private func startBackgroundModeObservation() {
    @Shared(.backgroundMode) var observedBackgroundMode
    Task { [weak self] in
      guard let self else { return }
      var old: Bool = observedBackgroundMode
      for await newMode in $observedBackgroundMode.publisher.values {
        guard old != newMode else { continue }
        old = newMode
        if newMode {
          self.connect()
        } else {
          self.disconnect()
        }
      }
    }
  }

  public func connect() {
    $connectedAccessoryName.withLock { $0 = nil }
    $connectedAccessorySerialNumber.withLock { $0 = nil }
    guard backgroundMode else { return }
    let accessories = EAAccessoryManager.shared().connectedAccessories
    do {
      guard let newAccessory = accessories.first(where: { $0.protocolStrings.contains(protocolString) }) else {
        throw ObdLinkError.accessoryNotFound(self.protocolString)
      }
      if let requiredSerialNumber = accessorySerialNumber, newAccessory.serialNumber != requiredSerialNumber {
        throw ObdLinkError.accessorySerialNumberMismatch(requiredSerialNumber, newAccessory.serialNumber)
      }
      guard let newSession = EASession(accessory: newAccessory, forProtocol: protocolString) else {
        throw ObdLinkError.sessionFailed
      }
      guard let inputStream = newSession.inputStream else {
        throw ObdLinkError.inputStreamNotAvailable
      }
      guard let  outputStream = newSession.outputStream else {
        throw ObdLinkError.outputStreamNotAvailable
      }

      inputStream.delegate = self
      outputStream.delegate = self

      inputStream.schedule(in: .main, forMode: .default)
      outputStream.schedule(in: .main, forMode: .default)

      inputStream.open()
      outputStream.open()

      logger.debug("\(timestamp()) ObdLinkManager.connect(): \(newAccessory.name)")
      self.accessory = newAccessory
      self.session = newSession
      var obdResponseContinuation: AsyncStream<String>.Continuation!
      self.obdResponseStream = AsyncStream(bufferingPolicy: .unbounded) { continuation in
        obdResponseContinuation = continuation
      }
      self.obdResponseStreamContinuation = obdResponseContinuation

      self.commandProcessingTaskHandle = commandProcessingTask()
      $connectedAccessoryName.withLock { $0 = newAccessory.name }
      $connectedAccessorySerialNumber.withLock { $0 = newAccessory.serialNumber }
      DokoLogging.shared.postLoggingResponse(.connect("\(newAccessory.name)"))
    } catch let error as ObdLinkError {
      self.logger.error("\(timestamp()) ObdLinkManager.connect: \(error.errorDescription)")
      DokoLogging.shared.postLoggingResponse(.error("\(error.errorDescription)"))
    } catch {
      self.logger.error("\(timestamp()) ObdLinkManager.connect: \(String(describing: error))")
      DokoLogging.shared.postLoggingResponse(.error("\(String(describing: error))"))
    }
  }

  public func disconnect() {
    self.logger.debug("\(timestamp()) ObdLinkManager.disconnect()")
    self.obdResponseStream = nil
    self.obdResponseStreamContinuation = nil
    self.commandProcessingTaskHandle?.cancel()
    self.commandProcessingTaskHandle = nil
    let accessoryName = self.accessory?.name ?? "Unknown accessory"
    guard let session = self.session else {
      DokoLogging.shared.postLoggingResponse(.error("no session for \(accessoryName)"))
      return
    }
    session.inputStream?.close()
    session.inputStream?.remove(from: .main, forMode: .default)
    session.outputStream?.close()
    session.outputStream?.remove(from: .main, forMode: .default)
    self.session = nil
    self.accessory = nil
    $connectedAccessoryName.withLock { $0 = nil }
    $connectedAccessorySerialNumber.withLock { $0 = nil }
    DokoLogging.shared.postLoggingResponse(.disconnect("\(accessoryName)"))
  }

  func commandProcessingTask() -> Task<Void, Never> {
    Task {
      self.logger.info("\(timestamp()) ObdLinkManager.commandProcessingTask() started")
      while !Task.isCancelled {
        guard let outputStream = self.session?.outputStream, outputStream.hasSpaceAvailable else {
          self.logger.error("\(timestamp()) No active session or space to write command.")
          self.commandProcessingTaskHandle?.cancel()
          self.commandProcessingTaskHandle = nil
          return
        }
        guard let dokoCommandPacket = await DokoPacketManager.shared.removeDokoPacket() else {
          self.logger.error("\(timestamp()) ObdLinkManager.commandProcessingTask(): packet error on removeDokoCommandPacket()")
          self.commandProcessingTaskHandle?.cancel()
          self.commandProcessingTaskHandle = nil
          return
        }
        guard let commandPacket = await connectedVehicleInterface.translateDokoCommandPacket(using: dokoCommandPacket) else {
          DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.commandProcessingTask: packet translation failed"))
          continue
        }

        var obdResponseDictionary: ObdResponseDictionary = [:]
        var errorPackets = 0
        for command in commandPacket.commands {
          if Task.isCancelled { return }
          guard let obdLinkCommand = await connectedVehicleInterface.vehicleObdCommand(command) else {
            self.logger.error("\(timestamp()) No OBD command in vehicle dictionary: \(command.description)")
            DokoLogging.shared.postLoggingResponse(.error("ObdDokoVehicleManager.obdLinkCommandLookup(\(command.description))"))
            errorPackets += 1
            continue
          }
          
          var commandResponse: String = ""
          if !obdLinkCommand.isEmpty {
            guard let commandData = "\(obdLinkCommand)\r".data(using: .ascii) else {
              self.logger.error("\(timestamp()) ObdLinkManager.commandProcessingTask: failed to encode command '\(obdLinkCommand)'")
              DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.commandProcessingTask: failed to encode command '\(obdLinkCommand)'"))
              errorPackets += 1
              continue
            }
            _ = writeAll(commandData, to: outputStream)

            guard let trueCommandResponse = await self.waitForObdCommandResponse() else {
              self.logger.error("\(timestamp()) ObdLinkManager.commandProcessingTask: error reading response for: '\(command.description)'")
              DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager..commandProcessingTask: error reading response for: '\(command.description)'"))
              errorPackets += 1
              continue
            }
            commandResponse = trueCommandResponse
          }

          let obdCommandResponse = await connectedVehicleInterface.vehicleObdCommandResponse(command, commandResponse, rawCommand: obdLinkCommand)
          switch obdCommandResponse.result {
          case .ok:
            obdResponseDictionary[command] = obdCommandResponse
          case .error(let error):
            self.logger.error("\(timestamp()) \(obdCommandResponse.response.description): \(error.description)")
            obdResponseDictionary[command] = obdCommandResponse
            errorPackets += 1
          default:
            let obdError = ObdResult.getObdError(errorString: commandResponse)
            self.logger.error("\(timestamp()) \(obdCommandResponse.response.description): \(obdError.description)")
            obdResponseDictionary[command] = obdCommandResponse
            errorPackets += 1
          }
        }

        let responsePacket = ObdResponsePacket(
          queuedAt: commandPacket.queuedAt,
          type: commandPacket.type,
          errors: errorPackets,
          responses: obdResponseDictionary
        )
        await DokoLogging.shared.postObdResponsePacket(responsePacket: responsePacket)
        let dokoResponsePacket = await connectedVehicleInterface.vehicleDokoResponsePacket(responsePacket)
        await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
      }
      self.logger.info("\(timestamp()) ObdLinkManager.commandProcessingTask() stopped")
    }
  }

  private func writeAll(_ data: Data, to stream: OutputStream) -> Bool {
    var remaining = data.count
    var offset = 0
    return data.withUnsafeBytes { raw in
      guard let base = raw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return false }
      while remaining > 0 {
        let written = stream.write(base.advanced(by: offset), maxLength: remaining)
        if written <= 0 { return false }
        remaining -= written
        offset += written
      }
      return true
    }
  }

  private func waitForObdCommandResponse() async -> String? {
    guard let stream = obdResponseStream else { return nil }
    var iterator = stream.makeAsyncIterator()
    if let next = await iterator.next() {
      return next
    }
    DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.waitForObdCommandResponse(nil)"))
    return nil
  }

  @MainActor
  public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    let streamType = (aStream as? InputStream) != nil ? "inputStream" : ((aStream as? OutputStream) != nil ? "outputStream" : "Unknown")
    switch eventCode {
    case .hasBytesAvailable:
      guard let inputStream = aStream as? InputStream else { return }
      readAvailableBytes(from: inputStream)
    case .openCompleted:
      logger.debug("\(timestamp()) ObdLinkManager.\(streamType) stream opened")
      DokoLogging.shared.postLoggingResponse(.connect("ObdLinkManager.\(streamType)(opened)"))
    case .errorOccurred:
      self.logger.error("\(timestamp()) ObdLinkManager.\(streamType)(\(aStream.streamError?.localizedDescription ?? "Unknown error")")
      DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.\(streamType)(\(aStream.streamError?.localizedDescription ?? "Unknown error")"))
      disconnect()
      guard backgroundMode else { break }
      Task {
        try? await Task.sleep(for: .seconds(1))
        let accessories = EAAccessoryManager.shared().connectedAccessories
        if accessories.contains(where: { $0.protocolStrings.contains(self.protocolString) }) {
          self.connect()
        } else {
          self.logger.error("\(timestamp()) ObdLinkManager.\(streamType).errorOccurred(no accessory found)")
          DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.\(streamType).errorOccurred(no accessory found)"))
        }
      }
    case .endEncountered:
      self.logger.error("\(timestamp()) ObdLinkManager.\(streamType)(.endEncountered)")
      DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.\(streamType)(.endEncountered)"))
      disconnect()
      guard backgroundMode else { break }
      Task {
        try? await Task.sleep(for: .seconds(1))
        let accessories = EAAccessoryManager.shared().connectedAccessories
        if accessories.contains(where: { $0.protocolStrings.contains(self.protocolString) }) {
          self.connect()
        } else {
          self.logger.error("\(timestamp()) ObdLinkManager.\(streamType).endEncountered(no accessory found)")
          DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.\(streamType).endEncountered(no accessory found)"))
        }
      }
    default:
      break
    }
  }

  private func readAvailableBytes(from stream: InputStream) {
    let bufferSize = 128
    var buffer = [UInt8](repeating: 0, count: bufferSize)
    while stream.hasBytesAvailable {
      let bytesRead = stream.read(&buffer, maxLength: bufferSize)
      if bytesRead > 0 {
        responseBuffer.append(contentsOf: buffer.prefix(bytesRead))
        if let responseString = String(data: responseBuffer, encoding: .ascii), responseString.hasSuffix(">") {
          var trimmedResponse = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
          trimmedResponse = trimmedResponse.replacingOccurrences(of: ">", with: "")
          trimmedResponse = trimmedResponse.replacingOccurrences(of: "\r", with: "")
          obdResponseStreamContinuation.yield(trimmedResponse)
          responseBuffer.removeAll()
        }
      } else if bytesRead < 0, let error = stream.streamError {
        self.logger.error("\(timestamp()) Stream read error: \(error.localizedDescription)")
        DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.readAvailableBytes: \(error.localizedDescription)"))
        break
      }
    }
  }

  public func setBackgroundMode(_ enabled: Bool) {
    $backgroundMode.withLock { $0 = enabled }
  }

  @objc func connectAccessory(connectingAccessory: NotificationCenter.Publisher.Output) {
    guard backgroundMode else { return }
    if session == nil {
      connect()
    } else {
      DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.connectAccessory: session exists"))
    }
  }

  @objc func disconnectAccessory(disconnectingAccessory: NotificationCenter.Publisher.Output) {
    do {
      guard let userinfo = disconnectingAccessory.userInfo else { throw ObdLinkError.missingDisconnectUserInfo }
      if let disconnectingAccessory = userinfo[EAAccessoryKey] as? EAAccessory {
        if self.accessory?.connectionID == disconnectingAccessory.connectionID {
          disconnect()
        }
      }
      connect()
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("ObdLinkManager.disconnectAccessory: \(String(describing: error))"))
    }
  }
}
