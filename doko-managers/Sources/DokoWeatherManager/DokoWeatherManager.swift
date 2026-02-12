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
  private var meanTemperatureSum: Double = 0.0
  private var meanTemperatureCount: Int = 0
  private var isRunning: Bool = false
  private var _latestWeatherUpdate: DokoCurrentWeather?

  public var latestWeather: DokoCurrentWeather? {
    isRunning ? _latestWeatherUpdate : nil
  }

  private init() {
    self.weatherService = WeatherService()
  }

  public func startWeatherService() {
    meanTemperatureSum = 0.0
    meanTemperatureCount = 0
    _latestWeatherUpdate = nil
    isRunning = true
    logger.debug("\(timestamp()) WM.startWeatherService")
    DokoLogging.shared.postLoggingResponse(.info("WM.startWeatherService"))
  }

  public func stopWeatherService() {
    isRunning = false
    _latestWeatherUpdate = nil
    logger.debug("\(timestamp()) WM.stopWeatherService")
    DokoLogging.shared.postLoggingResponse(.info("WM.stopWeatherService"))
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
      if isRunning {
        meanTemperatureSum += dokoCurrentWeather.temperature
        meanTemperatureCount += 1
        _latestWeatherUpdate = dokoCurrentWeather
      }
      return dokoCurrentWeather
    } catch {
      logger.error("\(timestamp()) WM.currentWeather failed: \(error.localizedDescription)")
      DokoLogging.shared.postLoggingResponse(.error("WM.currentWeather failed: \(error.localizedDescription)"))
      return nil
    }
  }

  public var meanTemperature: Double? {
    guard meanTemperatureCount > 0 else {
      DokoLogging.shared.postLoggingResponse(.error("WM.meanTemperature: unexpected request"))
      return nil
    }
    return meanTemperatureSum / Double(meanTemperatureCount)
  }
}
