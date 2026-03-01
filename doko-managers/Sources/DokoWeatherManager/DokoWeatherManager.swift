import CoreLocation
import WeatherKit
import OSLog

import DokoTypes
import DokoLogging

@DokoEngineActor
public final class DokoWeatherManager: Sendable {
  private let logger = Logger(subsystem: "com.unchan.doko", category: "DokoWeatherManager")

  public static let shared = DokoWeatherManager()

  private let weatherService: WeatherService
  private var _latestWeatherUpdate: DokoCurrentWeather?

  public var latestWeather: DokoCurrentWeather? {
    guard
      let latest = _latestWeatherUpdate,
      Date.now.timeIntervalSince(latest.timestamp) < 660
    else { return nil }
    return latest
  }

  private init() {
    self.weatherService = WeatherService()
  }

  public func currentWeather(for location: CLLocation) async -> DokoCurrentWeather? {
    do {
      let weather = try await self.weatherService.weather(for: location)
      let currentWeather = weather.currentWeather
      let dokoCurrentWeather = DokoCurrentWeather(
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
