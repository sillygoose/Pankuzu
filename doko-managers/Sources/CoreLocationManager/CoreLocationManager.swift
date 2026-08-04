import CoreLocation
import OSLog

import DokoLogging

// MARK: - CoreLocationManager

@Observable
@MainActor
public final class CoreLocationManager: NSObject, @MainActor CLLocationManagerDelegate {
  private let logger = Logger(subsystem: "Doko", category: "CoreLocationManager")

  public static let shared = CoreLocationManager()

  private let locationManager: CLLocationManager
  private var background: CLBackgroundActivitySession?
  private var liveUpdatesTask: Task<Void, Never>? = nil

  public var backgroundActivity: Bool = UserDefaults.standard.bool(forKey: "BGActivitySessionStarted") {
    didSet {
      backgroundActivity ? self.background = CLBackgroundActivitySession() : self.background?.invalidate()
      UserDefaults.standard.set(backgroundActivity, forKey: "BGActivitySessionStarted")
    }
  }

  public func restoreBackgroundSession() {
    guard backgroundActivity else { return }
    background = CLBackgroundActivitySession()
  }

  public var authorizationStatus: CLAuthorizationStatus = .notDetermined

  private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
  private var locationUpdatesEnabled: Bool = false
  
  private var _currentPosition: CLLocation?
  private var _currentElevation: CLLocation?

  var lastOutputPosition: CLLocation?
  var lastOutputElevation: CLLocation?

  public var packetUpdatesEnabled: Bool = false

