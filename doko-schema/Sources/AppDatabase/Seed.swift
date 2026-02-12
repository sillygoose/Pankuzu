import Foundation

import SQLiteData

import Vehicles
import Locations
import Trips
import Charges
import DokoSchemaTypes

private let f150VehicleID: String = "1FTVW3L76RWG00000"
private let machEVehicleID: String = "3FMTK4SE2NMA00000"
private let id4VehicleID: String = "1V2DNPE81PC030349"

private let kwikFillLocationID: UUID = UUID(0x1)
private let byrneDairyLocationID: UUID = UUID(0x2)
private let evolveNYLocationID: UUID = UUID(0x3)
private let villageHallLocationID: UUID = UUID(0x4)

private let todayTripStart: Date = Date.now.addingTimeInterval(-3 * 60 * 60)
private let todayTripEnd: Date = todayTripStart.addingTimeInterval(10 * 60)

private let pastWeekTripStart: Date = Date.now.addingTimeInterval(-3 * 24 * 60 * 60)
private let pastWeekTripEnd: Date = pastWeekTripStart.addingTimeInterval(10 * 60)

private let pastMonthTripStart: Date = Date.now.addingTimeInterval(-13 * 24 * 60 * 60)
private let pastMonthTripEnd: Date = pastMonthTripStart.addingTimeInterval(10 * 60)

private let customTripStart: Date = Date.now.addingTimeInterval(-40 * 24 * 60 * 60)
private let customTripEnd: Date = customTripStart.addingTimeInterval(10 * 60)

private let deletedTripStart: Date = Date.now.addingTimeInterval(-1 * 24 * 60 * 60)
private let deletedTripEnd: Date = pastMonthTripStart.addingTimeInterval(10 * 60)

private let todayTripID: UUID = UUID(0x1)
private let pastWeekTripID: UUID = UUID(0x2)
private let pastMonthTripID: UUID = UUID(0x3)
private let customTripID: UUID = UUID(0x4)
private let deletedTripID: UUID = UUID(0x5)

private let todayChargeStart: Date = Date.now.addingTimeInterval(-3 * 60 * 60)
private let todayChargeEnd: Date = todayChargeStart.addingTimeInterval(10 * 60)

private let pastWeekChargeStart: Date = Date.now.addingTimeInterval(-3 * 24 * 60 * 60)
private let pastWeekChargeEnd: Date = pastWeekChargeStart.addingTimeInterval(10 * 60)

private let pastMonthChargeStart: Date = Date.now.addingTimeInterval(-13 * 24 * 60 * 60)
private let pastMonthChargeEnd: Date = pastMonthChargeStart.addingTimeInterval(10 * 60)

private let customChargeStart: Date = Date.now.addingTimeInterval(-40 * 24 * 60 * 60)
private let customChargeEnd: Date = customChargeStart.addingTimeInterval(10 * 60)

private let deletedChargeStart: Date = Date.now.addingTimeInterval(-1 * 24 * 60 * 60)
private let deletedChargeEnd: Date = pastMonthChargeStart.addingTimeInterval(10 * 60)

private let todayChargeID: UUID = UUID(0x1)
private let pastWeekChargeID: UUID = UUID(0x2)
private let pastMonthChargeID: UUID = UUID(0x3)
private let customChargeID: UUID = UUID(0x4)
private let deletedChargeID: UUID = UUID(0x5)

