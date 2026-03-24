import SwiftUI
import Charts
import WeatherKit

import CommonUI
import DokoTypes
import DokoSharing
import DokoSchema

@MainActor
@Observable
public final class TripDetailWeatherModel {
  var trip: Trip
  
  @ObservationIgnored
  @FetchOne(TripWeather.none) var tripWeather
  
  @ObservationIgnored
  @Shared(.appSettings) var appSettings
  
  var combinedMarkDarkURL: URL?
  var legalPageURL: URL?

  var weatherConditions: [DokoWeather] = []
  var downsampledWeatherConditions: [DokoWeather] = []

  var minimumTemperature: Measurement<UnitTemperature> = .init(value: 0, unit: .celsius)
  var maximumTemperature: Measurement<UnitTemperature> = .init(value: 0, unit: .celsius)
  var meanTemperature: Measurement<UnitTemperature>?

  public init(
    trip: Trip
  ) {
    self.trip = trip
    _tripWeather = FetchOne(TripWeather.find(trip.id))

    guard let tripWeather else { return }
    weatherConditions = tripWeather.weather
    guard !weatherConditions.isEmpty else { return }

    downsampledWeatherConditions = downsample(weatherConditions, maxPoints: 5)

    var minTemp: Double = .greatestFiniteMagnitude
    var maxTemp: Double = -.greatestFiniteMagnitude
    for weatherCondition in tripWeather.weather {
      minTemp = min(minTemp, weatherCondition.temperature)
      maxTemp = max(maxTemp, weatherCondition.temperature)
    }
    minimumTemperature = Measurement(value: floor(minTemp - 1), unit: UnitTemperature.celsius)
      .converted(to: appSettings.metric ? .celsius : .fahrenheit)
    maximumTemperature = Measurement(value: ceil(maxTemp + 1), unit: UnitTemperature.celsius)
      .converted(to: appSettings.metric ? .celsius : .fahrenheit)
    if let weighted = trip.weatherTempMeanWeighted, trip.duration > 0 {
      meanTemperature = Measurement(value: weighted / trip.duration, unit: UnitTemperature.celsius)
        .converted(to: appSettings.metric ? .celsius : .fahrenheit)
    }
  }

  private func downsample(_ data: [DokoWeather], maxPoints: Int) -> [DokoWeather] {
    var result: [DokoWeather]

    if data.count > maxPoints,
       let first = data.first,
       let last = data.last {
      let startTime = first.timestamp.timeIntervalSince1970
      let endTime = last.timestamp.timeIntervalSince1970
      let timeStep = (endTime - startTime) / Double(maxPoints - 1)

      result = (0..<maxPoints).map { i in
        let targetTime = startTime + Double(i) * timeStep
        return data.min { a, b in
          abs(a.timestamp.timeIntervalSince1970 - targetTime) < abs(b.timestamp.timeIntervalSince1970 - targetTime)
        } ?? first
      }
    } else {
      result = data
    }

    if result.count >= 2 {
      let last = result[result.count - 1]
      let secondToLast = result[result.count - 2]
      if last.timestamp.timeIntervalSince(secondToLast.timestamp) < 180 {
        result.remove(at: result.count - 2)
      }
    }

    return result
  }
}

public struct TripDetailWeatherView: View {
  @Bindable var model: TripDetailWeatherModel
  
  @Environment(\.dismiss) var dismiss
  
  public init(model: TripDetailWeatherModel) {
    self.model = model
  }
  
