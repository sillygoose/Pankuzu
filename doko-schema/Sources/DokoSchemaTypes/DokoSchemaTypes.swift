import Foundation

import DokoTypes

public struct DokoDataPoint: Identifiable, Hashable, Equatable, Codable, Sendable {
  public let timestamp: Date
  public let datapoint: Double
  public var id: Date { timestamp }
  
  public init(timestamp: Date, double: Double) {
    self.timestamp = timestamp
    self.datapoint = double
  }
}

public struct DokoWeather: Identifiable, Hashable, Equatable, Codable, Sendable {
  public let timestamp: Date
  public let temperature: Double
  public let windSpeed: Double
  public let windGust: Double?
  public let windDirection: Double
  public let windCompassDirection: String
  public let conditionSymbol: String
  public var id: Date { timestamp }

  public init(
    timestamp: Date,
    temperature: Double,
    windSpeed: Double,
    windGust: Double? = nil,
    windDirection: Double,
    windCompassDirection: String,
    conditionSymbol: String
  ) {
    self.timestamp = timestamp
    self.temperature = temperature
    self.windSpeed = windSpeed
    self.windGust = windGust
    self.windDirection = windDirection
    self.windCompassDirection = windCompassDirection
    self.conditionSymbol = conditionSymbol
  }

  public init(currentWeather: DokoCurrentWeather) {
    self.timestamp = currentWeather.timestamp
    self.temperature = currentWeather.temperature
    self.windSpeed = currentWeather.windSpeed
    if let windGust = currentWeather.windGust {
      self.windGust = windGust
    } else {
      self.windGust = nil
    }
    self.windDirection = currentWeather.windDirection
    self.windCompassDirection = currentWeather.windCompassDirection
    self.conditionSymbol = currentWeather.conditionSymbol
  }
}

public struct VehiclePosition: Identifiable, Equatable, Hashable, Codable, Sendable {
  public var timestamp: Date
  public let latitude: Double
  public let longitude: Double
  public let elevation: Double?
  public let course: Double?
  public let speed: Double?
  public let horizontalAccuracy: Double?
  public let verticalAccuracy: Double?
  public var id: Date { timestamp }

  public init(
    timestamp: Date,
    latitude: Double,
    longitude: Double,
    elevation: Double? = nil,
    course: Double? = nil,
    speed: Double? = nil,
    horizontalAccuracy: Double? = nil,
    verticalAccuracy: Double? = nil
  ) {
    self.timestamp = timestamp
    self.latitude = latitude
    self.longitude = longitude
    self.elevation = elevation
    self.course = course
    self.speed = speed
    self.horizontalAccuracy = horizontalAccuracy
    self.verticalAccuracy = verticalAccuracy
  }

  public init(position: DokoPosition) {
    self.timestamp = position.timestamp
    self.latitude = position.latitude
    self.longitude = position.longitude
    self.elevation = position.elevation
    self.course = position.course
    self.speed = position.speed
    self.horizontalAccuracy = position.horizontalAccuracy
    self.verticalAccuracy = position.verticalAccuracy
  }
}

public struct VehicleElevation: Identifiable, Equatable, Hashable, Codable, Sendable {
  public var timestamp: Date
  public let elevation: Double
  public let verticalAccuracy: Double?
  public var id: Date { timestamp }

  public init(
    timestamp: Date,
    elevation: Double,
    verticalAccuracy: Double? = nil
  ) {
    self.timestamp = timestamp
    self.elevation = elevation
    self.verticalAccuracy = verticalAccuracy
  }

  public init(position: DokoPosition) {
    self.timestamp = position.timestamp
    self.elevation = position.elevation
    self.verticalAccuracy = position.verticalAccuracy
  }
}
