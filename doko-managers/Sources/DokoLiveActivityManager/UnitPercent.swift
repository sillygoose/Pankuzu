import Foundation

public final class UnitPercent: Dimension, @unchecked Sendable {
  public static let percent = UnitPercent(symbol: "%", converter: UnitConverterLinear(coefficient: 1.0))

  public override class func baseUnit() -> Self {
    percent as! Self
  }
}
