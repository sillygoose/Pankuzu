import OSLog
import DokoTypes
import VehicleCommon

public protocol FordTranslating: Actor {
  var logger: Logger { get }
  var logName: String { get }
  var responseCache: DokoResponseDictionary { get set }
  var hvBatteryEnergy: PowerEnergyIntegrator { get set }
  var chargerInputEnergy: PowerEnergyIntegrator { get set }
  var chargerOutputEnergy: PowerEnergyIntegrator { get set }
  var vehicleOdometer: EnhancedOdometer { get set }
  var vehicleDuration: DurationTracker { get set }
  var vehicleMeanTemperature: MeanTemperature { get set }
  var vehicleEfficiency: TripEfficiency<ContinuousClock> { get set }

  func parseVehicleOdometer(_ response: String) throws -> Double
  func parseVehicleSpeed(_ response: String) throws -> Double
}
