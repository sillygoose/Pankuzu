import Foundation
import SwiftUI
import MapKit

public struct AppSettings: Codable, Equatable, Sendable {
  public var backgroundMode: Bool = false
  public var accessorySerialNumber: String? = nil
  
  public var metric: Bool = false
  public var kWhPer100km: Bool = false
  
  public var iCloudSync: Bool = false
  
  public var poiThreshold: Double = 75
  public var duplicateLocationThreshold: Double = 35
  
  public var tripMapStyle: DisplayMapStyle = .standard
  public var chargeMapStyle: DisplayMapStyle = .standard
  
  public var tripMapPolyline: Bool = true
  public var showElevationOnPath: Bool = false
  public var identicalTripPositionDistance: Double = 10
  public var tripPositionCourseDeviation: Double = 2.0
  public var maximumTripPositionDistance: Double = 300
  public var maximumTripElevationDistance: Double = 100
  public var minimumTripElevationChange: Double = 2
  public var deletedRecordRetentionDays: Int = 30
  
  public var abrpEnabled: Bool = false
  public var abrpUserToken: String = ""
  public var abrpVehicleTokens: [String: String] = [:]

  public init() {}

  public enum CodingKeys: String, CodingKey {
    case backgroundMode, accessorySerialNumber, metric, kWhPer100km, iCloudSync
    case poiThreshold, duplicateLocationThreshold
    case tripMapStyle, chargeMapStyle, tripMapPolyline, showElevationOnPath
    case identicalTripPositionDistance, tripPositionCourseDeviation
    case maximumTripPositionDistance, maximumTripElevationDistance, minimumTripElevationChange
    case deletedRecordRetentionDays
    case abrpEnabled, abrpUserToken, abrpVehicleTokens
  }

  public func encode(to encoder: any Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(backgroundMode, forKey: .backgroundMode)
    try c.encodeIfPresent(accessorySerialNumber, forKey: .accessorySerialNumber)
    try c.encode(metric, forKey: .metric)
    try c.encode(kWhPer100km, forKey: .kWhPer100km)
    try c.encode(iCloudSync, forKey: .iCloudSync)
    try c.encode(poiThreshold, forKey: .poiThreshold)
    try c.encode(duplicateLocationThreshold, forKey: .duplicateLocationThreshold)
    try c.encode(tripMapStyle, forKey: .tripMapStyle)
    try c.encode(chargeMapStyle, forKey: .chargeMapStyle)
    try c.encode(tripMapPolyline, forKey: .tripMapPolyline)
    try c.encode(showElevationOnPath, forKey: .showElevationOnPath)
    try c.encode(identicalTripPositionDistance, forKey: .identicalTripPositionDistance)
    try c.encode(tripPositionCourseDeviation, forKey: .tripPositionCourseDeviation)
    try c.encode(maximumTripPositionDistance, forKey: .maximumTripPositionDistance)
    try c.encode(maximumTripElevationDistance, forKey: .maximumTripElevationDistance)
    try c.encode(minimumTripElevationChange, forKey: .minimumTripElevationChange)
    try c.encode(deletedRecordRetentionDays, forKey: .deletedRecordRetentionDays)
    try c.encode(abrpEnabled, forKey: .abrpEnabled)
    try c.encode(abrpUserToken, forKey: .abrpUserToken)
    try c.encode(abrpVehicleTokens, forKey: .abrpVehicleTokens)
  }

  // Future-proof decode: new fields added later fall back to defaults;
  // removed fields in old JSON are silently ignored by the decoder.
  public init(from decoder: any Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    backgroundMode = try c.decodeIfPresent(Bool.self, forKey: .backgroundMode) ?? false
    accessorySerialNumber = try c.decodeIfPresent(String.self, forKey: .accessorySerialNumber)
    metric = try c.decodeIfPresent(Bool.self, forKey: .metric) ?? false
    kWhPer100km = try c.decodeIfPresent(Bool.self, forKey: .kWhPer100km) ?? false
    iCloudSync = try c.decodeIfPresent(Bool.self, forKey: .iCloudSync) ?? false
    poiThreshold = try c.decodeIfPresent(Double.self, forKey: .poiThreshold) ?? 75
    duplicateLocationThreshold = try c.decodeIfPresent(Double.self, forKey: .duplicateLocationThreshold) ?? 35
    tripMapStyle = try c.decodeIfPresent(DisplayMapStyle.self, forKey: .tripMapStyle) ?? .standard
    chargeMapStyle = try c.decodeIfPresent(DisplayMapStyle.self, forKey: .chargeMapStyle) ?? .standard
    tripMapPolyline = try c.decodeIfPresent(Bool.self, forKey: .tripMapPolyline) ?? true
    showElevationOnPath = try c.decodeIfPresent(Bool.self, forKey: .showElevationOnPath) ?? false
    identicalTripPositionDistance = try c.decodeIfPresent(Double.self, forKey: .identicalTripPositionDistance) ?? 10
    tripPositionCourseDeviation = try c.decodeIfPresent(Double.self, forKey: .tripPositionCourseDeviation) ?? 2.0
    maximumTripPositionDistance = try c.decodeIfPresent(Double.self, forKey: .maximumTripPositionDistance) ?? 300
    maximumTripElevationDistance = try c.decodeIfPresent(Double.self, forKey: .maximumTripElevationDistance) ?? 100
    minimumTripElevationChange = try c.decodeIfPresent(Double.self, forKey: .minimumTripElevationChange) ?? 2
    deletedRecordRetentionDays = try c.decodeIfPresent(Int.self, forKey: .deletedRecordRetentionDays) ?? 30
    abrpEnabled = try c.decodeIfPresent(Bool.self, forKey: .abrpEnabled) ?? false
    abrpUserToken = try c.decodeIfPresent(String.self, forKey: .abrpUserToken) ?? ""
    abrpVehicleTokens = try c.decodeIfPresent([String: String].self, forKey: .abrpVehicleTokens) ?? [:]
  }
}

