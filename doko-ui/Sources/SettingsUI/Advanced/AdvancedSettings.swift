import SwiftUI

import CommonUI
import DokoTypes
import DokoSharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var advancedExpanded: Self {
    Self[.appStorage("AdvancedSettings-advancedExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var debuggingExpanded: Self {
    Self[.appStorage("AdvancedSettings-debuggingExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var tripPositionExpanded: Self {
    Self[.appStorage("AdvancedSettings-tripPositionExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var tripElevationExpanded: Self {
    Self[.appStorage("AdvancedSettings-tripElevationExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var tripSettingsExpanded: Self {
    Self[.appStorage("AdvancedSettings-tripSettingsExpanded"), default: false]
  }
}

@MainActor
@Observable
class AdvancedSettingsModel {
  @ObservationIgnored @Shared(.appSettings) var appSettings

  func setPoiThreshold(_ threshold: Double) {
    $appSettings.poiThreshold.withLock { $0 = threshold }
  }

  func setDuplicateLocationThreshold(_ threshold: Double) {
    $appSettings.duplicateLocationThreshold.withLock { $0 = threshold }
  }

  func setTripMapPolylineToggleChanged(isOn: Bool) {
    $appSettings.tripMapPolyline.withLock { $0 = isOn }
  }

  func setShowElevationOnPathToggleChanged(isOn: Bool) {
    $appSettings.showElevationOnPath.withLock { $0 = isOn }
  }

  func setIdenticalTripPositionDistance(_ distance: Double) {
    $appSettings.identicalTripPositionDistance.withLock { $0 = distance }
  }

  func setPositionCourseDeviation(_ course: Double) {
    $appSettings.tripPositionCourseDeviation.withLock { $0 = course }
  }

  func setMaximumTripPositionDistance(_ distance: Double) {
    $appSettings.maximumTripPositionDistance.withLock { $0 = distance }
  }

  func setMaximumTripElevationDistance(_ distance: Double) {
    $appSettings.maximumTripElevationDistance.withLock { $0 = distance }
  }

  func setMinimumTripElevationChange(_ elevation: Double) {
    $appSettings.minimumTripElevationChange.withLock { $0 = elevation }
  }

  func setDeletedRecordRetentionDays(_ days: Int) {
    $appSettings.deletedRecordRetentionDays.withLock { $0 = days }
  }

  func setTripEfficiencyAverageDuration(_ duration: Int) {
    $appSettings.tripEfficiencyAverageDuration.withLock { $0 = duration }
  }
}


@MainActor
struct AdvancedSettingsView: View {
  @State private var model = AdvancedSettingsModel()

  @Shared(.advancedExpanded) var advancedExpanded
  @Shared(.debuggingExpanded) var debuggingExpanded
  @Shared(.tripPositionExpanded) var tripPositionExpanded
  @Shared(.tripElevationExpanded) var tripElevationExpanded
  @Shared(.tripSettingsExpanded) var tripSettingsExpanded

  let PoiThresholdSliderRangeMetric = 30.0...100.0
  let PoiThresholdSliderRange = 100.0...300.0
  let PoiThresholdSliderStepMetric = 10.0
  let PoiThresholdSliderStep = 30.0

  let DuplicateLocationThresholdSliderRangeMetric = 10.0...50.0
  let DuplicateLocationThresholdSliderRange = 30.0...150.0
  let DuplicateLocationThresholdSliderStepMetric = 5.0
  let DuplicateLocationThresholdSliderStep = 15.0

  var body: some View {
    List {
      DisclosureGroup(
        isExpanded: Binding(
          get: { advancedExpanded },
          set: { newValue in $advancedExpanded.withLock { $0 = newValue } }
        )
      ) {
        Section {
          HStack {
            let sliderRange = model.appSettings.metric ? PoiThresholdSliderRangeMetric : PoiThresholdSliderRange
            let sliderStep = model.appSettings.metric ? PoiThresholdSliderStepMetric : PoiThresholdSliderStep
            Slider(
              value: Binding(
                get: { model.appSettings.metric ? model.appSettings.poiThreshold : model.appSettings.poiThreshold * 3 },
                set: { model.setPoiThreshold(model.appSettings.metric ? $0 : $0 / 3) }
              ),
              in: sliderRange,
              step: sliderStep
            )
            Spacer()
            let poiThreshold = Measurement(
              value: model.appSettings.metric ? model.appSettings.poiThreshold : model.appSettings.poiThreshold * 3,
              unit: model.appSettings.metric ? UnitLength.meters : UnitLength.feet
            )
            Text(
              poiThreshold.formatted(
                .measurement(
                  width: .abbreviated,
                  usage: .asProvided,
                  numberFormatStyle: .number.rounded(rule: .towardZero, increment: sliderStep)
                )
              )
            )
          }
        } header: {
          Text("POI Threshold")
        } footer: {
          Text("Threshold used to find nearby Points of Interest.")
            .font(.caption)
            .opacity(DesignTokens.Opacity.muted)
        }

        Section {
          HStack {
            let sliderRange = model.appSettings.metric ? DuplicateLocationThresholdSliderRangeMetric : DuplicateLocationThresholdSliderRange
            let sliderStep = model.appSettings.metric ? DuplicateLocationThresholdSliderStepMetric : DuplicateLocationThresholdSliderStep
            Slider(
              value: Binding(
                get: { model.appSettings.metric ? model.appSettings.duplicateLocationThreshold : model.appSettings.duplicateLocationThreshold * 3 },
                set: { model.setDuplicateLocationThreshold(model.appSettings.metric ? $0 : $0 / 3) }
              ),
              in: sliderRange,
              step: sliderStep
            )
            Spacer()
            let duplicateLocationThreshold = Measurement(
              value: model.appSettings.metric ? model.appSettings.duplicateLocationThreshold : model.appSettings.duplicateLocationThreshold * 3,
              unit: model.appSettings.metric ? UnitLength.meters : UnitLength.feet
            )
            Text(
              duplicateLocationThreshold.formatted(
                .measurement(
                  width: .abbreviated,
                  usage: .asProvided,
                  numberFormatStyle: .number.rounded(rule: .towardZero, increment: sliderStep)
                )
              )
            )
          }
        } header: {
          Text("Duplicate Location Threshold")
        } footer: {
          Text("Threshold used to determine when two locations are the same.")
            .font(.caption)
            .opacity(DesignTokens.Opacity.muted)
        }
      } label: {
        Text("Thresholds")
      }

      DisclosureGroup(
        isExpanded: Binding(
          get: { tripSettingsExpanded },
          set: { newValue in $tripSettingsExpanded.withLock { $0 = newValue } }
        )
      ) {
        Picker(
          "Efficiency Average Duration",
          selection: Binding(
            get: { model.appSettings.tripEfficiencyAverageDuration },
            set: { model.setTripEfficiencyAverageDuration($0) }
          )
        ) {
          Text("5 min").tag(5)
          Text("10 min").tag(10)
          Text("15 min").tag(15)
        }
      } label: {
        Text("Trip Settings")
      }

#if DEBUG
      DisclosureGroup(
        isExpanded: Binding(
          get: { debuggingExpanded },
          set: { newValue in $debuggingExpanded.withLock { $0 = newValue } }
        )
      ) {
        Toggle(
          "Use polylines for path segments",
          isOn: Binding(
            get: { model.appSettings.tripMapPolyline },
            set: { isOn, _ in model.setTripMapPolylineToggleChanged(isOn: isOn) }
          )
        )

        Toggle(
          "Show elevation data on trip path",
          isOn: Binding(
            get: { model.appSettings.showElevationOnPath },
            set: { isOn, _ in model.setShowElevationOnPathToggleChanged(isOn: isOn) }
          )
        )

        Section {
          HStack {
            Slider(
              value: Binding(
                get: { Double(model.appSettings.deletedRecordRetentionDays) },
                set: { model.setDeletedRecordRetentionDays(Int($0)) }
              ),
              in: 1.0...30.0,
              step: 1.0
            )
            Spacer()
            Text("\(model.appSettings.deletedRecordRetentionDays) days")
          }
        } header: {
          Text("Keep Deleted Trip/Charge For")
        }

        DisclosureGroup(
          isExpanded: Binding(
            get: { tripPositionExpanded },
            set: { newValue in $tripPositionExpanded.withLock { $0 = newValue } }
          )
        ) {
          Section {
            HStack {
              let identicalTripPositionDistanceRange = 1.0...15.0
              let identicalTripPositionDistanceStep = 1.0
              Slider(
                value: Binding(
                  get: { return model.appSettings.identicalTripPositionDistance },
                  set: { model.setIdenticalTripPositionDistance($0) }
                ),
                in: identicalTripPositionDistanceRange,
                step: identicalTripPositionDistanceStep
              )
              Spacer()
              let identicalTripPositionDistance = Measurement(
                value: model.appSettings.identicalTripPositionDistance,
                unit: UnitLength.meters
              )
              Text(
                identicalTripPositionDistance.formatted(
                  .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.rounded(rule: .towardZero, increment: identicalTripPositionDistanceStep)
                  )
                )
              )
            }
          } header: {
            Text("Identical Trip Position Threshold")
          } footer: {
            Text(
              "Threshold used to determine if two trip positions are considered the same."
            )
            .font(.caption)
            .opacity(DesignTokens.Opacity.muted)
          }

          Section {
            HStack {
              let positionCourseDeviationRange = 0.1...5.0
              let positionCourseDeviationStep = 0.1
              Slider(
                value: Binding(
                  get: { return model.appSettings.tripPositionCourseDeviation },
                  set: { model.setPositionCourseDeviation($0) }
                ),
                in: positionCourseDeviationRange,
                step: positionCourseDeviationStep
              )
              Spacer()
              let positionCourseDeviation = Measurement(
                value: model.appSettings.tripPositionCourseDeviation,
                unit: UnitAngle.degrees
              )
              Text(
                positionCourseDeviation.formatted(
                  .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.rounded(rule: .towardZero, increment: positionCourseDeviationStep)
                  )
                )
              )
            }
          } header: {
            Text("Course Deviation Threshold")
          } footer: {
            Text(
              "Output a position when the course deviates by the threshold from the last recorded position."
            )
            .font(.caption)
            .opacity(DesignTokens.Opacity.muted)
          }

          Section {
            HStack {
              let maximumTripPositionDistanceRange = 100.0...400.0
              let maximumTripPositionDistanceStep = 20.0
              Slider(
                value: Binding(
                  get: { return model.appSettings.maximumTripPositionDistance },
                  set: { model.setMaximumTripPositionDistance($0) }
                ),
                in: maximumTripPositionDistanceRange,
                step: maximumTripPositionDistanceStep
              )
              Spacer()
              let maximumTripPoitionDistance = Measurement(
                value: model.appSettings.maximumTripPositionDistance,
                unit: UnitLength.meters
              )
              Text(
                maximumTripPoitionDistance.formatted(
                  .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.rounded(rule: .towardZero, increment: maximumTripPositionDistanceStep)
                  )
                )
              )
            }
          } header: {
            Text("Maximum Output Position Threshold")
          } footer: {
            Text(
              "Output a position record when the threshold from the previous record is exceeded."
            )
            .font(.caption)
            .opacity(DesignTokens.Opacity.muted)
          }
        } label: {
          Text("Trip Position")
        }

        DisclosureGroup(
          isExpanded: Binding(
            get: { tripElevationExpanded },
            set: { newValue in $tripElevationExpanded.withLock { $0 = newValue } }
          )
        ) {
          Section {
            HStack {
              let maximumTripElevationDistanceRange = 20.0...200.0
              let maximumTripElevationDistanceStep = 20.0
              Slider(
                value: Binding(
                  get: { return model.appSettings.maximumTripElevationDistance },
                  set: { model.setMaximumTripElevationDistance($0) }
                ),
                in: maximumTripElevationDistanceRange,
                step: maximumTripElevationDistanceStep
              )
              Spacer()
              let maximumTripElevaionDistance = Measurement(
                value: model.appSettings.maximumTripElevationDistance,
                unit: UnitLength.meters
              )
              Text(
                maximumTripElevaionDistance.formatted(
                  .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.rounded(rule: .towardZero, increment: maximumTripElevationDistanceStep)
                  )
                )
              )
            }
          } header: {
            Text("Trip Elevation Threshold")
          } footer: {
            Text(
              "Threshold used to determine the maximum distance between two trip elevations."
            )
            .font(.caption)
            .opacity(DesignTokens.Opacity.muted)
          }

          Section {
            HStack {
              let minimumTripElevaionChangeRange = 1.0...10.0
              let minimumTripElevationChangeStep = 0.5
              Slider(
                value: Binding(
                  get: { return model.appSettings.minimumTripElevationChange },
                  set: { model.setMinimumTripElevationChange($0) }
                ),
                in: minimumTripElevaionChangeRange,
                step: minimumTripElevationChangeStep
              )
              Spacer()
              let minimumTripElevationChange = Measurement(
                value: model.appSettings.minimumTripElevationChange,
                unit: UnitLength.meters
              )
              Text(
                minimumTripElevationChange.formatted(
                  .measurement(
                    width: .abbreviated,
                    usage: .asProvided,
                    numberFormatStyle: .number.rounded(rule: .towardZero, increment: minimumTripElevationChangeStep)
                  )
                )
              )
            }
          } header: {
            Text("Trip Elevation Change Threshold")
          } footer: {
            Text(
              "Threshold used to determine the minimum chsnge in elevation for output."
            )
            .font(.caption)
            .opacity(DesignTokens.Opacity.muted)
          }
        } label: {
          Text("Trip Elevation")
        }
      } label: {
        Text("Debugging")
      }
#endif
    }
    .listStyle(.plain)
    .navigationTitle("Advanced")
  }
}

#Preview {
  NavigationStack {
    AdvancedSettingsView()
    .preferredColorScheme(.dark)
  }
}
