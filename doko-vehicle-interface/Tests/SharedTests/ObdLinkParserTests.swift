import Testing
import Shared

@Suite("OBD-Link Parsers")
struct ObdLinkParserTests {

  // MARK: - ATCAF (CAN auto-formatting)

  @Test func atcafEchoOff() throws {
    try parseATCAF("OK")
  }

  @Test func atcafEcho0() throws {
    try parseATCAF("ATCAF0OK")
  }

  @Test func atcafEcho1() throws {
    try parseATCAF("ATCAF1OK")
  }

  @Test func atcafRejectsInvalidDigit() {
    #expect(throws: (any Error).self) { try parseATCAF("ATCAF2OK") }
  }

  @Test func atcafRejectsError() {
    #expect(throws: (any Error).self) { try parseATCAF("ERROR") }
  }

  // MARK: - ATCRA (set receive address)

  @Test func atcraEchoOff() throws {
    try parseATCRA("OK")
  }

  @Test func atcraHexAddress() throws {
    try parseATCRA("ATCRA7DF00OK")
  }

  @Test func atcraWildcard() throws {
    try parseATCRA("ATCRAXXXXXXXOK")
  }

  @Test func atcraRejectsInvalidHex() {
    #expect(throws: (any Error).self) { try parseATCRA("ATCRAGHEOK") }
  }

  @Test func atcraRejectsError() {
    #expect(throws: (any Error).self) { try parseATCRA("ERROR") }
  }

  // MARK: - ATE (echo on/off)

  @Test func ateEchoOff() throws {
    try parseATE("OK")
  }

  @Test func ateEcho0() throws {
    try parseATE("ATE0OK")
  }

  @Test func ateEcho1() throws {
    try parseATE("ATE1OK")
  }

  @Test func ateRejectsInvalidDigit() {
    #expect(throws: (any Error).self) { try parseATE("ATE2OK") }
  }

  @Test func ateRejectsError() {
    #expect(throws: (any Error).self) { try parseATE("ERROR") }
  }

  // MARK: - ATFCSD (flow control set data)

  @Test func atfcsdEchoOff() throws {
    try parseATFCSD("OK")
  }

  @Test func atfcsdWithData() throws {
    try parseATFCSD("ATFCSD300OK")
  }

  @Test func atfcsdRejectsMissingDigits() {
    #expect(throws: (any Error).self) { try parseATFCSD("ATFCSDOK") }
  }

  @Test func atfcsdRejectsError() {
    #expect(throws: (any Error).self) { try parseATFCSD("ERROR") }
  }

  // MARK: - ATFCSH (flow control set header)

  @Test func atfcshEchoOff() throws {
    try parseATFCSH("OK")
  }

  @Test func atfcshWithHeader() throws {
    try parseATFCSH("ATFCSH7E010FFOK")
  }

  @Test func atfcshRejectsInvalidHex() {
    #expect(throws: (any Error).self) { try parseATFCSH("ATFCSHGFOK") }
  }

  @Test func atfcshRejectsError() {
    #expect(throws: (any Error).self) { try parseATFCSH("ERROR") }
  }

  // MARK: - ATFCSM (flow control set mode)

  @Test func atfcsmEchoOff() throws {
    try parseATFCSM("OK")
  }

  @Test func atfcsmMode0() throws {
    try parseATFCSM("ATFCSM0OK")
  }

  @Test func atfcsmMode1() throws {
    try parseATFCSM("ATFCSM1OK")
  }

  @Test func atfcsmMode2() throws {
    try parseATFCSM("ATFCSM2OK")
  }

  @Test func atfcsmRejectsMode3() {
    #expect(throws: (any Error).self) { try parseATFCSM("ATFCSM3OK") }
  }

  @Test func atfcsmRejectsError() {
    #expect(throws: (any Error).self) { try parseATFCSM("ERROR") }
  }

  // MARK: - ATH (headers on/off)

  @Test func athEchoOff() throws {
    try parseATH("OK")
  }

  @Test func athHeaders0() throws {
    try parseATH("ATH0OK")
  }

  @Test func athHeaders1() throws {
    try parseATH("ATH1OK")
  }

  @Test func athRejectsInvalidDigit() {
    #expect(throws: (any Error).self) { try parseATH("ATH2OK") }
  }

