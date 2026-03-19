import Foundation
import SwiftUI
import MapKit

import Sharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var metric: Self {
    Self[.appStorage("ApplicationSettings-metric"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var kWhPer100km: Self {
    Self[.appStorage("ApplicationSettings-kWhPer100km"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var iCloudSync: Self {
    Self[.appStorage("ApplicationSettings-iCloudSync"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Double>.Default {
  public static var poiThreshold: Self {
    Self[.appStorage("ApplicationSettings-poiThreshold"), default: 75]
  }
}

extension SharedKey where Self == AppStorageKey<Double>.Default {
  public static var duplicateLocationThreshold: Self {
    Self[.appStorage("ApplicationSettings-duplicateLocationThreshold"), default: 35]
  }
}

extension SharedKey where Self == AppStorageKey<DisplayMapStyle>.Default {
  public static var tripMapStyle: Self {
    Self[.appStorage("ApplicationSettings-tripMapStyle"), default: .standard]
  }
}

extension SharedKey where Self == AppStorageKey<DisplayMapStyle>.Default {
  public static var chargeMapStyle: Self {
    Self[.appStorage("ApplicationSettings-chargeMapStyle"), default: .standard]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var tripMapPolyline: Self {
    Self[.appStorage("ApplicationSettings-tripMapPolyline"), default: true]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var showElevationOnPath: Self {
    Self[.appStorage("ApplicationSettings-showElevationOnPath"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Double>.Default {
  public static var identicalTripPositionDistance: Self {
    Self[.appStorage("ApplicationSettings-identicalTripPositionDistance"), default: 10]
  }
}

extension SharedKey where Self == AppStorageKey<Double>.Default {
  public static var tripPositionCourseDeviation: Self {
    Self[.appStorage("ApplicationSettings-positionCourseDeviation"), default: 2.0]
  }
}

extension SharedKey where Self == AppStorageKey<Double>.Default {
  public static var maximumTripPositionDistance: Self {
    Self[.appStorage("ApplicationSettings-maximumTripPositionDistance"), default: 300]
  }
}

extension SharedKey where Self == AppStorageKey<Double>.Default {
  public static var maximumTripElevationDistance: Self {
    Self[.appStorage("ApplicationSettings-maximumTripElevationDistance"), default: 100]
  }
}

extension SharedKey where Self == AppStorageKey<Double>.Default {
  public static var minimumTripElevationChange: Self {
    Self[.appStorage("ApplicationSettings-minimumTripElevationChange"), default: 2]
  }
}

extension SharedKey where Self == AppStorageKey<Int>.Default {
  public static var deletedRecordRetentionDays: Self {
    Self[.appStorage("ApplicationSettings-deletedRecordRetentionDays"), default: 30]
  }
}

public enum DisplayMapStyle: String, CaseIterable, Equatable, Identifiable, Sendable {
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
