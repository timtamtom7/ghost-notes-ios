import SwiftUI

struct ArchiveView: View {
    @Bindable var viewModel: LibraryViewModel
    @State private var selectedArticle: Article?

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.archivedArticles.isEmpty {
                ProgressView()
                    .tint(.primary)
            } else if viewModel.archivedArticles.isEmpty {
                emptyState
            } else {
                archivedList
            }
        }
        .navigationTitle("Archive")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedArticle) { article in
            ReadingView(article: article)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 56))
                .foregroundColor(.ghost)

            Text("Archive is empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Articles you've finished reading\nwill appear here.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var archivedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.archivedArticles) { article in
                    ArticleCard(article: article)
                        .onTapGesture {
                            Theme.haptic(.light)
                            selectedArticle = article
                        }
                        .contextMenu {
                            Button {
                                Theme.haptic(.success)
                                Task { await viewModel.unarchiveArticle(article) }
                            } label: {
                                Label("Restore to Library", systemImage: "arrow.uturn.backward")
                            }

                            Button {
                                Theme.haptic(.light)
                                Task { await viewModel.markAsUnread(article) }
                            } label: {
                                Label("Mark as unread", systemImage: "circle")
                            }

                            Divider()

                            Button(role: .destructive) {
                                Theme.haptic(.warning)
                                Task { await viewModel.deleteArticle(article) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            await viewModel.load()
        }
    }
}

#Preview {
    NavigationStack {
        ArchiveView(viewModel: LibraryViewModel())
    }
}
