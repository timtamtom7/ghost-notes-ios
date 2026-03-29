import SwiftUI

@main
struct GhostNotesMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacContentView()
                .preferredColorScheme(.dark)
        }
    }
}
