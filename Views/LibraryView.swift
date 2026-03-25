import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var articleStore: ArticleStore
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var showingAddSheet = false
    @State private var articleToDelete: Article?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                filterPicker
                articleList
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                }
                .tint(Theme.accent)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddArticleSheet()
        }
        .alert("Delete Article", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let article = articleToDelete {
                    articleStore.deleteArticle(article)
                }
            }
        } message: {
            Text("Are you sure you want to delete this article? This cannot be undone.")
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.textTertiary)
            TextField("Search articles...", text: $searchText)
                .foregroundColor(Theme.textPrimary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surfaceSecondary)
        .cornerRadius(10)
        .padding(.horizontal, Theme.screenMargin)
        .padding(.top, 8)
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.screenMargin)
        .padding(.vertical, 12)
    }

    private var articleList: some View {
        let filtered = articleStore.filteredArticles(filter: selectedFilter, searchText: searchText)

        return Group {
            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                ArticleCardView(article: article)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    Task {
                                        await articleStore.archiveArticle(article)
                                    }
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }

                                Button(role: .destructive) {
                                    articleToDelete = article
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                if article.summary != nil {
                                    Button {
                                        Task {
                                            await articleStore.regenerateSummary(for: article)
                                        }
                                    } label: {
                                        Label("Regenerate Summary", systemImage: "arrow.clockwise")
                                    }
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task {
                                        await articleStore.archiveArticle(article)
                                    }
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(Theme.accent)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    articleToDelete = article
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.screenMargin)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundColor(Theme.textTertiary)
            Text("Your library is empty")
                .font(.title2.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
            Text("Save your first article to get started")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
            Button {
                showingAddSheet = true
            } label: {
                Text("Add Article")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .cornerRadius(Theme.cornerRadiusButton)
            }
            .padding(.top, 8)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
            .environmentObject(ArticleStore())
    }
}
