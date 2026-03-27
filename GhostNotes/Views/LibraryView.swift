import SwiftUI

struct LibraryView: View {
    @Bindable var viewModel: LibraryViewModel
    @State private var urlInput = ""
    @State private var showingAddSheet = false
    @State private var selectedArticle: Article?
    @State private var showingFilters = false

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.articles.isEmpty {
                ProgressView()
                    .tint(.primary)
            } else if viewModel.filteredArticles.isEmpty {
                emptyState
            } else {
                articleList
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Theme.haptic(.light)
                    showingFilters.toggle()
                } label: {
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .fontWeight(.semibold)
                }
                .tint(showingFilters ? .primary : .textSecondary)
                .accessibilityLabel(showingFilters ? "Hide filters" : "Show filters")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Theme.haptic(.light)
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .tint(.primary)
                .accessibilityLabel("Add article")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Theme.haptic(.light)
                    viewModel.showingStats = true
                } label: {
                    Image(systemName: "chart.bar")
                }
                .tint(.textSecondary)
                .accessibilityLabel("View reading stats")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddArticleSheet(viewModel: viewModel, isPresented: $showingAddSheet)
        }
        .sheet(item: $selectedArticle) { article in
            ReadingView(article: article)
        }
        .sheet(isPresented: $viewModel.showingStats) {
            StatsView(stats: viewModel.stats, streak: viewModel.streak)
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersSheet(viewModel: viewModel, isPresented: $showingFilters)
        }
        .task {
            await viewModel.load()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundColor(.ghost)

            Text(viewModel.searchQuery.isEmpty ? "Your library is empty" : "No results")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text(viewModel.searchQuery.isEmpty ?
                 "Save articles from around the web.\nThey'll be here waiting for you." :
                 "Try a different search or clear filters.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    Theme.haptic(.light)
                    viewModel.searchQuery = ""
                    Task { await viewModel.load() }
                } label: {
                    Text("Clear search")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.top, 8)
                .accessibilityLabel("Clear search results")
            } else {
                Button {
                    Theme.haptic(.light)
                    showingAddSheet = true
                } label: {
                    Label("Save your first article", systemImage: "plus")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.background)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.primary)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if showingFilters {
                    activeFiltersBar
                }

                ForEach(viewModel.filteredArticles) { article in
                    ArticleCard(article: article)
                        .onTapGesture {
                            Theme.haptic(.light)
                            selectedArticle = article
                        }
                        .contextMenu {
                            Button {
                                Theme.haptic(.success)
                                Task { await viewModel.archiveArticle(article) }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }

                            Button {
                                Theme.haptic(.light)
                                Task { await viewModel.markAsRead(article) }
                            } label: {
                                Label("Mark as read", systemImage: "checkmark")
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

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if viewModel.filterReadStatus != .all {
                    filterChip(label: viewModel.filterReadStatus == .unread ? "Unread" : "Read") {
                        Theme.haptic(.light)
                        viewModel.filterReadStatus = .all
                    }
                }
                if !viewModel.filterDomain.isEmpty {
                    filterChip(label: viewModel.filterDomain) {
                        Theme.haptic(.light)
                        viewModel.filterDomain = ""
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func filterChip(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.background)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.background.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.primary)
        .clipShape(Capsule())
    }
}

struct SearchFiltersSheet: View {
    @Bindable var viewModel: LibraryViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Read status filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 8) {
                            filterButton(title: "All", isSelected: viewModel.filterReadStatus == .all) {
                                viewModel.filterReadStatus = .all
                            }
                            filterButton(title: "Unread", isSelected: viewModel.filterReadStatus == .unread) {
                                viewModel.filterReadStatus = .unread
                            }
                            filterButton(title: "Read", isSelected: viewModel.filterReadStatus == .read) {
                                viewModel.filterReadStatus = .read
                            }
                        }
                    }

                    // Domain filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Domain")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        TextField("e.g., medium.com", text: $viewModel.filterDomain)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(12)
                            .background(Color.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Theme.haptic(.light)
                        isPresented = false
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.primary)
                    .accessibilityLabel("Done applying filters")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func filterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Theme.haptic(.light)
            action()
        } label: {
            Text(title)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.primary : Color.surface)
                .foregroundColor(isSelected ? .background : .textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
        }
        .accessibilityLabel("\(title) filter, \(isSelected ? "selected" : "not selected")")
    }
}

struct AddArticleSheet: View {
    @Bindable var viewModel: LibraryViewModel
    @Binding var isPresented: Bool
    @State private var url = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Article URL")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        TextField("https://example.com/article", text: $url)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(16)
                            .background(Color.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
                            .focused($isFocused)
                            .accessibilityLabel("Article URL input")
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.error)
                            .accessibilityLabel("Error: \(error)")
                    }

                    Button {
                        Theme.haptic(.success)
                        Task {
                            await viewModel.addArticle(url: url)
                            if viewModel.errorMessage == nil {
                                isPresented = false
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.background)
                            } else {
                                Text("Save Article")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(url.isEmpty ? Color.ghost : Color.primary)
                        .foregroundColor(.background)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
                    }
                    .disabled(url.isEmpty || viewModel.isLoading)
                    .accessibilityLabel("Save article to library")

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Save Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Theme.haptic(.light)
                        isPresented = false
                    } label: {
                        Text("Cancel")
                    }
                    .foregroundColor(.textSecondary)
                    .accessibilityLabel("Cancel and dismiss")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView(viewModel: LibraryViewModel())
    }
}