private let todayPositions: [VehiclePosition] = [
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(0 * todayPositionIncrement), latitude: 42.944847, longitude: -76.447141, elevation: 301),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(1 * todayPositionIncrement), latitude: 42.94405, longitude: -76.44689, elevation: 301),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(2 * todayPositionIncrement), latitude: 42.94405, longitude: -76.44689, elevation: 301),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(3 * todayPositionIncrement), latitude: 42.94405, longitude: -76.44689, elevation: 285),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(4 * todayPositionIncrement), latitude: 42.94467, longitude: -76.43706, elevation: 271),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(5 * todayPositionIncrement), latitude: 42.94467, longitude: -76.43706,  elevation: 267),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(6 * todayPositionIncrement), latitude: 42.94504, longitude: -76.43162, elevation: 264),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(7 * todayPositionIncrement), latitude: 42.94504, longitude: -76.43162, elevation: 264),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(8 * todayPositionIncrement), latitude: 42.94576, longitude: -76.4293, elevation: 265),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(9 * todayPositionIncrement), latitude: 42.94576, longitude: -76.4293, elevation: 267),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(10 * todayPositionIncrement), latitude: 42.94535, longitude: -76.42546, elevation: 268),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(11 * todayPositionIncrement), latitude: 42.94535, longitude: -76.42546, elevation: 276),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(12 * todayPositionIncrement), latitude: 42.94458, longitude: -76.41928, elevation: 284),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(13 * todayPositionIncrement), latitude: 42.94458, longitude: -76.41928, elevation: 291),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(14 * todayPositionIncrement), latitude: 42.94432, longitude: -76.41716, elevation: 298),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(15 * todayPositionIncrement), latitude: 42.94432, longitude: -76.41716, elevation: 297),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(16 * todayPositionIncrement), latitude: 42.94426, longitude: -76.41594, elevation: 296),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(17 * todayPositionIncrement), latitude: 42.94426, longitude: -76.41594, elevation: 294),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(18 * todayPositionIncrement), latitude: 42.94462, longitude: -76.40959, elevation: 293),
  VehiclePosition(timestamp: todayTripStart.addingTimeInterval(19 * todayPositionIncrement), latitude: 42.94462, longitude: -76.40959, elevation: 292),
  VehiclePosition(timestamp: todayTripEnd, latitude: 42.944902, longitude: -76.409327, elevation: 300)
]
private let todayPositionIncrement: TimeInterval = todayTripEnd.timeIntervalSince(todayTripStart) / 21

private let todayElevations: [VehicleElevation] = [
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(0 * todayElevationIncrement), elevation: 301),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(1 * todayElevationIncrement), elevation: 301),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(2 * todayElevationIncrement), elevation: 301),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(3 * todayElevationIncrement), elevation: 285),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(4 * todayElevationIncrement), elevation: 271),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(5 * todayElevationIncrement), elevation: 267),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(6 * todayElevationIncrement), elevation: 264),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(7 * todayElevationIncrement), elevation: 264),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(8 * todayElevationIncrement), elevation: 265),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(9 * todayElevationIncrement), elevation: 267),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(10 * todayElevationIncrement), elevation: 268),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(11 * todayElevationIncrement), elevation: 276),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(12 * todayElevationIncrement), elevation: 284),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(13 * todayElevationIncrement), elevation: 291),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(14 * todayElevationIncrement), elevation: 298),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(15 * todayElevationIncrement), elevation: 297),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(16 * todayElevationIncrement), elevation: 296),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(17 * todayElevationIncrement), elevation: 294),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(18 * todayElevationIncrement), elevation: 293),
  VehicleElevation(timestamp: todayTripStart.addingTimeInterval(19 * todayElevationIncrement), elevation: 292),
  VehicleElevation(timestamp: todayTripEnd, elevation: 300)
]
private let todayElevationIncrement: TimeInterval = todayTripEnd.timeIntervalSince(todayTripStart) / 21

private let todayTripBatteryEnergy: [DokoDataPoint] = [
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(0 * todayBateryEnergyIncrement), double: 0.0),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(1 * todayBateryEnergyIncrement), double: 0.3),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(2 * todayBateryEnergyIncrement), double: 0.4),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(3 * todayBateryEnergyIncrement), double: 0.6),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(4 * todayBateryEnergyIncrement), double: 0.8),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(5 * todayBateryEnergyIncrement), double: 1.1),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(6 * todayBateryEnergyIncrement), double: 1.2),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(7 * todayBateryEnergyIncrement), double: 1.35),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(8 * todayBateryEnergyIncrement), double: 1.4),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(9 * todayBateryEnergyIncrement), double: 1.5),
]
private let todayBateryEnergyIncrement: TimeInterval = todayTripEnd.timeIntervalSince(todayTripStart) / 10

private let todayTripEnergyToEmpty: [DokoDataPoint] = [
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(0 * todayEteIncrement), double: 67),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(1 * todayEteIncrement), double: 66.6),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(2 * todayEteIncrement), double: 66.5),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(3 * todayEteIncrement), double: 66.3),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(4 * todayEteIncrement), double: 66.4),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(5 * todayEteIncrement), double: 66.47),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(6 * todayEteIncrement), double: 66.41),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(7 * todayEteIncrement), double: 66.21),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(8 * todayEteIncrement), double: 65.99),
  DokoDataPoint(timestamp: todayTripStart.addingTimeInterval(9 * todayEteIncrement), double: 65.84),
]
private let todayEteIncrement: TimeInterval = todayTripEnd.timeIntervalSince(todayTripStart) / 10

