import Foundation

public enum AppBuildInfo {
  private static var buildInfoDictionary: NSDictionary? {
    guard let path = Bundle.main.path(forResource: "BuildInfo", ofType: "plist") else { return nil }
    return NSDictionary(contentsOfFile: path)
  }

  public static var displayName: String {
    (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? "???"
  }

  public static var version: String {
    (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?.??"
  }

  public static var build: String {
    (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "?"
  }

  public static var branchName: String {
    guard let branch = buildInfoDictionary?["BranchName"] as? String else { return "???" }
    return branch == "main" ? "" : branch
  }

  public static var shortHash: String {
    (buildInfoDictionary?["ShortVersion"] as? String) ?? "???"
  }

  public static var buildDate: Date? {
    guard let dateString = buildInfoDictionary?["BuiltAt"] as? String else { return nil }
    return ISO8601DateFormatter().date(from: dateString)
  }
}
