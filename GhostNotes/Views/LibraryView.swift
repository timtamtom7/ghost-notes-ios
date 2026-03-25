import SwiftUI

struct LibraryView: View {
    @Bindable var viewModel: LibraryViewModel
    @State private var urlInput = ""
    @State private var showingAddSheet = false
    @State private var selectedArticle: Article?
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.articles.isEmpty {
                ProgressView()
                    .tint(.primary)
            } else if viewModel.articles.isEmpty {
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
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .tint(.primary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingStats = true
                } label: {
                    Image(systemName: "chart.bar")
                }
                .tint(.textSecondary)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddArticleSheet(viewModel: viewModel, isPresented: $showingAddSheet)
        }
        .sheet(item: $selectedArticle) { article in
            ReadingView(article: article)
        }
        .sheet(isPresented: $viewModel.showingStats) {
            StatsView(stats: viewModel.stats)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundColor(.ghost)
            
            Text("Your library is empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Save articles from around the web.\nThey'll be here waiting for you.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
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
        .padding(32)
    }
    
    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.articles) { article in
                    ArticleCard(article: article)
                        .onTapGesture {
                            selectedArticle = article
                        }
                        .contextMenu {
                            Button {
                                Task { await viewModel.archiveArticle(article) }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            
                            Button {
                                Task { await viewModel.markAsRead(article) }
                            } label: {
                                Label("Mark as read", systemImage: "checkmark")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
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
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isFocused)
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.error)
                    }
                    
                    Button {
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(url.isEmpty || viewModel.isLoading)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Save Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.textSecondary)
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
