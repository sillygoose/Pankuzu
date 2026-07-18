import ExternalAccessory
import Combine
import OSLog
import WidgetKit

import DokoTypes
import DokoSharing
import DokoSchema
import DokoLogging
import DokoABRP
import CoreLocationManager
import DokoPacketManager
import DokoVehicleManager
import DokoNotificationManager
import DokoLiveActivityManager
import ObdLinkManager

@DokoEngineActor
public final class DokoStateEngine {
  let logger = Logger(subsystem: "com.unchan.doko", category: "StateEngine")

  public static let shared = DokoStateEngine()

  private var vehicleTypeObservationTask: Task<Void, Never>?
  private var vehicleStateObservationTask: Task<Void, Never>?

  private var consecutiveResponsePacketErrors: Int = 0
  private var responseProcessingTask: Task<Void, Never>?
  private var stateEngineTask: Task<Void, Never>?

  var dokoSchedulerTask: Task<Void, Never>?

  @Shared(.vehicleState) var vehicleState
  @Shared(.connectedAccessoryName) var accessoryName
  @Shared(.activeSession) var activeSession
  @Shared(.appSettings) var appSettings

  var tripInProgress: Trip.Draft?
  var chargeInProgress: Charge.Draft?

  private init() {
    accessoryNameObservation()
  }

  private func startStateEngine() async {
    self.logger.info("\(timestamp()) SE.startStateEngine")
    DokoLogging.shared.postLoggingResponse(.info("SE.startStateEngine"))
    self.responseProcessingTask = self.dokoResponseProcessing()
  }

  private func stopStateEngine() async {
    stateEngineTask?.cancel()
    stateEngineTask = nil
    responseProcessingTask?.cancel()
    responseProcessingTask = nil
    self.logger.info("\(timestamp()) SE.stopStateEngine")
    DokoLogging.shared.postLoggingResponse(.info("SE.stopStateEngine"))
    $vehicleState.withLock { $0 = .reset }
  }

  enum StateEngineError: Error, LocalizedError {
    case unexpectedStatePacket(VehicleState, DokoPacketType)
    case unexpectedNextState
    case unknownVehicle, excessiveErrors
    case missingTripID, missingChargeID
    case tripDraftError, chargeDraftError
    case chargeWriteError, chargeUpdateError, chargeArgumentError, chargeLocationError
    case chargeHistoryWriteError, chargeHistoryArgumentError

    var errorDescription: String {
      switch self {
      case let .unexpectedStatePacket(state, packet):
        "Unexpected response packet '\(packet.description)' in state '\(state.description)'"
      case .unexpectedNextState:
        "An unexpected state was received"
      case .unknownVehicle:
        "Expected an active vehicle but was missing"
      case .excessiveErrors:
        "Excessive packet errors"
      case .missingTripID:
        "Missing the trip ID"
      case .missingChargeID:
        "Missing the charge ID"
      case .tripDraftError:
        "Missing the Trip draft record"
      case .chargeDraftError:
        "Missing the Charge draft record"
      case .chargeWriteError:
        "Error writing a Charge record"
      case .chargeUpdateError:
        "Error updating the Charge draft record"
      case .chargeArgumentError:
        "Error extracting Charge arguments"
      case .chargeLocationError:
        "Error processing Charge location"
      case .chargeHistoryWriteError:
        "Error writing a ChargeHistory record"
      case .chargeHistoryArgumentError:
        "Error extracting ChargeHistory arguments"
      }
    }
  }

