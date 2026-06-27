import FordCommon

extension FordMachE: FordTranslating {
  public var logName: String { "FME" }
  public func parseVehicleOdometer(_ response: String) throws -> Double { try parseOdometer(response) }
  public func parseVehicleSpeed(_ response: String) throws -> Double { try parseSpeed(response) }
}
