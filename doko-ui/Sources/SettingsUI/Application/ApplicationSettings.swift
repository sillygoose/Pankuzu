import SwiftUI
import MapKit

import CommonUI
import DokoTypes
import DokoSharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var displayUnitsExpanded: Self {
    Self[.appStorage("ApplicationSettings-displayUnitsExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var mapStylesExpanded: Self {
    Self[.appStorage("ApplicationSettings-mapStylesExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var advancedExpanded: Self {
    Self[.appStorage("ApplicationSettings-advancedExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var debuggingExpanded: Self {
    Self[.appStorage("ApplicationSettings-debuggingExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var tripPositionExpanded: Self {
    Self[.appStorage("ApplicationSettings-tripPositionExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var tripElevationExpanded: Self {
    Self[.appStorage("ApplicationSettings-tripElevationExpanded"), default: false]
  }
}

struct MapStylePicker: View {
  @Binding var selection: DisplayMapStyle
  let pickerName: String

  var body: some View {
    Picker(
      pickerName,
      selection: $selection
    ) {
      ForEach(DisplayMapStyle.allCases) { mapStyle in
        Text(mapStyle.name)
          .fixedSize(horizontal: false, vertical: true)
          .tag(mapStyle)
      }
    }
  }
}

@MainActor
@Observable
class ApplicationSettingsModel {
  @ObservationIgnored @Shared(.metric) var metric
  @ObservationIgnored @Shared(.kWhPer100km) var kWhPer100km

  @ObservationIgnored @Shared(.tripMapStyle) var tripMapStyle
  @ObservationIgnored @Shared(.chargeMapStyle) var chargeMapStyle

  @ObservationIgnored @Shared(.poiThreshold) var poiThreshold
  @ObservationIgnored @Shared(.duplicateLocationThreshold) var duplicateLocationThreshold

  @ObservationIgnored @Shared(.tripMapPolyline) var tripMapPolyline
  @ObservationIgnored @Shared(.showElevationOnPath) var showElevationOnPath

  @ObservationIgnored @Shared(.identicalTripPositionDistance) var identicalTripPositionDistance
  @ObservationIgnored @Shared(.tripPositionCourseDeviation) var tripPositionCourseDeviation
  @ObservationIgnored @Shared(.maximumTripPositionDistance) var maximumTripPositionDistance

  @ObservationIgnored @Shared(.maximumTripElevationDistance) var maximumTripElevationDistance
  @ObservationIgnored @Shared(.minimumTripElevationChange) var minimumTripElevationChange

  func metricToggleChanged(isOn: Bool) {
    $metric.withLock { $0 = isOn }
  }

  func kWhPer100kmToggleChanged(isOn: Bool) {
    $kWhPer100km.withLock { $0 = isOn }
  }

  func setTripMapStyle(_ style: DisplayMapStyle) {
    $tripMapStyle.withLock { $0 = style }
  }

  func setChargeMapStyle(_ style: DisplayMapStyle) {
    $chargeMapStyle.withLock { $0 = style }
  }

  func setPoiThreshold(_ threshold: Double) {
    $poiThreshold.withLock { $0 = threshold }
  }

  func setDuplicateLocationThreshold(_ threshold: Double) {
    $duplicateLocationThreshold.withLock { $0 = threshold }
  }

  func setTripMapPolylineToggleChanged(isOn: Bool) {
    $tripMapPolyline.withLock { $0 = isOn }
  }

  func setShowElevationOnPathToggleChanged(isOn: Bool) {
    $showElevationOnPath.withLock { $0 = isOn }
  }

  func setIdenticalTripPositionDistance(_ distance: Double) {
    $identicalTripPositionDistance.withLock { $0 = distance }
  }

  func setPositionCourseDeviation(_ course: Double) {
    $tripPositionCourseDeviation.withLock { $0 = course }
  }

  func setMaximumTripPositionDistance(_ distance: Double) {
    $maximumTripPositionDistance.withLock { $0 = distance }
  }

  func setMaximumTripElevationDistance(_ distance: Double) {
    $maximumTripElevationDistance.withLock { $0 = distance }
  }

  func setMinimumTripElevationChange(_ elevation: Double) {
    $minimumTripElevationChange.withLock { $0 = elevation }
  }
}

struct ApplicationSettingsView: View {
  @Bindable var model: ApplicationSettingsModel

  let PoiThresholdSliderRangeMetric = 30.0...100.0
  let PoiThresholdSliderRange = 100.0...300.0
  let PoiThresholdSliderStepMetric = 10.0
  let PoiThresholdSliderStep = 30.0

  let DuplicateLocationThresholdSliderRangeMetric = 10.0...50.0
  let DuplicateLocationThresholdSliderRange = 30.0...150.0
  let DuplicateLocationThresholdSliderStepMetric = 5.0
  let DuplicateLocationThresholdSliderStep = 15.0

  @Shared(.displayUnitsExpanded) var displayUnitsExpanded
  @Shared(.mapStylesExpanded) var mapStylesExpanded
  @Shared(.advancedExpanded) var advancedExpanded
  @Shared(.debuggingExpanded) var debuggingExpanded
  @Shared(.tripPositionExpanded) var tripPositionExpanded
  @Shared(.tripElevationExpanded) var tripElevationExpanded

  var body: some View {
    List {
      DisclosureGroup(
        isExpanded: Binding(
          get: { displayUnitsExpanded },
          set: { newValue in $displayUnitsExpanded.withLock { $0 = newValue } }
        )
      ) {
        Toggle(
          "Metric",
          isOn: Binding(
            get: { model.metric },
            set: { isOn, _ in model.metricToggleChanged(isOn: isOn) }
          )
        )
        if model.metric {
          Toggle(
            "kWh Per 100km",
            isOn: Binding(
              get: { model.kWhPer100km },
              set: { isOn, _ in model.kWhPer100kmToggleChanged(isOn: isOn) }
            )
          )
        }
      } label: {
        Text("Display Units")
      }

      DisclosureGroup(
        isExpanded: Binding(
          get: { mapStylesExpanded },
          set: { newValue in $mapStylesExpanded.withLock { $0 = newValue } }
        )
      ) {
        MapStylePicker(
          selection: Binding(
            get: { model.tripMapStyle },
            set: { model.setTripMapStyle($0) }
          ),
          pickerName: "Trip Map Style"
        )
        MapStylePicker(
          selection: Binding(
            get: { model.chargeMapStyle },
            set: { model.setChargeMapStyle($0) }
          ),
          pickerName: "Charge Map Style"
        )
      } label: {
        Text("Map Styling")
      }

      DisclosureGroup(
        isExpanded: Binding(
          get: { advancedExpanded },
          set: { newValue in $advancedExpanded.withLock { $0 = newValue } }
        )
      ) {
        Section {
          HStack {
            let sliderRange = model.metric ? PoiThresholdSliderRangeMetric : PoiThresholdSliderRange
            let sliderStep = model.metric ? PoiThresholdSliderStepMetric : PoiThresholdSliderStep
            Slider(
              value: Binding(
                get: { return model.metric ? model.poiThreshold : model.poiThreshold * 3 },
                set: { model.setPoiThreshold(model.metric ? $0 : $0 / 3) }
              ),
              in: sliderRange,
              step: sliderStep
            )
            Spacer()
            let poiThreshold = Measurement(
              value: model.metric ? model.poiThreshold : model.poiThreshold * 3,
              unit: model.metric ? UnitLength.meters : UnitLength.feet
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
          Text(
            "Threshold used to find nearby Points of Interest."
          )
          .font(.caption)
          .opacity(DesignTokens.Opacity.muted)
        }

        Section {
          HStack {
            let sliderRange = model.metric ? DuplicateLocationThresholdSliderRangeMetric : DuplicateLocationThresholdSliderRange
            let sliderStep = model.metric ? DuplicateLocationThresholdSliderStepMetric : DuplicateLocationThresholdSliderStep
            Slider(
              value: Binding(
                get: { return model.metric ? model.duplicateLocationThreshold : model.duplicateLocationThreshold * 3 },
                set: { model.setDuplicateLocationThreshold(model.metric ? $0 : $0 / 3) }
              ),
              in: sliderRange,
              step: sliderStep
            )
            Spacer()
            let duplicateLocationThreshold = Measurement(
              value: model.metric ? model.duplicateLocationThreshold : model.duplicateLocationThreshold * 3,
              unit: model.metric ? UnitLength.meters : UnitLength.feet
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
          Text(
            "Threshold used to determine when two locations are the same."
          )
          .font(.caption)
          .opacity(DesignTokens.Opacity.muted)
        }
      } label: {
        Text("Advanced")
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
            get: { model.tripMapPolyline },
            set: { isOn, _ in model.setTripMapPolylineToggleChanged(isOn: isOn) }
          )
        )

        Toggle(
          "Show elevation data on trip path",
          isOn: Binding(
            get: { model.showElevationOnPath },
            set: { isOn, _ in model.setShowElevationOnPathToggleChanged(isOn: isOn) }
          )
        )

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
                  get: { return model.identicalTripPositionDistance },
                  set: { model.setIdenticalTripPositionDistance($0) }
                ),
                in: identicalTripPositionDistanceRange,
                step: identicalTripPositionDistanceStep
              )
              Spacer()
              let identicalTripPositionDistance = Measurement(
                value: model.identicalTripPositionDistance,
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
                  get: { return model.tripPositionCourseDeviation },
                  set: { model.setPositionCourseDeviation($0) }
                ),
                in: positionCourseDeviationRange,
                step: positionCourseDeviationStep
              )
              Spacer()
              let positionCourseDeviation = Measurement(
                value: model.tripPositionCourseDeviation,
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
                  get: { return model.maximumTripPositionDistance },
                  set: { model.setMaximumTripPositionDistance($0) }
                ),
                in: maximumTripPositionDistanceRange,
                step: maximumTripPositionDistanceStep
              )
              Spacer()
              let maximumTripPoitionDistance = Measurement(
                value: model.maximumTripPositionDistance,
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
                  get: { return model.maximumTripElevationDistance },
                  set: { model.setMaximumTripElevationDistance($0) }
                ),
                in: maximumTripElevationDistanceRange,
                step: maximumTripElevationDistanceStep
              )
              Spacer()
              let maximumTripElevaionDistance = Measurement(
                value: model.maximumTripElevationDistance,
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
                  get: { return model.minimumTripElevationChange },
                  set: { model.setMinimumTripElevationChange($0) }
                ),
                in: minimumTripElevaionChangeRange,
                step: minimumTripElevationChangeStep
              )
              Spacer()
              let minimumTripElevationChange = Measurement(
                value: model.minimumTripElevationChange,
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
    .navigationTitle("Application")
  }
}

#Preview {
  NavigationStack {
    ApplicationSettingsView(
      model: ApplicationSettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