  private func dokoResponseProcessing() -> Task<Void, Never> {
    Task {
      @Shared(.connectedVehicleInterface) var connectedVehicle
      @Shared(.chargeUpdateResponses) var chargeUpdateResponses
      @Shared(.tripUpdateResponses) var tripUpdateResponses

      self.logger.info("\(timestamp()) SE.obdResponseProcessing() started")
      while !Task.isCancelled {
        guard let dokoResponsePacket = await DokoPacketManager.shared.removeDokoResponsePacket() else { return }
        do {
          DokoLogging.shared.postLoggingResponse(.schedulers("processing: \(dokoResponsePacket.type.description)"))
          DokoLogging.shared.postDokoResponsePacket(responsePacket: dokoResponsePacket)
          switch dokoResponsePacket.type {
          case .reset:
            guard case .reset = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            let nextState = dokoResponsePacket.nextState ?? .reset
            $vehicleState.withLock { $0 = nextState }

          case .vin:
            guard case .vin = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            var nextState: VehicleState = .vin
            if let vin = dokoResponsePacket.vin {
              if let _ = DokoVehicleManager.shared.setVin(vin: vin) {
                nextState = dokoResponsePacket.nextState ?? .vin
              }
              else {
                await DokoNotificationManager.shared.unsupportedVehicleNotification()
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run { ObdLinkManager.shared.disconnect() }
                nextState = .vin
              }
            }
            $vehicleState.withLock { $0 = nextState }

          case .vehicleCustomization:
            guard case .vehicleCustomization = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            let nextState = dokoResponsePacket.nextState ?? .vehicleCustomization
            $vehicleState.withLock { $0 = nextState }
            
          case .idle:
            guard case .idle = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            let nextState = dokoResponsePacket.nextState ?? .idle
            if nextState == .tripStarting {
              $tripUpdateResponses.withLock { $0 = [:] }
              await CoreLocationManager.shared.startLocationUpdates()
              await DokoNotificationManager.shared.startTripNotification(vehicle: connectedVehicle.vehicle?.makeModel ?? "Unknown")
            } else if nextState == .acChargeStarting || nextState == .dcChargeStarting {
              $chargeUpdateResponses.withLock { $0 = [:] }
              await CoreLocationManager.shared.startLocationUpdates()
              await DokoNotificationManager.shared.startChargeNotification(vehicle: connectedVehicle.vehicle?.makeModel ?? "Unknown")
            }
            if nextState != .idle { $vehicleState.withLock { $0 = nextState } }

          case .tripStarting:
            guard case .tripStarting = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            var nextState = dokoResponsePacket.nextState ?? .tripStarting
            if nextState == .tripInProgress {
              do {
                let vehicleID = connectedVehicle.vehicle?.id
                self.tripInProgress = try Trip.postTripStartRecord(
                  vehicleID: vehicleID,
                  tripStartResponse: dokoResponsePacket
                )
                await CoreLocationManager.shared.startPacketUpdates()
                Task { await LiveActivityManager.shared.startTrip() }
                $activeSession.withLock { $0 = .trip }
              } catch let error as StateEngineError {
                DokoLogging.shared.postLoggingResponse(.error(".tripStarting: \(error.errorDescription)"))
                nextState = .tripStarting
              } catch {
                DokoLogging.shared.postLoggingResponse(.error(".tripStarting: \(String(describing: error)))"))
                nextState = .tripStarting
              }
            }
            $vehicleState.withLock { $0 = nextState }
            
          case .tripInProgress:
            guard case .tripInProgress = vehicleState else {
              throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type)
            }
            let nextState = dokoResponsePacket.nextState ?? .tripInProgress
            if nextState != self.vehicleState {
              await CoreLocationManager.shared.stopPacketUpdates()
              $vehicleState.withLock { $0 = nextState }
            }

          case .tripUpdate:
            guard case .tripInProgress = vehicleState else {
              throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type)
            }
            guard let tripDraft = self.tripInProgress else { throw StateEngineError.tripDraftError }
            ABRPManager.shared.sendTripTelemetry(packet: dokoResponsePacket)
            do {
              self.tripInProgress = try Trip.updateTripRecord(tripDraft: tripDraft, tripDataResponse: dokoResponsePacket)
              $tripUpdateResponses.withLock { $0 = dokoResponsePacket.responses }
              Task { await LiveActivityManager.shared.updateTrip(tripData: dokoResponsePacket) }
            } catch let error as StateEngineError {
              DokoLogging.shared.postLoggingResponse(.error(".tripUpdate: \(error.errorDescription)"))
            } catch {
              DokoLogging.shared.postLoggingResponse(.error(".tripUpdate: \(String(describing: error)))"))
            }

          case .tripEnding:
            guard case .tripEnding = vehicleState else {
              throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type)
            }
            guard let tripDraft = self.tripInProgress else { throw StateEngineError.tripDraftError }
            var nextState = dokoResponsePacket.nextState ?? .tripEnding
            if nextState == .idle {
              do {
                let _ = try Trip.postTripEndRecord(tripDraft: tripDraft, tripEndResponse: dokoResponsePacket)
                await CoreLocationManager.shared.stopLocationUpdates()
                Task { await LiveActivityManager.shared.endTrip(tripEnd: dokoResponsePacket) }
                self.tripInProgress = nil
                $activeSession.withLock { $0 = nil }
              } catch let error as StateEngineError {
                DokoLogging.shared.postLoggingResponse(.error(".tripEnding: \(error.errorDescription)"))
                nextState = .tripEnding
              } catch {
                DokoLogging.shared.postLoggingResponse(.error(".tripEnding: \(String(describing: error)))"))
                nextState = .tripEnding
              }
            }
            $vehicleState.withLock { $0 = nextState }

          case .tripCorePosition:
            guard case .tripInProgress = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            guard let tripID = tripInProgress?.id else { throw StateEngineError.missingTripID }
            do {
              try Trip.postTripPositionRecord(tripID: tripID, tripPositionPacket: dokoResponsePacket)
            } catch {
              DokoLogging.shared.postLoggingResponse(.error(".tripCorePosition: \(String(describing: error))"))
            }

          case .tripCoreElevation:
            guard case .tripInProgress = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            guard let tripID = tripInProgress?.id else { throw StateEngineError.missingTripID }
            do {
              try Trip.postTripElevationRecord(tripID: tripID, tripElevationPacket: dokoResponsePacket)
            } catch {
              DokoLogging.shared.postLoggingResponse(.error(".tripCoreElevation: \(String(describing: error))"))
            }

          case .tripData:
            guard case .tripInProgress = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            guard let tripID = self.tripInProgress?.id else { throw StateEngineError.missingTripID }
            do {
              try Trip.postTripData(tripID: tripID, tripDataPacket: dokoResponsePacket)
            } catch {
              DokoLogging.shared.postLoggingResponse(.error(".tripData: \(String(describing: error))"))
            }

          case .tripWeather:
            guard case .tripInProgress = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            guard let tripID = self.tripInProgress?.id else { throw StateEngineError.missingTripID }
            guard var tripDraft = self.tripInProgress else { throw StateEngineError.tripDraftError }
            do {
              if tripDraft.weatherTempStart == nil {
                tripDraft.weatherTempStart = dokoResponsePacket.weather?.temperature
                tripDraft.weatherTempEnd = dokoResponsePacket.weather?.temperature
                tripDraft.weatherTempMeanWeighted = dokoResponsePacket.weather?.temperature
                tripDraft.weatherConditionsStart = dokoResponsePacket.weather?.conditionSymbol
                tripDraft.weatherConditionsEnd = dokoResponsePacket.weather?.conditionSymbol
                DokoLogging.shared.postLoggingResponse(.info(".tripWeather updated tripDraft"))
              }
              try Trip.postTripWeatherRecord(tripID: tripID, tripWeatherPacket: dokoResponsePacket)
              self.tripInProgress = try Trip.updateTripRecord(tripDraft: tripDraft, tripDataResponse: dokoResponsePacket)
            } catch {
              DokoLogging.shared.postLoggingResponse(.error(".tripWeather: \(String(describing: error))"))
            }

          case .acChargeStarting:
            guard case .acChargeStarting = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            var nextState = dokoResponsePacket.nextState ?? .acChargeStarting
            if nextState == .acChargeInProgress {
              do {
                let vehicleID = connectedVehicle.vehicle?.id
                self.chargeInProgress = try Charge.postChargeStartRecord(
                  vehicleID: vehicleID,
                  dcfcCharge: false,
                  chargeStartResponse: dokoResponsePacket
                )
                await CoreLocationManager.shared.stopLocationUpdates()
                Task { await LiveActivityManager.shared.startCharge() }
                $activeSession.withLock { $0 = .acCharge }
              } catch {
                DokoLogging.shared.postLoggingResponse(.error(".acChargeStarting: \(String(describing: error))"))
                nextState = .acChargeStarting
              }
            }
            $vehicleState.withLock { $0 = nextState }

          case .acChargeInProgress:
            guard case .acChargeInProgress = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            let nextState = dokoResponsePacket.nextState ?? .acChargeInProgress
            if nextState != self.vehicleState { $vehicleState.withLock { $0 = nextState } }

          case .acChargeEnding:
            guard case .acChargeEnding = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            guard let chargeDraft = self.chargeInProgress else { throw StateEngineError.chargeArgumentError }
            var nextState = dokoResponsePacket.nextState ?? .acChargeEnding
            if nextState == .idle {
              do {
                let _ = try Charge.postChargeEndRecord(chargeDraft: chargeDraft, chargeEndResponse: dokoResponsePacket)
                self.chargeInProgress = nil
                Task { await LiveActivityManager.shared.endCharge(chargeData: dokoResponsePacket) }
                $activeSession.withLock { $0 = nil }
              } catch {
                DokoLogging.shared.postLoggingResponse(.error(".acChargeEnding: \(String(describing: error))"))
                nextState = .acChargeEnding
              }
            }
            $vehicleState.withLock { $0 = nextState }

          case .dcChargeStarting:
            guard case .dcChargeStarting = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            var nextState = dokoResponsePacket.nextState ?? .dcChargeStarting
            if nextState == .dcChargeInProgress {
              do {
                let vehicleID = connectedVehicle.vehicle?.id
                self.chargeInProgress = try Charge.postChargeStartRecord(
                  vehicleID: vehicleID,
                  dcfcCharge: true,
                  chargeStartResponse: dokoResponsePacket
                )
                await CoreLocationManager.shared.stopLocationUpdates()
                Task { await LiveActivityManager.shared.startCharge() }
                $activeSession.withLock { $0 = .dcCharge }
              } catch {
                DokoLogging.shared.postLoggingResponse(.error(".dcChargeStarting: \(String(describing: error))"))
                nextState = .dcChargeStarting
              }
            }
            $vehicleState.withLock { $0 = nextState }

          case .dcChargeInProgress:
            guard case .dcChargeInProgress = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            let nextState = dokoResponsePacket.nextState ?? .dcChargeInProgress
            if nextState != self.vehicleState { $vehicleState.withLock { $0 = nextState } }

          case .dcChargeEnding:
            guard case .dcChargeEnding = vehicleState else { throw StateEngineError.unexpectedStatePacket(vehicleState, dokoResponsePacket.type) }
            guard let chargeDraft = self.chargeInProgress else {  throw StateEngineError.chargeArgumentError }
            var nextState = dokoResponsePacket.nextState ?? .dcChargeEnding
            if nextState == .idle {
              do {
                let _ = try Charge.postChargeEndRecord(chargeDraft: chargeDraft, chargeEndResponse: dokoResponsePacket)
                self.chargeInProgress = nil
                Task { await LiveActivityManager.shared.endCharge(chargeData: dokoResponsePacket) }
                $activeSession.withLock { $0 = nil }
              } catch {
                DokoLogging.shared.postLoggingResponse(.error(".dcChargeEnding: \(String(describing: error))"))
                nextState = .dcChargeEnding
              }
            }
            $vehicleState.withLock { $0 = nextState }

          case .tripEnergy:
            break

          case .acChargeEnergy, .dcChargeEnergy:
            break
            
          case .acChargeUpdate, .dcChargeUpdate:
            guard let chargeDraft = self.chargeInProgress else { throw StateEngineError.chargeDraftError }
            ABRPManager.shared.sendChargeTelemetry( packet: dokoResponsePacket, isDCFC: dokoResponsePacket.type == .dcChargeUpdate )
            do {
              self.chargeInProgress = try Charge.postChargeUpdateRecord(chargeDraft: chargeDraft, chargeUpdateResponse: dokoResponsePacket)
              $chargeUpdateResponses.withLock { $0 = dokoResponsePacket.responses }
              Task { await LiveActivityManager.shared.updateCharge(chargeData: dokoResponsePacket) }
            } catch {
              DokoLogging.shared.postLoggingResponse(.error(".chargeUpdate: \(String(describing: error))"))
            }

          case .acChargeHistory, .dcChargeHistory:
            guard let chargeID = chargeInProgress?.id else { throw StateEngineError.missingChargeID }
            do {
              try Charge.postChargeHistoryRecord(chargeID: chargeID, chargeHistoryPacket: dokoResponsePacket)
            } catch {
              DokoLogging.shared.postLoggingResponse(.error(".chargeHistory: \(String(describing: error))"))
            }
          }
        } catch {
          DokoLogging.shared.postLoggingResponse(.error("dokoResponseProcessing: \(String(describing: error))"))
        }
      }
      DokoLogging.shared.postLoggingResponse(.info("SE.ResponseProcessing ended"))
      self.logger.info("\(timestamp()) StateEngine.obdResponseProcessing() stopped")
    }
  }
}

