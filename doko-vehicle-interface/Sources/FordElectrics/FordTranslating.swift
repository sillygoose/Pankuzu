import FordCommon

extension FordElectrics: FordTranslating {
  public func parseVehicleOdometer(_ response: String) throws -> Double { try parseOdometer(response) }
  public func parseVehicleSpeed(_ response: String) throws -> Double { try parseSpeed(response) }
}
