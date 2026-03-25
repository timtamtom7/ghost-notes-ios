import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var articleStore: ArticleStore
    @State private var showingClearConfirmation = false
    @State private var articleCount = 0
    @State private var storageUsed = "Calculating..."

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Section {
                    HStack {
                        Label("Articles Saved", systemImage: "doc.text")
                        Spacer()
                        Text("\(articleStore.articles.count)")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("Storage")
                        .foregroundColor(Theme.textTertiary)
                }

                Section {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear All Articles", systemImage: "trash")
                            .foregroundColor(Theme.destructive)
                    }
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("Data")
                        .foregroundColor(Theme.textTertiary)
                }

                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surface)

                    Link(destination: URL(string: "https://github.com/timtamtom7/ghost-notes-ios")!) {
                        Label("View on GitHub", systemImage: "link")
                    }
                    .listRowBackground(Theme.surface)
                } header: {
                    Text("About")
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Settings")
        .alert("Clear All Articles", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                clearAllArticles()
            }
        } message: {
            Text("This will permanently delete all saved articles. This cannot be undone.")
        }
    }

    private func clearAllArticles() {
        let articlesCopy = articleStore.articles
        for article in articlesCopy {
            articleStore.deleteArticle(article)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(ArticleStore())
    }
}
