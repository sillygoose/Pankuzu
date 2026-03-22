import Foundation
import OSLog

import DokoLogging

public enum ABRPError: Error, Sendable {
  case encodingFailed
  case invalidURL
  case serverError(Int)
}

public struct ABRPClient: Sendable {
  static let baseURL = URL(string: "https://api.iternio.com/1/tlm/send")!
  let apiKey: String

  public init() {
    self.apiKey = Bundle.main.object(forInfoDictionaryKey: "ABRPAPIKey") as? String ?? ""
  }

  public func send(telemetry: ABRPTelemetry, userToken: String) async throws {
    guard let tlmJSON = telemetry.jsonString else {
      throw ABRPError.encodingFailed
    }

    var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false)!
    components.queryItems = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "token", value: userToken),
      URLQueryItem(name: "tlm", value: tlmJSON),
    ]
    guard let url = components.url else {
      throw ABRPError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 10

    let (_, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw ABRPError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1)
    }
  }
}
