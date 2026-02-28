import SwiftUI
import WeatherKit

import CommonUI

@MainActor
@Observable
class AboutModel {
  var combinedMarkDarkURL: URL?
  var legalPageURL: URL?
  
  public static var displayName: String? {
    guard
      let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    else { return nil }
    return "\(displayName)"
  }
  
  public static var branchName: String? {
    guard let dictionaryPath = Bundle.main.path(forResource: "BuildInfo", ofType: "plist"),
          let dictionary = NSDictionary(contentsOfFile: dictionaryPath)
    else { return nil }
    guard let build =  dictionary["BranchName"] as? String else { return nil }
    return build == "main" ? "" : build
  }

  public static var shortHash: String? {
    guard let dictionaryPath = Bundle.main.path(forResource: "BuildInfo", ofType: "plist"),
          let dictionary = NSDictionary(contentsOfFile: dictionaryPath)
    else { return nil }
    return dictionary["ShortVersion"] as? String
  }
  
  public static var buildDate: Date? {
    guard let dictionaryPath = Bundle.main.path(forResource: "BuildInfo", ofType: "plist"),
          let dictionary = NSDictionary(contentsOfFile: dictionaryPath),
          let dateString = dictionary["BuiltAt"] as? String
    else { return nil }
    return ISO8601DateFormatter().date(from: dateString)
  }
  
  public static var version: String? {
    guard
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    else { return nil }
    return "\(version)"
  }
  
  public static var build: String? {
    guard
      let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    else { return nil }
    return "\(build)"
  }
}

struct AboutView: View {
  @Bindable var model: AboutModel
  
  var body: some View {
    let displayName = AboutModel.displayName ?? "???"
    let version = AboutModel.version ?? "?.??"
    let build = AboutModel.build ?? "?"
    let shortHash = AboutModel.shortHash ?? "???"
    let branchName = AboutModel.branchName ?? "???"

    let aboutText =
    """
    \(displayName) is an EV utility application that records your trips and charges \
    and aggregates the data to let you make the most of your vehicle's performance \
    and history.
    """

    ScrollView {
      VStack(alignment: .leading) {
        Section {
          Text("\(displayName) \(version).\(build) \(branchName)(\(shortHash))")
        }
        .padding([.bottom], 20)

        Section {
          Text("\(aboutText)")
        }
        .padding([.bottom], 20)

        Section {
          Text("Pankuzu is open source software, code, issues, discussions, and more are on [GitHub](https://github.com/sillygoose/Pankuzu).")
        }
        .padding([.bottom], 20)

        Section {
          Text("Special thanks for the following Swift packages that made this app possible:")
        }
        .padding([.bottom], 20)

        Section {
          VStack(alignment: .leading, spacing: 20) {
            HStack {
              Text("PointFree")
              Spacer()
              Link("SQLiteData", destination: URL(string: "https://github.com/pointfreeco/sqlite-data")!)
            }
            HStack {
              Spacer()
              Link("Parsing", destination: URL(string: "https://github.com/pointfreeco/swift-parsing")!)
            }
            HStack {
              Spacer()
              Link("Sharing", destination: URL(string: "https://github.com/pointfreeco/swift-sharing")!)
            }
          }
        }
        .padding([.bottom], 20)

        Section {
          VStack(alignment: .leading, spacing: 20) {
            HStack {
              Text("Gwendal Roué")
              Spacer()
              Link("GRDB", destination: URL(string: "https://github.com/groue/GRDB.swift")!)
            }
          }
        }
        .padding([.bottom], 30)

        Section {
          HStack {
            if let combinedMarkDarkURL = model.combinedMarkDarkURL {
              AsyncImage(url: combinedMarkDarkURL) { image in
                image.resizable().scaledToFit().frame(height: 14)
              } placeholder: { ProgressView() }
              Spacer()
              if let legalPageURL = model.legalPageURL {
                Link("Other weather data sources", destination: legalPageURL)
              }
            }
          }
        } header: {
          Text("Weather Provider")
        } footer: {
          Text("Weather data is supplied by Apple Weather, click the link for the third-party data sources.")
            .font(DesignTokens.Font.caption)
            .opacity(DesignTokens.Opacity.muted)
        }
      }
      .padding()
    }
    .navigationTitle("About")
    .task {
      let weatherService = WeatherService()
      guard let weatherAttribution = try? await weatherService.attribution else { return }
      model.combinedMarkDarkURL = weatherAttribution.combinedMarkDarkURL
      model.legalPageURL = weatherAttribution.legalPageURL
    }
  }
}

#Preview {
  NavigationStack {
    AboutView(
      model: AboutModel()
    )
    .preferredColorScheme(.dark)
  }
}
