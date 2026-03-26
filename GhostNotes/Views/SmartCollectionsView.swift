import SwiftUI

/// R8: Smart Collections — auto-organized article groups by detected topic
struct SmartCollectionsView: View {
    @Bindable var viewModel: LibraryViewModel
    @State private var topics: [TopicClusterService.Topic] = []
    @State private var isLoading = true
    @State private var selectedTopic: TopicClusterService.Topic?
    @State private var selectedArticle: Article?

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.primary)
            } else if topics.isEmpty {
                emptyState
            } else {
                topicsGrid
            }
        }
        .navigationTitle("Smart Collections")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refreshTopics() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                }
                .tint(.textSecondary)
                .accessibilityLabel("Refresh topic clustering")
            }
        }
        .sheet(item: $selectedArticle) { article in
            ReadingView(article: article)
        }
        .task {
            await refreshTopics()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 56))
                .foregroundColor(.ghost)

            Text("No topics detected")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Save more articles and we'll\nauto-organize them by topic.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var topicsGrid: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Topic cards
                ForEach(topics) { topic in
                    TopicCard(topic: topic) {
                        selectedTopic = topic
                    }
                }

                // Keywords section
                if !allKeywords.isEmpty {
                    keywordsSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .sheet(item: $selectedTopic) { topic in
            TopicDetailSheet(topic: topic, viewModel: viewModel) { article in
                selectedArticle = article
            }
        }
    }

    private var allKeywords: [String] {
        Array(topics.flatMap { $0.keywords }.prefix(20))
    }

    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Keywords")
                .font(.headline)
                .foregroundColor(.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(allKeywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.surface)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.surfaceElevated.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func refreshTopics() async {
        isLoading = true
        let allArticles = viewModel.articles + viewModel.archivedArticles

        // Brief loading state
        try? await Task.sleep(nanoseconds: 400_000_000)

        topics = TopicClusterService.shared.clusterArticles(allArticles)
        isLoading = false
    }
}

// MARK: - Topic Card

struct TopicCard: View {
    let topic: TopicClusterService.Topic
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("\(topic.articles.count) article\(topic.articles.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }

                if !topic.keywords.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(topic.keywords.prefix(4), id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption2)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.primary.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        if topic.keywords.count > 4 {
                            Text("+\(topic.keywords.count - 4)")
                                .font(.caption2)
                                .foregroundColor(.textTertiary)
                        }
                    }
                }

                // Preview articles
                HStack(spacing: -8) {
                    ForEach(topic.articles.prefix(3)) { article in
                        Circle()
                            .fill(Color.ghost)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Text(String(article.domain.prefix(1)).uppercased())
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.textSecondary)
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.surface, lineWidth: 2)
                            )
                    }

                    if topic.articles.count > 3 {
                        Text("+\(topic.articles.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.textTertiary)
                            .padding(.leading, 12)
                    }

                    Spacer()
                }
            }
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(topic.name) topic with \(topic.articles.count) articles")
    }
}

// MARK: - Topic Detail Sheet

struct TopicDetailSheet: View {
    let topic: TopicClusterService.Topic
    @Bindable var viewModel: LibraryViewModel
    let onArticleTap: (Article) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Topic header
                        VStack(alignment: .leading, spacing: 12) {
                            Text(topic.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            HStack(spacing: 8) {
                                Label("\(topic.articles.count) articles", systemImage: "doc.text")
                                Label("Auto-organized", systemImage: "wand.and.stars")
                            }
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                            if !topic.keywords.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(topic.keywords, id: \.self) { keyword in
                                        Text(keyword)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.primary.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Articles
                        ForEach(topic.articles) { article in
                            ArticleCard(article: article)
                                .onTapGesture {
                                    dismiss()
                                    onArticleTap(article)
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
            }
            .navigationTitle("Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                self.size.width = max(self.size.width, currentX)
            }

            self.size.height = currentY + lineHeight
        }
    }
}

#Preview {
    NavigationStack {
        SmartCollectionsView(viewModel: LibraryViewModel())
    }
}
