import Testing
import Vehicles

@Suite("VIN Decoder")
struct VINDecoderTests {

  // MARK: - Mustang Mach-E (WMI: 3FM)
  // Layout: 3FM | T | K<series><drive> | <engine> | X | <year> | M | <seq>

  @Test func machESelectRWD() {
    let v = Vehicle(decoding: "3FMTK1RMXMMA00001")  // K1R, engine M, year M=2021
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "Mustang Mach-E Select")
    #expect(v.make == "Ford")
    #expect(v.year == "2021")
  }

  @Test func machESelectAWD() {
    let v = Vehicle(decoding: "3FMTK1SMXNMA00001")  // K1S, year N=2022
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "Mustang Mach-E Select")
    #expect(v.year == "2022")
  }

  @Test func machECalRoute1() {
    let v = Vehicle(decoding: "3FMTK2RMXPMA00001")  // K2R, year P=2023
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "Mustang Mach-E Cal Route 1")
    #expect(v.year == "2023")
  }

  @Test func machEPremiumRWD() {
    let v = Vehicle(decoding: "3FMTK3RMXRMA00001")  // K3R, year R=2024
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "Mustang Mach-E Premium")
  }

  @Test func machEPremiumAWD() {
    let v = Vehicle(decoding: "3FMTK3SMXRMA00001")  // K3S, year R=2024
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "Mustang Mach-E Premium")
  }

  @Test func machEGT() {
    let v = Vehicle(decoding: "3FMTK4SMXRMA00001")  // K4S, year R=2024
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "Mustang Mach-E GT")
  }

  @Test func machEAllEngineCodes() {
    // All valid Mach-E engine codes: M 7 S U X E
    for engine in ["M", "7", "S", "U", "X", "E"] {
      let v = Vehicle(decoding: "3FMTK1R\(engine)XMMA00001")
      #expect(v.vehicleType == .fordElectric, "engine code \(engine) should be fordElectric")
    }
  }

  @Test func machEUnknownTrimFallback() {
    let v = Vehicle(decoding: "3FMTK9RMXRMA00001")  // K9R - unknown series
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "Mustang Mach-E")
  }

  @Test func machENonElectricEngineCode() {
    let v = Vehicle(decoding: "3FMTK1RAXMMA00001")  // engine A - not electric
    #expect(v.vehicleType == .undetermined)
  }

  // MARK: - Mustang Mach-E 2025+ (year S=2025 or newer → .fordMachE)

  @Test func machE2025SelectRWD() {
    let v = Vehicle(decoding: "3FMTK1RMXSMA00001")  // K1R, year S=2025
    #expect(v.vehicleType == .fordMachE)
    #expect(v.model == "Mustang Mach-E Select")
    #expect(v.year == "2025")
  }

  @Test func machE2025SelectAWD() {
    let v = Vehicle(decoding: "3FMTK1SMXSMA00001")  // K1S, year S=2025
    #expect(v.vehicleType == .fordMachE)
    #expect(v.model == "Mustang Mach-E Select")
    #expect(v.year == "2025")
  }

  @Test func machE2025CalRoute1() {
    let v = Vehicle(decoding: "3FMTK2RMXSMA00001")  // K2R, year S=2025
    #expect(v.vehicleType == .fordMachE)
    #expect(v.model == "Mustang Mach-E Cal Route 1")
    #expect(v.year == "2025")
  }

  @Test func machE2025PremiumRWD() {
    let v = Vehicle(decoding: "3FMTK3RMXSMA00001")  // K3R, year S=2025
    #expect(v.vehicleType == .fordMachE)
    #expect(v.model == "Mustang Mach-E Premium")
    #expect(v.year == "2025")
  }

  @Test func machE2025PremiumAWD() {
    let v = Vehicle(decoding: "3FMTK3SMXSMA00001")  // K3S, year S=2025
    #expect(v.vehicleType == .fordMachE)
    #expect(v.model == "Mustang Mach-E Premium")
    #expect(v.year == "2025")
  }

  @Test func machE2025GT() {
    let v = Vehicle(decoding: "3FMTK4SMXSMA00001")  // K4S, year S=2025
    #expect(v.vehicleType == .fordMachE)
    #expect(v.model == "Mustang Mach-E GT")
    #expect(v.year == "2025")
  }

  @Test func machE2026() {
    let v = Vehicle(decoding: "3FMTK1RMXTMA00001")  // K1R, year T=2026
    #expect(v.vehicleType == .fordMachE)
    #expect(v.year == "2026")
  }

  @Test func machE2025AllEngineCodes() {
    for engine in ["M", "7", "S", "U", "X", "E"] {
      let v = Vehicle(decoding: "3FMTK1R\(engine)XSMA00001")
      #expect(v.vehicleType == .fordMachE, "engine code \(engine) should be fordMachE for 2025")
    }
  }

  @Test func machEYearBoundary() {
    // 2024 (R) → fordElectric, 2025 (S) → fordMachE
    let v2024 = Vehicle(decoding: "3FMTK1RMXRMA00001")  // year R=2024
    #expect(v2024.vehicleType == .fordElectric)
    let v2025 = Vehicle(decoding: "3FMTK1RMXSMA00001")  // year S=2025
    #expect(v2025.vehicleType == .fordMachE)
  }

  // MARK: - F-150 Lightning 2023 (WMI: 1FT, pos5-7: W1E, engine: L or V)

  @Test func lightning2023GVWRv() {
    let v = Vehicle(decoding: "1FTVW1ELXPA000001")  // pos4=V, W1E, engine L, year P=2023
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "F-150 Lightning")
    #expect(v.make == "Ford")
    #expect(v.year == "2023")
  }

  @Test func lightning2023GVWR6() {
    let v = Vehicle(decoding: "1FT6W1EVXPA000001")  // pos4=6, W1E, engine V, year P=2023
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "F-150 Lightning")
  }

  // MARK: - F-150 Lightning 2024+ (pos5-7: W1L/W3L/W5L/W7L, engine: S K 7 M)

  @Test func lightningPro2024() {
    let v = Vehicle(decoding: "1FTVW1LMXRA000001")  // W1L, engine M, year R=2024
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "F-150 Lightning Pro")
    #expect(v.year == "2024")
  }

  @Test func lightningXLT2024() {
    let v = Vehicle(decoding: "1FTVW3LSXRA000001")  // W3L, engine S
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "F-150 Lightning XLT")
  }

  @Test func lightningLariat2024() {
    let v = Vehicle(decoding: "1FT6W5LKXRA000001")  // pos4=6, W5L, engine K
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "F-150 Lightning Lariat")
  }

  @Test func lightningPlatinum2024() {
    let v = Vehicle(decoding: "1FTVW7L7XRA000001")  // W7L, engine 7
    #expect(v.vehicleType == .fordElectric)
    #expect(v.model == "F-150 Lightning Platinum")
  }

  @Test func lightningAllEngineCodes2024() {
    for engine in ["S", "K", "7", "M"] {
      let v = Vehicle(decoding: "1FTVW1L\(engine)XRA000001")
      #expect(v.vehicleType == .fordElectric, "engine code \(engine) should be fordElectric")
    }
  }

  @Test func lightningInvalidGVWR() {
    let v = Vehicle(decoding: "1FTXW1LMXRA000001")  // pos4=X, not V or 6
    #expect(v.vehicleType == .undetermined)
  }

  @Test func lightningNonElectricEngineCode() {
    let v = Vehicle(decoding: "1FTVW1LAXRA000001")  // engine A - not electric
    #expect(v.vehicleType == .undetermined)
  }

  // MARK: - VW ID.4 (WMI: WVG or 1V2)

  @Test func vwGermanyE1() {
    // WVG + pos7-8 = E1 → ID.4
    let v = Vehicle(decoding: "WVGZZZE1ZNB000001")
    #expect(v.vehicleType == .vwElectric)
    #expect(v.model == "ID.4")
    #expect(v.make == "VW")
  }

  @Test func vwGermanyE2() {
    // WVG + pos7-8 = E2 → ID.4
    let v = Vehicle(decoding: "WVGZZZE2ZNB000001")
    #expect(v.vehicleType == .vwElectric)
    #expect(v.model == "ID.4")
    #expect(v.make == "VW")
  }

  @Test func vwGermanyInvalidPositions() {
    // WVG + pos7-8 = E8 → undetermined
    let v = Vehicle(decoding: "WVGZZZE8ZNB000001")
    #expect(v.vehicleType == .undetermined)
    #expect(v.model == "Unknown")
  }

  @Test func vwUSA() {
    // 1V2 + pos7-8 = E8 → ID.4
    let v = Vehicle(decoding: "1V2ZZZE8ZNB000001")
    #expect(v.vehicleType == .vwElectric)
    #expect(v.model == "ID.4")
    #expect(v.make == "VW")
  }

  @Test func vwUSAInvalidPositions() {
    // 1V2 + pos7-8 = E1 → undetermined (E1/E2 are German-only)
    let v = Vehicle(decoding: "1V2ZZZE1ZNB000001")
    #expect(v.vehicleType == .undetermined)
    #expect(v.model == "Unknown")
  }

  // MARK: - Edge cases

  @Test func unknownWMI() {
    let v = Vehicle(decoding: "2HMTK1RMXMMA00001")
    #expect(v.vehicleType == .undetermined)
    #expect(v.model == "Unknown")
    #expect(v.make == "Unknown")
  }

  @Test func shortVIN() {
    let v = Vehicle(decoding: "3FMTK1R")
    #expect(v.vehicleType == .undetermined)
    #expect(v.model == "Unknown")
    #expect(v.year == "Unknown")
  }

  // MARK: - Model year decoding

  @Test func modelYears() {
    let years: [(String, String)] = [
      ("M", "2021"), ("N", "2022"), ("P", "2023"),
      ("R", "2024"), ("S", "2025"), ("T", "2026"),
    ]
    for (code, expected) in years {
      // pos10 is index 9: 3FM + T + K1R + M + X + <year> + M + A00001
      let v = Vehicle(decoding: "3FMTK1RMX\(code)MA00001")
      #expect(v.year == expected, "year code \(code) should be \(expected)")
    }
  }
}
