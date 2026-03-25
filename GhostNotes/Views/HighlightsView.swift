import SwiftUI

struct HighlightsView: View {
    @Bindable var viewModel: LibraryViewModel
    @State private var selectedArticle: Article?
    @State private var selectedHighlight: Highlight?
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            if viewModel.highlights.isEmpty {
                emptyState
            } else {
                highlightList
            }
        }
        .navigationTitle("Highlights")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedHighlight) { highlight in
            if let article = viewModel.articles.first(where: { $0.id == highlight.articleId }) {
                HighlightDetailSheet(highlight: highlight, article: article) {
                    Task { await viewModel.deleteHighlight(highlight) }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "highlighter")
                .font(.system(size: 56))
                .foregroundColor(.ghost)
            
            Text("No highlights yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Highlight text while reading\nto save your favorite passages.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
    
    private var highlightList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.highlights) { highlight in
                    HighlightCard(highlight: highlight, article: viewModel.articles.first { $0.id == highlight.articleId })
                        .onTapGesture {
                            selectedHighlight = highlight
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = highlight.text
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            
                            Button(role: .destructive) {
                                Task { await viewModel.deleteHighlight(highlight) }
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

struct HighlightCard: View {
    let highlight: Highlight
    let article: Article?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Article info
            if let article = article {
                HStack(spacing: 6) {
                    Text(article.domain)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                    
                    Text(article.title)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // Highlight text
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color(hex: highlight.color.hex))
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(highlight.text)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .lineLimit(4)
                    
                    if let note = highlight.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .italic()
                    }
                }
            }
            
            // Meta
            HStack {
                Text(highlight.selectedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                
                Spacer()
                
                if let article = article {
                    Text("\(article.readingTimeMinutes) min read")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct HighlightDetailSheet: View {
    let highlight: Highlight
    let article: Article
    let onDelete: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var note: String
    
    init(highlight: Highlight, article: Article, onDelete: @escaping () async -> Void) {
        self.highlight = highlight
        self.article = article
        self.onDelete = onDelete
        _note = State(initialValue: highlight.note ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Article header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(article.domain)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text(article.title)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Highlight
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: highlight.color.hex))
                                    .frame(width: 12, height: 12)
                                
                                Text(highlight.color.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Text(highlight.text)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                                .lineSpacing(6)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Note")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            TextEditor(text: $note)
                                .font(.body)
                                .foregroundColor(.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(12)
                                .background(Color.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await onDelete()
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.error)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HighlightsView(viewModel: LibraryViewModel())
    }
}
