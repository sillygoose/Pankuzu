import Foundation

import DokoTypes

extension CodingUserInfoKey {
  public static let useLegacyKeys = CodingUserInfoKey(rawValue: "useLegacyKeys")!
}

public struct DokoDataPoint: Identifiable, Hashable, Equatable, Codable, Sendable {
  public let timestamp: Date
  public let datapoint: Double
  public var id: Date { timestamp }

  public init(timestamp: Date, double: Double) {
    self.timestamp = timestamp
    self.datapoint = double
  }

  private enum CodingKeys: String, CodingKey {
    case timestamp = "t"
    case datapoint = "d"
  }

  private enum LegacyCodingKeys: String, CodingKey {
    case timestamp, datapoint
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.timestamp) {
      timestamp = try container.decode(Date.self, forKey: .timestamp)
      datapoint = try container.decode(Double.self, forKey: .datapoint)
    } else {
      let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
      timestamp = try legacy.decode(Date.self, forKey: .timestamp)
      datapoint = try legacy.decode(Double.self, forKey: .datapoint)
    }
  }

  public func encode(to encoder: Encoder) throws {
    if (encoder.userInfo[.useLegacyKeys] as? Bool) == true {
      var container = encoder.container(keyedBy: LegacyCodingKeys.self)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(datapoint, forKey: .datapoint)
    } else {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(datapoint, forKey: .datapoint)
    }
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

  private enum CodingKeys: String, CodingKey {
    case timestamp = "t"
    case temperature = "tp"
    case windSpeed = "ws"
    case windGust = "wg"
    case windDirection = "wd"
    case windCompassDirection = "wc"
    case conditionSymbol = "cs"
  }

  private enum LegacyCodingKeys: String, CodingKey {
    case timestamp, temperature, windSpeed, windGust, windDirection, windCompassDirection, conditionSymbol
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.timestamp) {
      timestamp = try container.decode(Date.self, forKey: .timestamp)
      temperature = try container.decode(Double.self, forKey: .temperature)
      windSpeed = try container.decode(Double.self, forKey: .windSpeed)
      windGust = try container.decodeIfPresent(Double.self, forKey: .windGust)
      windDirection = try container.decode(Double.self, forKey: .windDirection)
      windCompassDirection = try container.decode(String.self, forKey: .windCompassDirection)
      conditionSymbol = try container.decode(String.self, forKey: .conditionSymbol)
    } else {
      let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
      timestamp = try legacy.decode(Date.self, forKey: .timestamp)
      temperature = try legacy.decode(Double.self, forKey: .temperature)
      windSpeed = try legacy.decode(Double.self, forKey: .windSpeed)
      windGust = try legacy.decodeIfPresent(Double.self, forKey: .windGust)
      windDirection = try legacy.decode(Double.self, forKey: .windDirection)
      windCompassDirection = try legacy.decode(String.self, forKey: .windCompassDirection)
      conditionSymbol = try legacy.decode(String.self, forKey: .conditionSymbol)
    }
  }

  public func encode(to encoder: Encoder) throws {
    if (encoder.userInfo[.useLegacyKeys] as? Bool) == true {
      var container = encoder.container(keyedBy: LegacyCodingKeys.self)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(temperature, forKey: .temperature)
      try container.encode(windSpeed, forKey: .windSpeed)
      try container.encodeIfPresent(windGust, forKey: .windGust)
      try container.encode(windDirection, forKey: .windDirection)
      try container.encode(windCompassDirection, forKey: .windCompassDirection)
      try container.encode(conditionSymbol, forKey: .conditionSymbol)
    } else {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(temperature, forKey: .temperature)
      try container.encode(windSpeed, forKey: .windSpeed)
      try container.encodeIfPresent(windGust, forKey: .windGust)
      try container.encode(windDirection, forKey: .windDirection)
      try container.encode(windCompassDirection, forKey: .windCompassDirection)
      try container.encode(conditionSymbol, forKey: .conditionSymbol)
    }
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
    self.horizontalAccuracy = nil
    self.verticalAccuracy = nil
  }

  public init(position: DokoPosition) {
    self.timestamp = position.timestamp
    self.latitude = position.latitude
    self.longitude = position.longitude
    self.elevation = position.elevation
    self.course = position.course
    self.speed = position.speed
    self.horizontalAccuracy = nil
    self.verticalAccuracy = nil
  }

  private enum CodingKeys: String, CodingKey {
    case timestamp = "t"
    case latitude = "la"
    case longitude = "lo"
    case elevation = "e"
    case course = "c"
    case speed = "s"
    case horizontalAccuracy = "ha"
    case verticalAccuracy = "va"
  }

  private enum LegacyCodingKeys: String, CodingKey {
    case timestamp, latitude, longitude, elevation, course, speed, horizontalAccuracy, verticalAccuracy
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.timestamp) {
      timestamp = try container.decode(Date.self, forKey: .timestamp)
      latitude = try container.decode(Double.self, forKey: .latitude)
      longitude = try container.decode(Double.self, forKey: .longitude)
      elevation = try container.decodeIfPresent(Double.self, forKey: .elevation)
      course = try container.decodeIfPresent(Double.self, forKey: .course)
      speed = try container.decodeIfPresent(Double.self, forKey: .speed)
      horizontalAccuracy = try container.decodeIfPresent(Double.self, forKey: .horizontalAccuracy)
      verticalAccuracy = try container.decodeIfPresent(Double.self, forKey: .verticalAccuracy)
    } else {
      let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
      timestamp = try legacy.decode(Date.self, forKey: .timestamp)
      latitude = try legacy.decode(Double.self, forKey: .latitude)
      longitude = try legacy.decode(Double.self, forKey: .longitude)
      elevation = try legacy.decodeIfPresent(Double.self, forKey: .elevation)
      course = try legacy.decodeIfPresent(Double.self, forKey: .course)
      speed = try legacy.decodeIfPresent(Double.self, forKey: .speed)
      horizontalAccuracy = try legacy.decodeIfPresent(Double.self, forKey: .horizontalAccuracy)
      verticalAccuracy = try legacy.decodeIfPresent(Double.self, forKey: .verticalAccuracy)
    }
  }

  public func encode(to encoder: Encoder) throws {
    if (encoder.userInfo[.useLegacyKeys] as? Bool) == true {
      var container = encoder.container(keyedBy: LegacyCodingKeys.self)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(latitude, forKey: .latitude)
      try container.encode(longitude, forKey: .longitude)
      try container.encodeIfPresent(elevation, forKey: .elevation)
      try container.encodeIfPresent(course, forKey: .course)
      try container.encodeIfPresent(speed, forKey: .speed)
      try container.encodeIfPresent(horizontalAccuracy, forKey: .horizontalAccuracy)
      try container.encodeIfPresent(verticalAccuracy, forKey: .verticalAccuracy)
    } else {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(latitude, forKey: .latitude)
      try container.encode(longitude, forKey: .longitude)
      try container.encodeIfPresent(elevation, forKey: .elevation)
      try container.encodeIfPresent(course, forKey: .course)
      try container.encodeIfPresent(speed, forKey: .speed)
      try container.encodeIfPresent(horizontalAccuracy, forKey: .horizontalAccuracy)
      try container.encodeIfPresent(verticalAccuracy, forKey: .verticalAccuracy)
    }
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
    self.verticalAccuracy = nil
  }

  public init(position: DokoPosition) {
    self.timestamp = position.timestamp
    self.elevation = position.elevation
    self.verticalAccuracy = nil
  }

  private enum CodingKeys: String, CodingKey {
    case timestamp = "t"
    case elevation = "e"
    case verticalAccuracy = "va"
  }

  private enum LegacyCodingKeys: String, CodingKey {
    case timestamp, elevation, verticalAccuracy
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.timestamp) {
      timestamp = try container.decode(Date.self, forKey: .timestamp)
      elevation = try container.decode(Double.self, forKey: .elevation)
      verticalAccuracy = try container.decodeIfPresent(Double.self, forKey: .verticalAccuracy)
    } else {
      let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
      timestamp = try legacy.decode(Date.self, forKey: .timestamp)
      elevation = try legacy.decode(Double.self, forKey: .elevation)
      verticalAccuracy = try legacy.decodeIfPresent(Double.self, forKey: .verticalAccuracy)
    }
  }

  public func encode(to encoder: Encoder) throws {
    if (encoder.userInfo[.useLegacyKeys] as? Bool) == true {
      var container = encoder.container(keyedBy: LegacyCodingKeys.self)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(elevation, forKey: .elevation)
      try container.encodeIfPresent(verticalAccuracy, forKey: .verticalAccuracy)
    } else {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(timestamp, forKey: .timestamp)
      try container.encode(elevation, forKey: .elevation)
      try container.encodeIfPresent(verticalAccuracy, forKey: .verticalAccuracy)
    }
  }
}
