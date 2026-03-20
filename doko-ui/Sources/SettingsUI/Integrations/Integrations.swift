import SwiftUI

struct IntegrationsView: View {
  var body: some View {
    List {
    }
    .listStyle(.plain)
    .navigationTitle("Integrations")
  }
}

#Preview {
  NavigationStack {
    IntegrationsView()
      .preferredColorScheme(.dark)
  }
}
