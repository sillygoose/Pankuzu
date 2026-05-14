import CoreLocation
import WeatherKit
import OSLog

import Dependencies

import DokoTypes
import DokoLogging

@DokoEngineActor
public final class DokoWeatherManager: Sendable {
  private let logger = Logger(subsystem: "com.unchan.doko", category: "DokoWeatherManager")

  public static let shared = DokoWeatherManager()

  private let weatherService: WeatherService
  private var _latestWeatherUpdate: DokoCurrentWeather?

  public var latestWeather: DokoCurrentWeather? {
    @Dependency(\.date.now) var now
    guard
      var latest = _latestWeatherUpdate,
      now.timeIntervalSince(latest.timestamp) < 660
    else {
      return nil
    }
    latest.timestamp = now
    return latest
  }

  private init() {
    self.weatherService = WeatherService()
  }

  public func currentWeather(for location: CLLocation) async -> DokoCurrentWeather? {
    @Dependency(\.date.now) var now
    do {
      let weather = try await self.weatherService.weather(for: location)
      let currentWeather = weather.currentWeather
      let dokoCurrentWeather = DokoCurrentWeather(
        timestamp: now,
        temperature: currentWeather.temperature.converted(to: .celsius).value,
        windSpeed: currentWeather.wind.speed.converted(to: .metersPerSecond).value,
        windGust: currentWeather.wind.gust?.converted(to: .metersPerSecond).value,
        windDirection: currentWeather.wind.direction.converted(to: .degrees).value,
        windCompassDirection: currentWeather.wind.compassDirection.abbreviation,
        conditionSymbol: currentWeather.symbolName
      )
      _latestWeatherUpdate = dokoCurrentWeather
      return dokoCurrentWeather
    } catch {
      logger.error("\(timestamp()) WM.currentWeather failed: \(error.localizedDescription)")
      DokoLogging.shared.postLoggingResponse(.error("WM.currentWeather failed: \(error.localizedDescription)"))
      return nil
    }
  }
}
