import SwiftUI

@main
struct GhostNotesApp: App {
    @StateObject private var articleStore = ArticleStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(articleStore)
                .preferredColorScheme(.dark)
        }
    }
}