private let dcfcChargePower: [DokoDataPoint] = [
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(0 * dcfcChargePowerIncrement), double: 1),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(1 * dcfcChargePowerIncrement), double: 20),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(2 * dcfcChargePowerIncrement), double: 78),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(3 * dcfcChargePowerIncrement), double: 120),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(4 * dcfcChargePowerIncrement), double: 150),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(5 * dcfcChargePowerIncrement), double: 170),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(6 * dcfcChargePowerIncrement), double: 168),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(7 * dcfcChargePowerIncrement), double: 165),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(8 * dcfcChargePowerIncrement), double: 164),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(9 * dcfcChargePowerIncrement), double: 160),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(10 * dcfcChargePowerIncrement), double: 150),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(11 * dcfcChargePowerIncrement), double: 140),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(12 * dcfcChargePowerIncrement), double: 130),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(13 * dcfcChargePowerIncrement), double: 120),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(14 * dcfcChargePowerIncrement), double: 110),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(15 * dcfcChargePowerIncrement), double: 100),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(16 * dcfcChargePowerIncrement), double: 90),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(17 * dcfcChargePowerIncrement), double: 80),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(18 * dcfcChargePowerIncrement), double: 50),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(19 * dcfcChargePowerIncrement), double: 30)
]
private let dcfcChargePowerIncrement: TimeInterval = todayChargeEnd.timeIntervalSince(todayChargeStart) / 20

private let dcfcChargeEnergy: [DokoDataPoint] = [
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(0 * dcfcChargeEnergyIncrement), double: 0.0),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(1 * dcfcChargeEnergyIncrement), double: 1.5),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(2 * dcfcChargeEnergyIncrement), double: 6.0),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(3 * dcfcChargeEnergyIncrement), double: 9.5),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(4 * dcfcChargeEnergyIncrement), double: 11),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(5 * dcfcChargeEnergyIncrement), double: 13),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(6 * dcfcChargeEnergyIncrement), double: 18),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(7 * dcfcChargeEnergyIncrement), double: 22.8),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(8 * dcfcChargeEnergyIncrement), double: 27.9),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(9 * dcfcChargeEnergyIncrement), double: 31.8),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(10 * dcfcChargeEnergyIncrement), double: 36),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(11 * dcfcChargeEnergyIncrement), double: 40),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(12 * dcfcChargeEnergyIncrement), double: 43),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(13 * dcfcChargeEnergyIncrement), double: 46),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(14 * dcfcChargeEnergyIncrement), double: 49),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(15 * dcfcChargeEnergyIncrement), double: 51),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(16 * dcfcChargeEnergyIncrement), double: 53),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(17 * dcfcChargeEnergyIncrement), double: 55),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(18 * dcfcChargeEnergyIncrement), double: 57),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(19 * dcfcChargeEnergyIncrement), double: 58)
]
private let dcfcChargeEnergyIncrement: TimeInterval = todayChargeEnd.timeIntervalSince(todayChargeStart) / 20

private let dcfcChargeEte: [DokoDataPoint] = [
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(0 * dcfcChargeEteIncrement), double: 23.65),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(1 * dcfcChargeEteIncrement), double: 25.5),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(2 * dcfcChargeEteIncrement), double: 30),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(3 * dcfcChargeEteIncrement), double: 33.25),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(4 * dcfcChargeEteIncrement), double: 34),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(5 * dcfcChargeEteIncrement), double: 35),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(6 * dcfcChargeEteIncrement), double: 40),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(7 * dcfcChargeEteIncrement), double: 45),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(8 * dcfcChargeEteIncrement), double: 50),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(9 * dcfcChargeEteIncrement), double: 59),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(10 * dcfcChargeEteIncrement), double: 63),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(11 * dcfcChargeEteIncrement), double: 67),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(12 * dcfcChargeEteIncrement), double: 70),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(13 * dcfcChargeEteIncrement), double: 73),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(14 * dcfcChargeEteIncrement), double: 76),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(15 * dcfcChargeEteIncrement), double: 80),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(16 * dcfcChargeEteIncrement), double: 82),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(17 * dcfcChargeEteIncrement), double: 83),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(18 * dcfcChargeEteIncrement), double: 85),
  DokoDataPoint(timestamp: todayChargeStart.addingTimeInterval(19 * dcfcChargeEteIncrement), double: 86)
]
private let dcfcChargeEteIncrement: TimeInterval = todayChargeEnd.timeIntervalSince(todayChargeStart) / 20

