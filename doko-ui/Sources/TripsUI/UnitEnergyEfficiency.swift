import Foundation

class UnitEnergyEfficiency: Dimension, @unchecked Sendable {
  class UnitEnergyEfficiencyConverterCustom: UnitConverter {
    override func baseUnitValue(fromValue: Double) -> Double {
      if fromValue == 0 { return 0 }
      return 1 / fromValue * 100
    }

    override func value(fromBaseUnitValue: Double) -> Double {
      if fromBaseUnitValue == 0 { return 0 }
      return 1.0 / fromBaseUnitValue * 100.0
    }
  }

  static let kilometersPerKilowattHour = UnitEnergyEfficiency(symbol: "km/kWh", converter: UnitConverterLinear(coefficient: 1.0))
  static let milesPerKilowattHour = UnitEnergyEfficiency(symbol: "mi/kWh", converter: UnitConverterLinear(coefficient: 1.60934398))
  static let kilowattHoursPer100Kilometers = UnitEnergyEfficiency(symbol: "kWh/100km", converter: UnitEnergyEfficiencyConverterCustom())

  override class func baseUnit() -> Self {
    Self(symbol: "km/kWh")
  }
}