  @Test func athRejectsError() {
    #expect(throws: (any Error).self) { try parseATH("ERROR") }
  }

  // MARK: - ATS (printing of spaces)

  @Test func atsEchoOff() throws {
    try parseATS("OK")
  }

  @Test func atsSpaces0() throws {
    try parseATS("ATS0OK")
  }

  @Test func atsSpaces1() throws {
    try parseATS("ATS1OK")
  }

  @Test func atsRejectsInvalidDigit() {
    #expect(throws: (any Error).self) { try parseATS("ATS2OK") }
  }

  @Test func atsRejectsError() {
    #expect(throws: (any Error).self) { try parseATS("ERROR") }
  }

  // MARK: - ATSP (set protocol)

  @Test func atspEchoOff() throws {
    try parseATSP("OK")
  }

  @Test func atspSingleDigit() throws {
    try parseATSP("ATSP6OK")
  }

  @Test func atspMultiDigit() throws {
    try parseATSP("ATSP33OK")
  }

  @Test func atspRejectsMissingDigits() {
    #expect(throws: (any Error).self) { try parseATSP("ATSPOK") }
  }

  @Test func atspRejectsError() {
    #expect(throws: (any Error).self) { try parseATSP("ERROR") }
  }

  // MARK: - ATZ (reset / firmware version)

  @Test func atzStripsPrefix() throws {
    let version = try parseATZ("ATZv2.2")
    #expect(version == "v2.2")
  }

  @Test func atzNoPrefix() throws {
    let version = try parseATZ("ELM327 v1.5")
    #expect(version == "ELM327 v1.5")
  }

  // MARK: - STCSEGR (CAN segmentation grouping)

  @Test func stcsegrEchoOff() throws {
    try parseSTCSEGR("OK")
  }

  @Test func stcsegrMode0() throws {
    try parseSTCSEGR("STCSEGR0OK")
  }

  @Test func stcsegrMode1() throws {
    try parseSTCSEGR("STCSEGR1OK")
  }

  @Test func stcsegrRejectsMode2() {
    #expect(throws: (any Error).self) { try parseSTCSEGR("STCSEGR2OK") }
  }

  @Test func stcsegrRejectsError() {
    #expect(throws: (any Error).self) { try parseSTCSEGR("ERROR") }
  }

  // MARK: - STP (set protocol by number)

  @Test func stpEchoOff() throws {
    try parseSTP("OK")
  }

  @Test func stpWithProtocol() throws {
    try parseSTP("STP33OK")
  }

  @Test func stpRejectsMissingDigits() {
    #expect(throws: (any Error).self) { try parseSTP("STPOK") }
  }

  @Test func stpRejectsError() {
    #expect(throws: (any Error).self) { try parseSTP("ERROR") }
  }

  // MARK: - STPBR (set baud rate)

  @Test func stpbrEchoOff() throws {
    try parseSTPBR("OK")
  }

  @Test func stpbrWithRate() throws {
    try parseSTPBR("STPBR9600OK")
  }

  @Test func stpbrRejectsMissingDigits() {
    #expect(throws: (any Error).self) { try parseSTPBR("STPBROK") }
  }

  @Test func stpbrRejectsError() {
    #expect(throws: (any Error).self) { try parseSTPBR("ERROR") }
  }

  // MARK: - STPO (output on)

  @Test func stpoEchoOff() throws {
    try parseSTPO("OK")
  }

  @Test func stpoWithEcho() throws {
    try parseSTPO("STPOOK")
  }

  @Test func stpoRejectsGarbage() {
    #expect(throws: (any Error).self) { try parseSTPO("NOOK") }
  }

  @Test func stpoRejectsError() {
    #expect(throws: (any Error).self) { try parseSTPO("ERROR") }
  }

  // MARK: - STPRS (report protocol string)

  @Test func stprsStripsPrefix() throws {
    let proto = try parseSTPRS("STPRSCISO 15765-4:500")
    #expect(proto == "CISO 15765-4:500")
  }

  @Test func stprsNoPrefix() throws {
    let proto = try parseSTPRS("CAN 11/500")
    #expect(proto == "CAN 11/500")
  }

}
