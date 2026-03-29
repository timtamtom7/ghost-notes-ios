import SwiftUI

struct MacArticleListView: View {
    @Bindable var viewModel: MacLibraryViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.macTextTertiary)
                    .font(.caption)
                TextField("Search articles...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(.macTextPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusSmall)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .background(Color.macSeparator)

            // Column header
            HStack {
                Text(articleCountLabel)
                    .font(.caption)
                    .foregroundColor(.macTextSecondary)
                Spacer()
                Text(filterLabel)
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Divider()
                .background(Color.macSeparator)

            // Article cards
            ScrollView {
                if viewModel.filteredArticles.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredArticles) { article in
                            articleCard(article)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(Color.macBackground)
    }

    private var articleCountLabel: String {
        let count = viewModel.filteredArticles.count
        return count == 1 ? "1 article" : "\(count) articles"
    }

    private var filterLabel: String {
        viewModel.selectedFilter.rawValue
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: viewModel.searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.macGhost)
            Text(viewModel.searchText.isEmpty ? "No articles yet" : "No results")
                .font(.subheadline)
                .foregroundColor(.macTextSecondary)
            if viewModel.searchText.isEmpty {
                Text("Save your first article to get started")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func articleCard(_ article: Article) -> some View {
        let isSelected = viewModel.selectedArticle?.id == article.id
        return HStack(spacing: 12) {
            // Unread indicator
            Circle()
                .fill(article.isRead ? Color.clear : Color.macPrimary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 5) {
                Text(article.domain)
                    .font(.caption2)
                    .foregroundColor(.macTextSecondary)

                Text(article.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.macTextPrimary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Label("\(article.readingTimeMinutes) min", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.macTextTertiary)

                    if article.readingProgress > 0 && article.readingProgress < 1 {
                        Text("•")
                            .foregroundColor(.macTextTertiary)
                        Text("\(Int(article.readingProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.macPrimary)
                    }

                    if !article.bodyContent.isEmpty {
                        Text("•")
                            .foregroundColor(.macTextTertiary)
                        Text("Saved")
                            .font(.caption2)
                            .foregroundColor(.macTextSecondary)
                    }
                }
            }

            Spacer()

            // Swipe actions indicator
            VStack(spacing: 4) {
                Image(systemName: "ellipsis")
                    .font(.caption2)
                    .foregroundColor(.macGhost)
            }
        }
        .padding(12)
        .background(isSelected ? Color.macSurfaceElevated : Color.macSurface)
        .cornerRadius(MacTheme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: MacTheme.cornerRadiusMedium)
                .stroke(isSelected ? Color.macPrimary.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectArticle(article)
        }
        .contextMenu {
            if !article.isRead {
                Button("Mark as Read") {
                    Task { await viewModel.markAsRead(article) }
                }
            } else {
                Button("Mark as Unread") {
                    Task { await viewModel.markAsUnread(article) }
                }
            }

            if !article.isArchived {
                Button("Archive") {
                    Task { await viewModel.archiveArticle(article) }
                }
            } else {
                Button("Restore") {
                    Task { await viewModel.unarchiveArticle(article) }
                }
            }

            Divider()

            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteArticle(article) }
            }
        }
    }
}

#Preview {
    MacArticleListView(viewModel: MacLibraryViewModel())
        .frame(width: 320, height: 600)
}
