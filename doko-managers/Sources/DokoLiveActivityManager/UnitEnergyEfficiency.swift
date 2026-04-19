import Foundation

public class UnitEnergyEfficiency: Dimension, @unchecked Sendable {
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

  public static let kilometersPerKilowattHour = UnitEnergyEfficiency(symbol: "km/kWh", converter: UnitConverterLinear(coefficient: 1.0))
  public static let milesPerKilowattHour = UnitEnergyEfficiency(symbol: "mi/kWh", converter: UnitConverterLinear(coefficient: 1.60934398))
  public static let kilowattHoursPer100Kilometers = UnitEnergyEfficiency(symbol: "kWh/100km", converter: UnitEnergyEfficiencyConverterCustom())

  override public class func baseUnit() -> Self {
    Self(symbol: "km/kWh")
  }
}
