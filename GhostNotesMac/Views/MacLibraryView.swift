import SwiftUI

struct MacLibraryView: View {
    @Bindable var viewModel: MacLibraryViewModel
    @Binding var selectedArticle: Article?
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with search and add
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textSecondary)

                TextField("Search articles...", text: $viewModel.urlInput)
                    .textFieldStyle(.plain)
                    .foregroundColor(.textPrimary)
                    .onSubmit {
                        Task { await viewModel.addArticleFromInput() }
                    }

                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.surface)

            Divider()
                .background(Color.separator)

            // Article list
            if viewModel.isLoading && viewModel.articles.isEmpty {
                Spacer()
                ProgressView()
                    .tint(.primary)
                Spacer()
            } else if viewModel.articles.isEmpty {
                emptyState
            } else {
                articleList
            }
        }
        .frame(minWidth: 300)
        .background(Color.background)
        .sheet(isPresented: $showingAddSheet) {
            AddArticleSheet(viewModel: viewModel, isPresented: $showingAddSheet)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.ghost)
            Text("Your library is empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            Text("Add your first article to get started")
                .font(.body)
                .foregroundColor(.textSecondary)
            Button {
                showingAddSheet = true
            } label: {
                Label("Add Article", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var articleList: some View {
        List(viewModel.articles, selection: $selectedArticle) { article in
            ArticleRowView(article: article, viewModel: viewModel)
                .tag(article)
                .listRowBackground(
                    selectedArticle?.id == article.id
                        ? Color.primary.opacity(0.15)
                        : Color.clear
                )
                .contextMenu {
                    Button("Mark as Read") {
                        Task { await viewModel.markAsRead(article) }
                    }
                    Button("Mark as Unread") {
                        Task { await viewModel.markAsUnread(article) }
                    }
                    Divider()
                    Button("Archive") {
                        Task { await viewModel.archiveArticle(article) }
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

struct ArticleRowView: View {
    let article: Article
    let viewModel: MacLibraryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(article.title.isEmpty ? article.domain : article.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                Spacer()

                if article.isRead {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                        .font(.caption)
                }

                Text("\(article.readingTimeMinutes) min")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            HStack {
                Text(article.domain)
                    .font(.caption)
                    .foregroundColor(.primary)

                Text("·")
                    .foregroundColor(.textTertiary)

                Text(article.savedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            if !article.articleDescription.isEmpty {
                Text(article.articleDescription)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddArticleSheet: View {
    @Bindable var viewModel: MacLibraryViewModel
    @Binding var isPresented: Bool
    @State private var url = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Add Article")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            TextField("https://example.com/article", text: $url)
                .textFieldStyle(.roundedBorder)
                .font(.body)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    Task {
                        await viewModel.addArticle(url: url)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(url.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color.surface)
    }
}