private let acChargePower: [DokoDataPoint] = [
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(0 * acChargePowerIncrement), double: 0),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(1 * acChargePowerIncrement), double: 2),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(2 * acChargePowerIncrement), double: 4),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(3 * acChargePowerIncrement), double: 8),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(4 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(5 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(6 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(7 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(8 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(9 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(10 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(11 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(12 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(13 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(14 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(15 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(16 * acChargePowerIncrement), double: 10.5),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(17 * acChargePowerIncrement), double: 9),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(18 * acChargePowerIncrement), double: 8),
  DokoDataPoint(timestamp: pastWeekChargeStart.addingTimeInterval(19 * acChargePowerIncrement), double: 5)
]
private let acChargePowerIncrement: TimeInterval = pastWeekChargeEnd.timeIntervalSince(pastWeekChargeStart) / 20

private let todayTripWeather: [DokoWeather] = [
  DokoWeather(timestamp: todayTripStart, temperature: 20, windSpeed: 6, windDirection: 90, windCompassDirection: "S", conditionSymbol: "cloud.drizzle"),
  DokoWeather(timestamp: todayTripStart.addingTimeInterval(10 * todayPositionIncrement), temperature: 19, windSpeed: 6, windDirection: 90, windCompassDirection: "S", conditionSymbol: "cloud.fog"),
  DokoWeather(timestamp: todayTripEnd, temperature: 23, windSpeed: 8, windGust: 12, windDirection: 78, windCompassDirection: "S", conditionSymbol: "sun.max")
]

private let todayChargeWeather: [DokoWeather] = [
  DokoWeather(timestamp: todayChargeStart, temperature: 10, windSpeed: 2, windGust: 4, windDirection: 90, windCompassDirection: "S", conditionSymbol: "cloud.snow"),
  DokoWeather(timestamp: todayChargeStart.addingTimeInterval(10 * dcfcChargePowerIncrement), temperature: 11, windSpeed: 6, windDirection: 90, windCompassDirection: "S", conditionSymbol: "sun.snow"),
  DokoWeather(timestamp: todayChargeEnd, temperature: 9, windSpeed: 3, windGust: 6, windDirection: 99, windCompassDirection: "S", conditionSymbol: "wind.snow")
]

extension DatabaseWriter {
  public func seedPreviews() throws {
    try write { db in
      try db.seed {
        Vehicle.Draft(id: f150VehicleID)
        Vehicle.Draft(id: machEVehicleID)
        Vehicle.Draft(id: id4VehicleID)

        Location(
          id: kwikFillLocationID,
          latitude: 42.944847, longitude: -76.447141, elevation: 301,
          name: "Kwik Fill",
          street: "791 W Genesee Street Rd", city: "Skaneateles", stateProv: "NY", region: "US"
        )
        Location(
          id: byrneDairyLocationID,
          latitude: 42.944902, longitude: -76.409327, elevation: 300,
          name: "Byrne Dairy",
          street: "1387 East Genesee Street", city: "Skaneateles", stateProv: "NY", region: "US"
        )
        Location(
          id: evolveNYLocationID,
          latitude: 42.947846, longitude: -76.428322, elevation: 300,
          name: "EVolve NY",
          street: "38 Jordan St.", city: "Skaneateles", stateProv: "NY", region: "US"
        )
        Location(
          id: villageHallLocationID,
          latitude: 42.948219, longitude: -76.431343, elevation: 300,
          name: "Skaneateles Village Hall",
          street: "22 Fennell St.", city: "Skaneateles", stateProv: "NY", region: "US"
        )

        Trip(
          id: todayTripID,
          deleted: nil,
          vehicleID: f150VehicleID,
          originID: kwikFillLocationID,
          destinationID: byrneDairyLocationID,
          latitudeStart: 42.944847,
          longitudeStart: -76.447141,
          elevationStart: 301,
          latitudeEnd: 42.944902,
          longitudeEnd: -76.409327,
          elevationEnd: 292,
          timeStart: todayTripStart,
          timeEnd: todayTripEnd,
          odometerStart: 1000,
          odometerEnd: 1003.2,
          energy: -1.2,
          energyToEmptyStart: 67,
          energyToEmptyEnd: 65.8,
          distanceToEmptyStart: 83,
          distanceToEmptyEnd: 42,
          stateOfChargeStart: 83.5,
          stateOfChargeEnd: 52.0,
          batteryStateOfHealth: 91,
          batteryTempStart: 5,
          batteryTempEnd: 10,
          weatherTempStart: 10,
          weatherTempEnd: 13,
          weatherTempMeanWeighted: 12 * todayTripEnd.timeIntervalSince(todayTripStart),
          weatherConditionsStart: "cloud.drizzle",
          weatherConditionsEnd: "sun.haze",
        )
        TripPosition(
          tripID: todayTripID,
          path: todayPositions
        )
        TripElevation(
          tripID: todayTripID,
          elevations: todayElevations
        )
        TripData(
          tripID: todayTripID,
          batteryEnergy: todayTripBatteryEnergy,
          energyToEmpty: todayTripEnergyToEmpty
        )
        TripWeather(
          tripID: todayTripID,
          weather: todayTripWeather
        )
        Trip(
          id: pastWeekTripID,
          deleted: nil,
          vehicleID: machEVehicleID,
          originID: kwikFillLocationID,
          destinationID: byrneDairyLocationID,
          latitudeStart: 42.944847,
          longitudeStart: -76.447141,
          elevationStart: 301,
          latitudeEnd: 42.944902,
          longitudeEnd: -76.409327,
          elevationEnd: 292,
          timeStart: pastWeekTripStart,
          timeEnd: pastWeekTripStart,
          odometerStart: 1000,
          odometerEnd: 1003.2,
          energy: -1.2,
          energyToEmptyStart: 67,
          energyToEmptyEnd: 65.8,
          distanceToEmptyStart: 83,
          distanceToEmptyEnd: 42,
          stateOfChargeStart: 83.2,
          stateOfChargeEnd: 42.1,
          batteryStateOfHealth: 91,
          batteryTempStart: 5,
          batteryTempEnd: 10,
        )
        TripPosition(
          tripID: pastWeekTripID,
          path: todayPositions
        )
        Trip(
          id: pastMonthTripID,
          deleted: nil,
          vehicleID: id4VehicleID,
          originID: kwikFillLocationID,
          destinationID: byrneDairyLocationID,
          latitudeStart: 42.944847,
          longitudeStart: -76.447141,
          elevationStart: 301,
          latitudeEnd: 42.944902,
          longitudeEnd: -76.409327,
          elevationEnd: 292,
          timeStart: pastMonthTripStart,
          timeEnd: pastMonthTripStart,
          odometerStart: 1000,
          odometerEnd: 1003.2,
          energy: -1.2,
          energyToEmptyStart: 67,
          energyToEmptyEnd: 65.8,
          distanceToEmptyStart: 83,
          distanceToEmptyEnd: 42,
          stateOfChargeStart: 83.2,
          stateOfChargeEnd: 42.1,
          batteryStateOfHealth: 91,
          batteryTempStart: 5,
          batteryTempEnd: 10,
        )
        TripPosition(
          tripID: pastMonthTripID,
          path: todayPositions
        )
        Trip(
          id: customTripID,
          deleted: nil,
          vehicleID: id4VehicleID,
          originID: kwikFillLocationID,
          destinationID: byrneDairyLocationID,
          latitudeStart: 42.944847,
          longitudeStart: -76.447141,
          elevationStart: 301,
          latitudeEnd: 42.944902,
          longitudeEnd: -76.409327,
          elevationEnd: 292,
          timeStart: customTripStart,
          timeEnd: customTripStart,
          odometerStart: 1000,
          odometerEnd: 1003.2,
          energy: -1.2,
          energyToEmptyStart: 67,
          energyToEmptyEnd: 65.8,
          distanceToEmptyStart: 83,
          distanceToEmptyEnd: 42,
          stateOfChargeStart: 83.2,
          stateOfChargeEnd: 42.1,
          batteryStateOfHealth: 91,
          batteryTempStart: 5,
          batteryTempEnd: 10,
        )
        TripPosition(
          tripID: customTripID,
          path: todayPositions
        )
        Trip(
          id: deletedTripID,
          deleted: Date.now,
          vehicleID: id4VehicleID,
          originID: kwikFillLocationID,
          destinationID: byrneDairyLocationID,
          latitudeStart: 42.944847,
          longitudeStart: -76.447141,
          elevationStart: 301,
          latitudeEnd: 42.944902,
          longitudeEnd: -76.409327,
          elevationEnd: 292,
          timeStart: deletedTripStart,
          timeEnd: deletedTripEnd,
          odometerStart: 1000,
          odometerEnd: 1003.2,
          energy: -1.2,
          energyToEmptyStart: 67,
          energyToEmptyEnd: 65.8,
          distanceToEmptyStart: 83,
          distanceToEmptyEnd: 42,
          stateOfChargeStart: 83.2,
          stateOfChargeEnd: 42.1,
          batteryStateOfHealth: 91,
          batteryTempStart: 5,
          batteryTempEnd: 10,
        )
        TripPosition(
          tripID: deletedTripID,
          path: todayPositions
        )

        Charge(
          id: todayChargeID,
          deleted: nil,
          vehicleID: f150VehicleID,
          locationID: evolveNYLocationID,
          latitude: 42.947846,
          longitude: -76.428322,
          elevation: 271,
          timeStart: todayChargeStart,
          timeEnd: todayChargeEnd,
          chargerType: .dc,
          odometer: 1000,
          energy: 55,
          energyToEmptyStart: 18,
          energyToEmptyEnd: 73,
          stateOfChargeStart: 23,
          stateOfChargeEnd: 80,
          batteryStateOfHealth: 99.5,
          batteryTempStart: 23,
          batteryTempEnd: 52,
          couplerTempStart: 25,
          couplerTempEnd: 75,
          weatherTempStart: 16,
          weatherConditionsStart: "sun.snow",
        )
        ChargeHistory(
          chargeID: todayChargeID,
          batteryPower: dcfcChargePower,
          batteryEnergy: dcfcChargeEnergy,
          energyToEmpty: dcfcChargeEte
        )
        Charge(
          id: pastWeekChargeID,
          deleted: nil,
          vehicleID: machEVehicleID,
          locationID: villageHallLocationID,
          latitude: 42.948219,
          longitude: -76.431343,
          elevation: 271,
          timeStart: pastWeekChargeStart,
          timeEnd: pastWeekChargeEnd,
          chargerType: .ac,
          odometer: 1000,
          energy: 55,
          energyToEmptyStart: 18,
          energyToEmptyEnd: 73,
          stateOfChargeStart: 23,
          stateOfChargeEnd: 80,
          batteryStateOfHealth: 88,
        )
        ChargeHistory(
          chargeID: pastWeekChargeID,
          batteryPower: acChargePower
        )
        Charge(
          id: pastMonthChargeID,
          deleted: nil,
          vehicleID: id4VehicleID,
          locationID: villageHallLocationID,
          latitude: 42.948219,
          longitude: -76.431343,
          elevation: 271,
          timeStart: pastMonthChargeStart,
          timeEnd: pastMonthChargeEnd,
          chargerType: .ac,
          odometer: 1000,
          energy: 55,
          energyToEmptyStart: 18,
          energyToEmptyEnd: 73,
          distanceToEmptyStart: 76,
          distanceToEmptyEnd: 280,
          stateOfChargeStart: 23,
          stateOfChargeEnd: 85,
          batteryStateOfHealth: 98
        )
        ChargeHistory(
          chargeID: pastMonthChargeID,
          batteryPower: acChargePower
        )
        Charge(
          id: customChargeID,
          deleted: nil,
          vehicleID: id4VehicleID,
          locationID: villageHallLocationID,
          latitude: 42.948219,
          longitude: -76.431343,
          elevation: 271,
          timeStart: customChargeStart,
          timeEnd: customChargeEnd,
          chargerType: .ac,
          odometer: 1000,
          energy: 55,
          energyToEmptyStart: 18,
          energyToEmptyEnd: 73,
          distanceToEmptyStart: 76,
          distanceToEmptyEnd: 280,
          stateOfChargeStart: 23,
          stateOfChargeEnd: 85,
          batteryStateOfHealth: 98
        )
        ChargeHistory(
          chargeID: customChargeID,
          batteryPower: acChargePower
        )
        Charge(
          id: deletedChargeID,
          deleted: Date.now,
          vehicleID: id4VehicleID,
          locationID: villageHallLocationID,
          latitude: 42.948219,
          longitude: -76.431343,
          elevation: 271,
          timeStart: deletedChargeStart,
          timeEnd: deletedChargeEnd,
          chargerType: .ac,
          odometer: 1000,
          energy: 55,
          energyToEmptyStart: 18,
          energyToEmptyEnd: 73,
          distanceToEmptyStart: 155,
          distanceToEmptyEnd: 80,
          stateOfChargeStart: 23,
          stateOfChargeEnd: 80,
        )
        ChargeHistory(
          chargeID: deletedChargeID,
          batteryPower: acChargePower
        )
      }
    }
  }
}
