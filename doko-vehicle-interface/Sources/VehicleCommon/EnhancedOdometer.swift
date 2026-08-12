import Foundation
import CoreLocation

import DokoTypes
import DokoLogging

public struct EnhancedOdometer: Sendable {
  public var odometer: Double { (rawOdometer * 10).rounded() / 10 }
  public var distance: Double { (rawDistance * 10).rounded() / 10 }

  private(set) var initialOdometer: Double = 0
  private var rawOdometer: Double = 0
  private var rawDistance: Double = 0

  // GPS-refined trip distance: the vehicle odometer only advances in coarse, fixed increments
  // (0.1 km for Ford, 1 km for VW), so it can't say how far the vehicle had already traveled
  // before the first tick, or how far it's traveled since the most recent one. GPS covers both
  // of those gaps; the span between the first and most recent confirmed tick is taken straight
  // from the odometer, since that's the one thing it reports with certainty.
  private var startPosition: DokoPosition?
  private var firstChangeOdometer: Double?
  private var firstChangePosition: DokoPosition?
  private var lastChangePosition: DokoPosition?
  private var lastChangeOdometer: Double?

  public init() {}

//  @discardableResult
//  public mutating func setOdometer(with newOdometer: Double) -> Double {
//    initialOdometer = newOdometer
//    rawOdometer = newOdometer
//    rawDistance = 0
//    return distance
//  }

  @discardableResult
  public mutating func resetOdometer(with newOdometer: Double, and newPosition: DokoPosition) -> Double {
    initialOdometer = newOdometer
    rawOdometer = newOdometer
    rawDistance = 0
    startPosition = newPosition
    firstChangeOdometer = nil
    firstChangePosition = nil
    lastChangePosition = newPosition
    lastChangeOdometer = newOdometer
    return distance
  }

//  @discardableResult
//  public mutating func updateOdometer(with newOdometer: Double) -> Double {
//    rawOdometer = newOdometer
//    rawDistance = newOdometer - initialOdometer
//    return distance
//  }

  @discardableResult
  public mutating func updateOdometer(with newOdometer: Double, and newPosition: DokoPosition) -> Double {
    guard let startPosition else { return distance }

    if newOdometer != rawOdometer {
      if firstChangeOdometer == nil {
        DokoLogging.shared.postLoggingResponse(.info("distance(\(String(format: "%.3f", rawDistance)))"), debugPacket: true)
        firstChangeOdometer = newOdometer
        firstChangePosition = newPosition
      }
      lastChangeOdometer = newOdometer
      lastChangePosition = newPosition
      rawOdometer = newOdometer
    }

    if let firstChangePosition, let firstChangeOdometer, let lastChangePosition, let lastChangeOdometer {
      let confirmedDistance = Self.gpsDistance(startPosition, firstChangePosition) + (lastChangeOdometer - firstChangeOdometer)
      rawDistance = confirmedDistance + Self.gpsDistance(lastChangePosition, newPosition)
    } else {
      // No confirmed tick yet: GPS distance from trip start is the only measurement we have.
      rawDistance = Self.gpsDistance(startPosition, newPosition)
    }
    DokoLogging.shared.postLoggingResponse(.info("distance(\(String(format: "%.3f", rawDistance)))"), debugPacket: true)
    return distance
  }

  private static func gpsDistance(_ a: DokoPosition, _ b: DokoPosition) -> Double {
    let from = CLLocation(latitude: a.latitude, longitude: a.longitude)
    let to = CLLocation(latitude: b.latitude, longitude: b.longitude)
    return from.distance(from: to) / 1_000
  }
}
