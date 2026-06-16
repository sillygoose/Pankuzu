//###import SwiftUI
//import WidgetKit
//
//import DokoLiveActivityManager
//import DokoSharing
//
//struct PankuzuWidgetEntry: TimelineEntry {
//  let date: Date
//  let activeSession: ActiveSession?
//}
//
//struct PankuzuWidgetProvider: TimelineProvider {
//  func placeholder(in context: Context) -> PankuzuWidgetEntry {
//    PankuzuWidgetEntry(date: .now, activeSession: nil)
//  }
//
//  func getSnapshot(in context: Context, completion: @escaping (PankuzuWidgetEntry) -> Void) {
//    completion(makeEntry())
//  }
//
//  func getTimeline(in context: Context, completion: @escaping (Timeline<PankuzuWidgetEntry>) -> Void) {
//    completion(Timeline(entries: [makeEntry()], policy: .never))
//  }
//
//  private func makeEntry() -> PankuzuWidgetEntry {
//    @Shared(.widgetSession) var widgetSession
//    return PankuzuWidgetEntry(date: .now, activeSession: ActiveSession(rawValue: widgetSession))
//  }
//}
//
//struct PankuzuWidgetView: View {
//  let entry: PankuzuWidgetEntry
//
//  var body: some View {
//    VStack(spacing: 8) {
//      DokoWidgetIcon(height: 44)
//      Image(systemName: entry.activeSession?.symbol ?? "square.fill")
//        .font(.title2)
//        .foregroundStyle(entry.activeSession != nil ? Color.red : Color.clear)
//    }
//    .frame(maxWidth: .infinity, maxHeight: .infinity)
//    .containerBackground(for: .widget) {
//      Color.clear
//    }
//  }
//}
//
//struct PankuzuWidget: Widget {
//  let kind = "PankuzuWidget"
//
//  var body: some WidgetConfiguration {
//    StaticConfiguration(kind: kind, provider: PankuzuWidgetProvider()) { entry in
//      PankuzuWidgetView(entry: entry)
//    }
//    .configurationDisplayName("Pankuzu")
//    .description("EV trip and charge monitor.")
//    .supportedFamilies([.systemSmall])
//  }
//}
//
//#Preview(as: .systemSmall) {
//  PankuzuWidget()
//} timeline: {
//  PankuzuWidgetEntry(date: .now, activeSession: nil)
//  PankuzuWidgetEntry(date: .now, activeSession: .trip)
//  PankuzuWidgetEntry(date: .now, activeSession: .acCharge)
//  PankuzuWidgetEntry(date: .now, activeSession: .dcCharge)
//}
