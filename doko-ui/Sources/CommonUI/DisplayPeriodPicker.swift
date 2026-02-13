import Foundation
import SwiftUI

public enum DisplayPeriod: Codable, Hashable, Identifiable, Sendable {
  case today, pastWeek, pastMonth, custom(Date?, Date?)

  public var id: String { name }

  public var name: String {
    switch self {
    case .today: return "Today"
    case .pastWeek: return "Past Week"
    case .pastMonth: return "Past Month"
    case .custom: return "Custom"
    }
  }

  public var dateRange: (Date?, Date?) {
    let startOfToday = Calendar.current.startOfDay(for: Date.now)
    let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
    switch self {
    case .today:
      return (startOfToday, endOfToday)
    case .pastWeek:
      let startOfPastWeek = Calendar.current.date(byAdding: .day, value: -7, to: startOfToday)!
      return (startOfPastWeek, endOfToday)
    case .pastMonth:
      let startOfPastMonth = Calendar.current.date(byAdding: .day, value: -30, to: startOfToday)!
      return (startOfPastMonth, endOfToday)
    case let .custom(start, end):
      return (start, end)
    }
  }
}

extension DisplayPeriod {
  public static let defaultDisplayPeriod: DisplayPeriod = .today
  public static let defaultCustomDisplayPeriod: DisplayPeriod = .custom(nil, nil)
}

public struct DisplayPeriodPicker: View {
  @Binding var datePicker: DisplayPeriod
  let pickerName: String
  let customDisplayPeriod: DisplayPeriod

  public init(
    datePicker: Binding<DisplayPeriod>,
    pickerName: String,
    customDisplayPeriod: DisplayPeriod
  ) {
    self._datePicker = datePicker
    self.pickerName = pickerName
    self.customDisplayPeriod = customDisplayPeriod
  }

  @Environment(\.calendar) var calendar

  @State var multiDatePicker: Set<DateComponents> = []
  @State private var dates: Set<DateComponents> = []
  let datePickerComponents: Set<Calendar.Component> = [.calendar, .era, .year, .month, .day]

  var datesBinding: Binding<Set<DateComponents>> {
    Binding {
      dates
    } set: { newValue in
      if newValue.isEmpty {
        dates = newValue
      } else if newValue.count > dates.count {
        if newValue.count == 1 {
          dates = newValue
        } else if newValue.count == 2 {
          dates = filledRange(selectedDates: newValue)
        } else if let firstMissingDate = newValue.subtracting(dates).first {
          dates = [firstMissingDate]
        } else {
          dates = []
        }
      } else if let firstMissingDate = dates.subtracting(newValue).first {
        dates = [firstMissingDate]
      } else {
        dates = []
      }
      multiDatePicker = dates

      let dateMap = dates.compactMap { calendar.date(from: $0) }
      if let startOfPeriod = dateMap.min(), let endOfPeriod = dateMap.max() {
        let trueEndOfPeriod = Calendar.current.date(byAdding: .day, value: 1, to: endOfPeriod)!
        datePicker = .custom(startOfPeriod, trueEndOfPeriod)
      }
      else {
        dates = []
        multiDatePicker = dates
        datePicker = .custom(nil, nil)
      }
    }
  }

  var bounds: Range<Date> {
    let start = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!
    return start..<Date.now
  }

  public var body: some View {
    VStack {
      Picker(
        pickerName,
        selection: $datePicker
      ) {
        let custom: DisplayPeriod = {
          if case let .custom(start, end) = datePicker {
            return .custom(start, end)
          }
          return customDisplayPeriod
        }()
        ForEach([DisplayPeriod.today, .pastWeek, .pastMonth, custom], id: \.self) { displayPeriod in
          Text(displayPeriod.name)
            .fixedSize(horizontal: false, vertical: true)
            .tag(displayPeriod)
        }
      }
      .pickerStyle(.segmented)

      if case .custom(_, _) = datePicker {
        DisclosureGroup {
          MultiDatePicker(
            "Select dates",
            selection: datesBinding,
            in: bounds
          )
          .padding([.bottom], -DesignTokens.Padding.pickerSpacing)
        } label: {
          let dateMap = dates.compactMap { calendar.date(from: $0) }
          if let startOfPeriod = dateMap.min(), let endOfPeriod = dateMap.max() {
            let startPeriodString = String("\(startOfPeriod.formatted(date: .numeric, time: .omitted))")
            let endPeriodString = String("\(endOfPeriod.formatted(date: .numeric, time: .omitted))")
            Label("\(startPeriodString) thru \(endPeriodString)", systemImage: "calendar")
          } else {
            Label("No dates selected", systemImage: "calendar")
          }
        }
        .padding([.top], DesignTokens.Padding.pickerSpacing)
      }
    }
    .onAppear{
      if case let .custom(start, end) = datePicker {
        setDates(start, end)
      }
    }
    .onChange(of: datePicker) {
      if case let .custom(start, end) = datePicker {
        setDates(start, end)
      }
    }
  }

  private func setDates(_ startOfPeriod: Date?, _ endOfPeriod: Date?) {
    var startOfPeriodComponents: DateComponents = DateComponents()
    var endOfPeriodComponents: DateComponents = DateComponents()
    if let startDate = startOfPeriod {
      startOfPeriodComponents = Calendar.current.dateComponents(datePickerComponents, from: startDate)
    }
    if let endDate = endOfPeriod {
      let trueEndOfPeriod = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
      endOfPeriodComponents = Calendar.current.dateComponents(datePickerComponents, from: trueEndOfPeriod)
    }
    if startOfPeriodComponents == DateComponents() && endOfPeriodComponents == DateComponents() {
      dates = []
    } else {
      dates = filledRange(selectedDates: [startOfPeriodComponents, endOfPeriodComponents])
    }
  }

  private func filledRange(selectedDates: Set<DateComponents>) -> Set<DateComponents> {
    let allDates = selectedDates.compactMap { calendar.date(from: $0) }
    let sortedDates = allDates.sorted()
    var datesToAdd = [DateComponents]()
    if let first = sortedDates.first, let last = sortedDates.last {
      var date = first
      while date < last {
        if let nextDate = calendar.date(byAdding: .day, value: 1, to: date) {
          if !sortedDates.contains(nextDate) {
            let dateComponents = calendar.dateComponents(datePickerComponents,from: nextDate)
            datesToAdd.append(dateComponents)
          }
          date = nextDate
        } else {
          break
        }
      }
    }
    return selectedDates.union(datesToAdd)
  }
}

#Preview("DisplayPeriodPicker") {
  struct PreviewHost: View {
    @State private var displayPeriod: DisplayPeriod = .defaultDisplayPeriod
    private let customDisplayPeriod: DisplayPeriod = .defaultCustomDisplayPeriod

    var body: some View {
      NavigationStack {
        List {
          DisplayPeriodPicker(
            datePicker: $displayPeriod,
            pickerName: "Display Period",
            customDisplayPeriod: customDisplayPeriod
          )

          let (start, end) = displayPeriod.dateRange
          if let start = start, let end = end {
            let startPeriodString = String("\(start.formatted(date: .numeric, time: .omitted))")
            let endPeriodString = String("\(end.formatted(date: .numeric, time: .omitted))")
            Text("\(startPeriodString), \(endPeriodString)")
          } else {
            Text("nil, nil")
          }
        }
      }
    }
  }
  return PreviewHost()
    .preferredColorScheme(.dark)
}