  public var currentPosition: CLLocation? {
    if !locationUpdatesEnabled {
      DokoLogging.shared.postLoggingResponse(.coreLocation("currentPosition requested when disabled"))
    }
    guard let position = _currentPosition else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("currentPosition is nil"))
      return nil
    }
    return position
  }

  public var currentElevation: CLLocation? {
    if !locationUpdatesEnabled {
      DokoLogging.shared.postLoggingResponse(.coreLocation("currentElevation requested when disabled"))
    }
    guard let elevation = _currentElevation else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("currentElevation is nil"))
      return nil
    }
    return elevation
  }

  private func startAccessoryNameObservation() {
     @Shared(.connectedAccessoryName) var observedAccessoryName
     Task { [weak self] in
       guard let self else { return }
       var oldAccessoryName: String? = nil
       for await newAccessoryName in $observedAccessoryName.publisher.values {
         if Task.isCancelled { break }
         guard oldAccessoryName != newAccessoryName else { continue }
         if newAccessoryName == nil {
           if packetUpdatesEnabled { stopPacketUpdates() }
           if locationUpdatesEnabled { stopLocationUpdates() }
         }
         oldAccessoryName = newAccessoryName
       }
     }
   }

  override public init() {
    self.locationManager = CLLocationManager()
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    self.locationManager.allowsBackgroundLocationUpdates = false
    self.locationManager.pausesLocationUpdatesAutomatically = false
    self.locationManager.distanceFilter = kCLDistanceFilterNone
    self.locationManager.showsBackgroundLocationIndicator = true
    self.locationManager.activityType = .automotiveNavigation
    super.init()
    self.locationManager.delegate = self
    authorizationStatus = self.locationManager.authorizationStatus
    startAccessoryNameObservation()
  }

  public func requestUserAuthorization() async -> CLAuthorizationStatus {
    if authorizationStatus != .notDetermined {
      return authorizationStatus
    }
    return await withCheckedContinuation { continuation in
      self.authorizationContinuation = continuation
      locationManager.requestWhenInUseAuthorization()
    }
  }

  public func startPacketUpdates() {
    logger.debug("\(timestamp()) CLM.startPacketUpdates")
    DokoLogging.shared.postLoggingResponse(.coreLocation(".startPacketUpdates"))
    packetUpdatesEnabled = true
  }

  public func stopPacketUpdates() {
    logger.debug("\(timestamp()) CLM.stopPacketUpdates")
    DokoLogging.shared.postLoggingResponse(.coreLocation(".stopPacketUpdates"))
    packetUpdatesEnabled = false
  }

  public func startLocationUpdates() {
    logger.debug("\(timestamp()) startLocationUpdates: locationUpdatesEnabled=\(self.locationUpdatesEnabled), bgActivity=\(self.backgroundActivity), auth=\(self.authorizationStatus.rawValue)")
    authorizationStatus = locationManager.authorizationStatus
    if authorizationStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
    }

    if background == nil { background = CLBackgroundActivitySession() }
    locationManager.allowsBackgroundLocationUpdates = true

    _currentPosition = nil
    _currentElevation = nil
    lastOutputPosition = nil
    lastOutputElevation = nil

    locationUpdatesEnabled = true

    // Start classic Core Location updates for background reliability
    locationManager.startUpdatingLocation()
    
    // async live updates (more efficient in foreground)
    liveUpdatesTask?.cancel()
    liveUpdatesTask = Task { [weak self] in
      guard let self else { return }
      DokoLogging.shared.postLoggingResponse(.coreLocation(".liveUpdatesTask started"))
      do {
        for try await update in CLLocationUpdate.liveUpdates(.automotiveNavigation) {
          if Task.isCancelled || !self.locationUpdatesEnabled { break }
          if let location = update.location {
            DokoLogging.shared.postLoggingResponse(
              .coreLocation("liveUpdate(\(String(format: "e:%.1f, s:%.1f, c:%.0f", location.altitude, location.speed, location.course)))"),
              debugPacket: true
            )
            if let accurateHorizontalLocation = await filterHorizontalAccuracy(location) {
              await MainActor.run { self._currentPosition = accurateHorizontalLocation }
              if packetUpdatesEnabled { await filterPosition(accurateHorizontalLocation) }
            }
            if let accurateVerticalLocation = await filterVerticalAccuracy(location) {
              await MainActor.run { self._currentElevation = accurateVerticalLocation }
              if packetUpdatesEnabled { await filterElevation(accurateVerticalLocation) }
            }
          }
        }
        DokoLogging.shared.postLoggingResponse(.coreLocation(".liveUpdatesTask ended"))
      } catch {
        self.logger.error("\(timestamp()) liveUpdate stream error: \(String(describing: error))")
        DokoLogging.shared.postLoggingResponse(.error("liveUpdate stream error: \(String(describing: error))"))
      }
    }
  }

  public func stopLocationUpdates() {
    locationUpdatesEnabled = false
    liveUpdatesTask?.cancel()
    liveUpdatesTask = nil
    locationManager.stopUpdatingLocation()
    locationManager.allowsBackgroundLocationUpdates = false
    _currentPosition = nil
    _currentElevation = nil
    background?.invalidate()
    background = nil
    logger.debug("\(timestamp()) CLM.stopLocationUpdates completed")
    DokoLogging.shared.postLoggingResponse(.coreLocation(".stopLocationUpdates"))
  }

  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard locationUpdatesEnabled, let location = locations.last else { return }
    DokoLogging.shared.postLoggingResponse(
      .coreLocation("didUpdateLocations(\(String(format: "e:%.1f, s:%.1f, c:%.0f", location.altitude, location.speed, location.course)))"),
      debugPacket: true
    )
    Task {
      if let accurateHorizontalLocation = await filterHorizontalAccuracy(location) {
        await MainActor.run { self._currentPosition = accurateHorizontalLocation }
        if packetUpdatesEnabled { await filterPosition(accurateHorizontalLocation) }
      }
      if let accurateVerticalLocation = await filterVerticalAccuracy(location) {
        await MainActor.run { self._currentElevation = accurateVerticalLocation }
        if packetUpdatesEnabled { await filterElevation(accurateVerticalLocation) }
      }
    }
  }

  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    logger.error("\(timestamp()) CLM.locationManager( error:\(String(describing: error)))")
    DokoLogging.shared.postLoggingResponse(.coreLocation(".locationManager(\(String(describing: error)))"))
  }

  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus

    if let continuation = authorizationContinuation {
      authorizationContinuation = nil
      continuation.resume(returning: manager.authorizationStatus)
      return
    }

    switch manager.authorizationStatus {
    case .authorizedWhenInUse:
      locationManager.requestAlwaysAuthorization()
    case .authorizedAlways:
      logger.debug("\(timestamp()) Background location authorized")
    case .denied:
      logger.warning("\(timestamp()) User denied location")
    case .notDetermined:
      logger.debug("\(timestamp()) Waiting for user to decide")
    default:
      break
    }
  }
}

extension CLAuthorizationStatus {
  public var status: String {
    switch self {
    case .notDetermined:
      return "CLAuthorizationStatus.notDetermined"
    case .restricted:
      return "CLAuthorizationStatus.restricted"
    case .denied:
      return "CLAuthorizationStatus.denied"
    case .authorizedAlways:
      return "CLAuthorizationStatus.authorizedAlways"
    case .authorizedWhenInUse:
      return "CLAuthorizationStatus.authorizedWhenInUse"
    @unknown default:
      return "CLAuthorizationStatus.unknown"
    }
  }
}
