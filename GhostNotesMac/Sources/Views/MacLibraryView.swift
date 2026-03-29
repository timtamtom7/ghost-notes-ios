import SwiftUI

struct MacLibraryView: View {
    @Bindable var viewModel: MacLibraryViewModel
    @Binding var showingAddURL: Bool
    @Binding var urlToAdd: String

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ghost Notes")
                        .font(.headline)
                        .foregroundColor(.macTextPrimary)
                    Text("\(viewModel.unreadCount) unread")
                        .font(.caption)
                        .foregroundColor(.macTextSecondary)
                }
                Spacer()
                Button {
                    showingAddURL = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.macPrimary)
                        .frame(width: 28, height: 28)
                        .background(Color.macPrimary.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add article")
                .accessibilityHint("Save a new article by URL")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(Color.macSeparator)

            // Filter tabs
            HStack(spacing: 4) {
                ForEach(MacFilterOption.allCases, id: \.self) { filter in
                    filterButton(filter)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()
                .background(Color.macSeparator)

            // Article list in sidebar
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(viewModel.filteredArticles) { article in
                        sidebarArticleRow(article)
                    }
                }
            }

            Divider()
                .background(Color.macSeparator)

            // Bottom stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.articles.count) saved")
                        .font(.caption2)
                        .foregroundColor(.macTextTertiary)
                    Text("\(viewModel.archivedArticles.count) archived")
                        .font(.caption2)
                        .foregroundColor(.macTextTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.macSurface)
    }

    private func filterButton(_ filter: MacFilterOption) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            viewModel.selectedFilter = filter
        } label: {
            Text(filter.rawValue)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .macPrimary : .macTextSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.macPrimary.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: MacTheme.cornerRadiusSmall))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(filter.rawValue) filter")
        .accessibilityHint("Show \(filter.rawValue.lowercased()) articles")
    }

    private func sidebarArticleRow(_ article: Article) -> some View {
        let isSelected = viewModel.selectedArticle?.id == article.id
        return HStack(spacing: 10) {
            Circle()
                .fill(article.isRead ? Color.clear : Color.macPrimary)
                .frame(width: 6, height: 6)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(article.domain)
                    .font(.caption2)
                    .foregroundColor(.macTextSecondary)
                    .lineLimit(1)

                Text(article.title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.macTextPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.macSurfaceElevated : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectArticle(article)
        }
    }
}

#Preview {
    MacLibraryView(
        viewModel: MacLibraryViewModel(),
        showingAddURL: .constant(false),
        urlToAdd: .constant("")
    )
    .frame(width: 240, height: 600)
}