extension AppSettings: RawRepresentable {
  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let string = String(data: data, encoding: .utf8) else { return "{}" }
    return string
  }

  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else { return nil }
    self = decoded
  }
}

extension SharedKey where Self == AppStorageKey<AppSettings>.Default {
  public static var appSettings: Self {
    Self[.appStorage("AppSettings"), default: AppSettings()]
  }
}

extension AppSettings {
  /// One-time migration from individual UserDefaults keys to the unified AppSettings key.
  /// Call once during app bootstrap before any @Shared(.appSettings) accesses.
  public static func migrateIfNeeded() {
    let defaults = UserDefaults.standard
    guard defaults.object(forKey: "AppSettings") == nil else { return }

    var s = AppSettings()
    if let v = defaults.object(forKey: "ObdLinkManager-BackgroundMode") as? Bool { s.backgroundMode = v }
    if let v = defaults.string(forKey: "ObdLinkManager-AccessorySerialNumber") { s.accessorySerialNumber = v }
    if let v = defaults.object(forKey: "ApplicationSettings-metric") as? Bool { s.metric = v }
    if let v = defaults.object(forKey: "ApplicationSettings-kWhPer100km") as? Bool { s.kWhPer100km = v }
    if let v = defaults.object(forKey: "ApplicationSettings-iCloudSync") as? Bool { s.iCloudSync = v }
    if let v = defaults.object(forKey: "ApplicationSettings-poiThreshold") as? Double { s.poiThreshold = v }
    if let v = defaults.object(forKey: "ApplicationSettings-duplicateLocationThreshold") as? Double { s.duplicateLocationThreshold = v }
    if let v = defaults.string(forKey: "ApplicationSettings-tripMapStyle").flatMap(DisplayMapStyle.init) { s.tripMapStyle = v }
    if let v = defaults.string(forKey: "ApplicationSettings-chargeMapStyle").flatMap(DisplayMapStyle.init) { s.chargeMapStyle = v }
    if let v = defaults.object(forKey: "ApplicationSettings-tripMapPolyline") as? Bool { s.tripMapPolyline = v }
    if let v = defaults.object(forKey: "ApplicationSettings-showElevationOnPath") as? Bool { s.showElevationOnPath = v }
    if let v = defaults.object(forKey: "ApplicationSettings-identicalTripPositionDistance") as? Double { s.identicalTripPositionDistance = v }
    if let v = defaults.object(forKey: "ApplicationSettings-positionCourseDeviation") as? Double { s.tripPositionCourseDeviation = v }
    if let v = defaults.object(forKey: "ApplicationSettings-maximumTripPositionDistance") as? Double { s.maximumTripPositionDistance = v }
    if let v = defaults.object(forKey: "ApplicationSettings-maximumTripElevationDistance") as? Double { s.maximumTripElevationDistance = v }
    if let v = defaults.object(forKey: "ApplicationSettings-minimumTripElevationChange") as? Double { s.minimumTripElevationChange = v }
    if let v = defaults.object(forKey: "ApplicationSettings-deletedRecordRetentionDays") as? Int { s.deletedRecordRetentionDays = v }
    if let v = defaults.object(forKey: "ABRP-enabled") as? Bool { s.abrpEnabled = v }
    if let v = defaults.string(forKey: "ABRP-userToken") { s.abrpUserToken = v }

    defaults.set(s.rawValue, forKey: "AppSettings")
  }
}

public enum DisplayMapStyle: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
  case standard
  case hybrid
  case imagery

  public var id: Self { self }

  public var name: String { rawValue.capitalized }
  public var mapStyle: MapStyle {
    switch self {
    case .standard:
      return .standard
    case .hybrid:
      return .hybrid
    case .imagery:
      return .imagery
    }
  }
}