extension DokoStateEngine {
  public func accessoryNameObservation() {
//    @Shared(.connectedAccessoryName) var observedAccessoryName
//    @Shared(.activeSession) var activeSession
    DokoLogging.shared.postLoggingResponse(.info("SE.accessoryNameObservation"))
    Task { [weak self] in
      guard let self else { return }
      var oldAccessoryName: String? = nil
      for await newAccessoryName in $accessoryName.publisher.values {
        if Task.isCancelled { break }
        if oldAccessoryName == newAccessoryName { continue }
        self.logger.info("\(timestamp()) SE: accessory changed from \(oldAccessoryName ?? "nil") to \(newAccessoryName ?? "nil")")
        if let accessoryName = newAccessoryName {
          await DokoNotificationManager.shared.accessoryConnectedNotification(accessoryName: accessoryName)
          connectedVehicleObservation()
          vehicleStateObservation()
          await startStateEngine()
        } else {
          stopCVObservation()
          stopVehicleStateObservation()
          await stopStateEngine()
          $activeSession.withLock { $0 = nil }
          await DokoNotificationManager.shared.accessoryDisconnectedNotification(accessoryName: oldAccessoryName ?? "unknown")
        }
        oldAccessoryName = newAccessoryName
      }
    }
  }

  private func connectedVehicleObservation() {
    guard vehicleTypeObservationTask == nil else {
      DokoLogging.shared.postLoggingResponse(.error("SE.connectedVehicleObservation: already started"))
      return
    }
    self.logger.info("\(timestamp()) SE.connectedVehicleObservation")
    DokoLogging.shared.postLoggingResponse(.info("SE.connectedVehicleObservation"))
    @Shared(.connectedVehicleInterface) var observedConnectedVehicle
    vehicleTypeObservationTask = Task { [weak self] in
      guard let self else { return }
      var oldConnectedVehicle: Vehicle? = nil
      for await newConnectedVehicle in $observedConnectedVehicle.publisher.values {
        if Task.isCancelled { break }
        self.logger.info("\(timestamp()) SE.connectedVehicleObservation: connected vehicle changed from \(String(describing: oldConnectedVehicle)) to \(newConnectedVehicle.name)")
        DokoLogging.shared.postLoggingResponse(.info("SE.connectedVehicleObservation: connected vehicle changed from \(String(describing: oldConnectedVehicle)) to \(newConnectedVehicle.name)"))
        if oldConnectedVehicle == newConnectedVehicle.vehicle {
          DokoLogging.shared.postLoggingResponse(.info("SE.connectedVehicleObservation: no change in vehicle"))
          continue
        }
        if newConnectedVehicle.vehicle == nil {
          DokoLogging.shared.postLoggingResponse(.error("SE.connectedVehicleObservation: connected vehicle is nil"))
          $vehicleState.withLock { $0 = .reset}
        }
        oldConnectedVehicle = newConnectedVehicle.vehicle
      }
    }
  }

