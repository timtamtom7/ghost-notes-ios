import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @EnvironmentObject var articleStore: ArticleStore
    @Environment(\.dismiss) var dismiss
    @State private var scrollOffset: CGFloat = 0
    @State private var isGeneratingSummary = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                    headerSection
                    if let summary = article.summary {
                        AISummaryCard(
                            summary: summary,
                            isGenerating: isGeneratingSummary,
                            onRegenerate: {
                                Task {
                                    isGeneratingSummary = true
                                    await articleStore.regenerateSummary(for: article)
                                    isGeneratingSummary = false
                                }
                            }
                        )
                    } else {
                        generateSummaryButton
                    }
                    contentSection
                }
                .padding(.horizontal, Theme.screenMargin)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: URL(string: article.url) ?? URL(string: "https://example.com")!) {
                    Image(systemName: "square.and.arrow.up")
                }
                .tint(Theme.accent)
            }
        }
        .onAppear {
            if article.status == .unread {
                Task {
                    await articleStore.markAsRead(article)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: article.faviconURL ?? "")) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "globe")
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                .frame(width: 20, height: 20)
                .background(Theme.surfaceSecondary)
                .cornerRadius(4)

                Text(article.domain)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)

                Text("•")
                    .foregroundColor(Theme.textTertiary)

                Text(article.dateAdded, style: .date)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }

            Text(article.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 16) {
                Label("\(article.estimatedReadingTime) min read", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)

                if article.status == .read {
                    Label("Read", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Theme.success)
                }
            }

            Divider()
                .background(Theme.surfaceSecondary)
        }
    }

    private var generateSummaryButton: some View {
        Button {
            Task {
                isGeneratingSummary = true
                await articleStore.regenerateSummary(for: article)
                isGeneratingSummary = false
            }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate AI Summary")
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(Theme.accent)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Theme.accent.opacity(0.1))
            .cornerRadius(Theme.cornerRadiusButton)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Article")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
                .textCase(.uppercase)

            if let content = article.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textPrimary)
                    .lineSpacing(6)
            } else {
                Text("Content unavailable. Visit the original article for the full text.")
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: Article(
            url: "https://example.com",
            title: "Building Better Software with Swift",
            domain: "example.com",
            content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
            summary: "• First key insight about the topic\n• Second important point to remember\n• Third takeaway for readers",
            estimatedReadingTime: 5
        ))
        .environmentObject(ArticleStore())
    }
}