  public var body: some View {
    VStack {
      VStack {
        if let meanTemperature = model.meanTemperature {
          HStack {
            Text("Mean Temperature")
              .font(DesignTokens.Font.headline)
              .opacity(DesignTokens.Opacity.muted)
            Spacer()
            Text(meanTemperature.formatted(
              .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(0))
              )
            ))
            .font(DesignTokens.Font.headline)
            .bold()
          }
          .padding([.horizontal])
          .padding(.top, 8)
        }
        Chart {
          ForEach(model.weatherConditions) { weatherCondition in
            let temperature = Measurement(value: weatherCondition.temperature, unit: UnitTemperature.celsius)
              .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
            LineMark(
              x: .value("time", weatherCondition.timestamp),
              y: .value("temp", temperature.value)
            )
          }
          .foregroundStyle(.red)
          .interpolationMethod(.catmullRom)

          ForEach(model.downsampledWeatherConditions) { weatherCondition in
            let temperature = Measurement(value: weatherCondition.temperature, unit: UnitTemperature.celsius)
              .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
            PointMark(
              x: .value("time", weatherCondition.timestamp),
              y: .value("temp", temperature.value)
            )
            .symbol {
              ZStack {
                Circle()
                  .frame(width: 30, height: 30)
                  .foregroundColor(.orange)
                  .opacity(1)
                Image(systemName: weatherCondition.conditionSymbol)
                  .foregroundColor(Color(white: 0.2))
                  .frame(width: 25, height: 25)
              }
            }
          }
          .foregroundStyle(.red)
        }
        .chartXScale(domain: model.trip.timeStart...model.trip.timeEnd)
        .chartXAxis {
          AxisMarks(values: .automatic)
        }
        .chartYScale(domain: model.minimumTemperature.value...model.maximumTemperature.value)
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisValueLabel("\(value.as(Double.self)!.formatted())\(model.maximumTemperature.unit.symbol)")
            AxisGridLine()
            AxisTick()
          }
        }
        .frame(width: 320, height: 200)
      }
        
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Section {
            if !model.weatherConditions.isEmpty {
              ForEach(model.weatherConditions) { weatherCondition in
                VStack {
                  HStack {
                    let temperature = Measurement(value: weatherCondition.temperature, unit: UnitTemperature.celsius)
                      .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)

                    Text("\(weatherCondition.timestamp.formatted(date: .omitted, time: .shortened))")
                    Spacer()
                    Text(temperature
                      .formatted(
                        .measurement(
                          width: .abbreviated,
                          usage: .asProvided,
                          numberFormatStyle: .number.precision(.fractionLength(0))
                        )
                      )
                    )
                    Image(systemName: weatherCondition.conditionSymbol)
                  }

                  let windCompassDirection = weatherCondition.windCompassDirection
                  let windSpeed = Measurement(value: weatherCondition.windSpeed, unit: UnitSpeed.metersPerSecond)
                    .converted(to: model.appSettings.metric ? .kilometersPerHour : .milesPerHour)
                  let formattedWindSpeed = windSpeed.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
                  if let windGustMetric = weatherCondition.windGust {
                    let windGust = Measurement(value: windGustMetric, unit: UnitSpeed.metersPerSecond)
                      .converted(to: model.appSettings.metric ? .kilometersPerHour : .milesPerHour)
                    let formattedWindGust = windGust
                      .formatted(
                        .measurement(
                          width: .abbreviated,
                          usage: .asProvided,
                          numberFormatStyle: .number.precision(.fractionLength(0))
                        )
                      )
                    HStack {
                      Spacer()
                      Text(windCompassDirection + ", " + formattedWindSpeed + ", gusting to " + formattedWindGust)
                    }
                  } else {
                    HStack {
                      Spacer()
                      Text(windCompassDirection + ", " + formattedWindSpeed)
                    }
                  }
                }
              }
            } else {
              Text("There is no weather data to display.")
            }
          } header: {
            Text("Data Points")
          }
          .padding(.bottom, 20)

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
    }
    .navigationTitle(Text("Driving Conditions"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("Done") { dismiss() }
      }
    }
    .task {
      let weatherService = WeatherService()
      guard let weatherAttribution = try? await weatherService.attribution else { return }
      model.combinedMarkDarkURL = weatherAttribution.combinedMarkDarkURL
      model.legalPageURL = weatherAttribution.legalPageURL
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll var trips: [Trip]
  NavigationStack {
    TripDetailView(
      model: TripDetailModel(
        destination: .weatherChart,
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}

