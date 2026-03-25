import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(0)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(1)
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(ArticleStore())
}
