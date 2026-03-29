import SwiftUI

struct MacReadingView: View {
    let article: Article
    @Bindable var viewModel: MacLibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fontSize: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)

                    HStack {
                        Text(article.domain)
                            .font(.caption)
                            .foregroundColor(.primary)

                        Text("·")

                        Text("\(article.readingTimeMinutes) min read")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Button {
                    Task { await viewModel.markAsRead(article) }
                } label: {
                    Image(systemName: article.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(article.isRead ? .success : .textSecondary)

                Button {
                    Task { await viewModel.archiveArticle(article) }
                    dismiss()
                } label: {
                    Image(systemName: "archivebox")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(.textSecondary)

                Divider()
                    .frame(height: 24)

                Button {
                    if let url = URL(string: article.url) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "safari")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.surface)

            Divider().background(Color.separator)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(article.title)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.textPrimary)
                        .padding(.bottom, 8)

                    HStack {
                        Text(article.domain)
                            .font(.caption)
                            .foregroundColor(.primary)

                        Text("·")

                        Text(article.savedAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Text("\(article.readingTimeMinutes) min read")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.bottom, 24)

                    if let description = Optional(article.articleDescription), !description.isEmpty {
                        Text(description)
                            .font(.system(size: fontSize, design: .serif))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(8)
                            .padding(.bottom, 24)
                    }

                    if let body = Optional(article.bodyContent), !body.isEmpty {
                        Text(body)
                            .font(.system(size: fontSize, design: .serif))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(fontSize * 0.4)
                    } else {
                        Text("No content available. Open in Safari to read the full article.")
                            .font(.body)
                            .foregroundColor(.textTertiary)
                            .italic()
                    }
                }
                .padding(40)
                .frame(maxWidth: 720)
            }
            .background(Color.background)
        }
    }
}

struct MacForYouView: View {
    @Bindable var viewModel: MacLibraryViewModel
    @Binding var selectedArticle: Article?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("For You")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.surface)

            Divider().background(Color.separator)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.articles.isEmpty {
                        emptyState
                    } else {
                        Text("Recommended based on your reading")
                            .font(.headline)
                            .foregroundColor(.textSecondary)

                        ForEach(viewModel.articles.prefix(5)) { article in
                            RecommendationCard(article: article, viewModel: viewModel)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.background)
        }
        .frame(minWidth: 300)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.ghost)
            Text("Add articles to get personalized recommendations")
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct RecommendationCard: View {
    let article: Article
    @Bindable var viewModel: MacLibraryViewModel

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                Text(article.domain)
                    .font(.caption)
                    .foregroundColor(.primary)

                if !article.articleDescription.isEmpty {
                    Text(article.articleDescription)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack {
                Text("\(article.readingTimeMinutes) min")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MacCollectionsView: View {
    @Bindable var viewModel: MacLibraryViewModel
    @State private var newCollectionName = ""
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Collections")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.surface)

            Divider().background(Color.separator)

            if viewModel.collections.isEmpty {
                emptyState
            } else {
                List(viewModel.collections) { collection in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.primary)
                        Text(collection.name)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(collection.articleCount)")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.vertical, 8)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteCollection(collection) }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(minWidth: 300)
        .background(Color.background)
        .sheet(isPresented: $showingAddSheet) {
            VStack(spacing: 16) {
                Text("New Collection")
                    .font(.headline)
                TextField("Collection name", text: $newCollectionName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Cancel") { showingAddSheet = false }
                    Button("Create") {
                        Task {
                            await viewModel.addCollection(name: newCollectionName)
                            newCollectionName = ""
                            showingAddSheet = false
                        }
                    }
                    .disabled(newCollectionName.isEmpty)
                }
            }
            .padding(24)
            .frame(width: 300)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundColor(.ghost)
            Text("No collections yet")
                .foregroundColor(.textSecondary)
            Button("Create Collection") {
                showingAddSheet = true
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Spacer()
        }
    }
}

struct MacHighlightsView: View {
    @Bindable var viewModel: MacLibraryViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Highlights")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.surface)

            Divider().background(Color.separator)

            if viewModel.highlights.isEmpty {
                emptyState
            } else {
                List(viewModel.highlights) { highlight in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color(hex: HighlightColor(rawValue: highlight.color.rawValue)?.hex ?? "7B6CF6"))
                                .frame(width: 10, height: 10)
                            Text(highlight.selectedAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                            Spacer()
                            Button {
                                Task { await viewModel.deleteHighlight(highlight) }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.error)
                        }

                        Text("\"\(highlight.text)\"")
                            .font(.body)
                            .foregroundColor(.textPrimary)
                            .italic()

                        if let note = highlight.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(.plain)
            }
        }
        .frame(minWidth: 300)
        .background(Color.background)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "highlighter")
                .font(.system(size: 40))
                .foregroundColor(.ghost)
            Text("No highlights yet")
                .foregroundColor(.textSecondary)
            Text("Highlight text in articles to save passages")
                .font(.caption)
                .foregroundColor(.textTertiary)
            Spacer()
        }
    }
}

struct MacStatsView: View {
    @Bindable var viewModel: MacLibraryViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Stats")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.surface)

            Divider().background(Color.separator)

            ScrollView {
                VStack(spacing: 24) {
                    // Streak
                    HStack(spacing: 24) {
                        StatCard(title: "Current Streak", value: "\(viewModel.streak.currentStreak)", subtitle: "days", icon: "flame.fill", color: .orange)
                        StatCard(title: "Longest Streak", value: "\(viewModel.streak.longestStreak)", subtitle: "days", icon: "trophy.fill", color: .yellow)
                        StatCard(title: "Total Read", value: "\(viewModel.stats.totalRead)", subtitle: "articles", icon: "checkmark.circle.fill", color: .success)
                    }

                    HStack(spacing: 24) {
                        StatCard(title: "Saved", value: "\(viewModel.stats.totalSaved)", subtitle: "articles", icon: "bookmark.fill", color: .primary)
                        StatCard(title: "Archived", value: "\(viewModel.stats.totalArchived)", subtitle: "articles", icon: "archivebox.fill", color: .textSecondary)
                        StatCard(title: "Total Time", value: "\(viewModel.stats.totalReadingTimeMinutes)", subtitle: "minutes", icon: "clock.fill", color: .accent)
                    }
                }
                .padding(24)
            }
            .background(Color.background)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MacArchiveView: View {
    @Bindable var viewModel: MacLibraryViewModel
    @Binding var selectedArticle: Article?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Archive")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.surface)

            Divider().background(Color.separator)

            if viewModel.archivedArticles.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "archivebox")
                        .font(.system(size: 40))
                        .foregroundColor(.ghost)
                    Text("No archived articles")
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
            } else {
                List(viewModel.archivedArticles, selection: $selectedArticle) { article in
                    ArticleRowView(article: article, viewModel: viewModel)
                        .tag(article)
                        .contextMenu {
                            Button("Restore to Library") {
                                Task { await viewModel.unarchiveArticle(article) }
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                Task { await viewModel.deleteArticle(article) }
                            }
                        }
                }
                .listStyle(.plain)
            }
        }
        .frame(minWidth: 300)
        .background(Color.background)
    }
}