  private func stopCVObservation() {
    self.logger.info("\(timestamp()) SE.stopCVObservation")
    DokoLogging.shared.postLoggingResponse(.info("SE.stopCVObservation"))
    vehicleTypeObservationTask?.cancel()
    vehicleTypeObservationTask = nil
  }

  private func vehicleStateObservation() {
    guard vehicleStateObservationTask == nil else {
      DokoLogging.shared.postLoggingResponse(.error("SE.vehicleStateObservation: already started"))
      return
    }
    @Shared(.connectedVehicleInterface) var connectedVehicleInterface
    DokoLogging.shared.postLoggingResponse(.info("SE.vehicleStateObservation"))
    vehicleStateObservationTask = Task { [weak self] in
      guard let self else { return }
      defer {
        dokoSchedulerTask?.cancel()
        dokoSchedulerTask = nil
      }
      for await newState in $vehicleState.publisher.values {
        DokoLogging.shared.postLoggingResponse(.info("SE.vehicleStateObservation(\(newState.description)))"))
        dokoSchedulerTask?.cancel()
        dokoSchedulerTask = nil
        if accessoryName == nil {
          DokoLogging.shared.postLoggingResponse(.error("SE.vehicleStateObservation: expected accessory"))
          continue
        }
        guard let schedules = await connectedVehicleInterface.createStateScheduler(for: newState) else {
          DokoLogging.shared.postLoggingResponse(.error("SE.vehicleStateObservation: No scheduler for state '\(newState.description)'"))
          continue
        }
        self.dokoSchedulerTask = createScheduler(schedules: schedules)
        DokoLogging.shared.postLoggingResponse(.info("SE.vehicleStateObservation(schedulaer created))"))
      }
    }
  }

  private func stopVehicleStateObservation() {
    self.logger.info("\(timestamp()) SE.stopVehicleStateObservation")
    DokoLogging.shared.postLoggingResponse(.info("SE.stopVehicleStateObservation"))
    vehicleStateObservationTask?.cancel()
    vehicleStateObservationTask = nil
  }
}
