import SwiftUI

/// R8: AI-powered reading recommendations surfaced in the library
typealias ForYouView = RecommendationsView
struct RecommendationsView: View {
    @Bindable var viewModel: LibraryViewModel
    @State private var recommendations: [RecommendationService.Recommendation] = []
    @State private var isLoading = true
    @State private var selectedArticle: Article?

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            if isLoading {
                loadingState
            } else if recommendations.isEmpty {
                emptyState
            } else {
                recommendationsList
            }
        }
        .navigationTitle("For You")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedArticle) { article in
            ReadingView(article: article)
        }
        .task {
            await loadRecommendations()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.primary)

            Text("Finding articles for you…")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundColor(.ghost)

            Text("No recommendations yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Read more articles to unlock\npersonalized suggestions.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var recommendationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Section header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        Text("Based on what you've been reading")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Button {
                        Task { await loadRecommendations() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Refresh recommendations")
                }
                .padding(.horizontal, 4)

                ForEach(recommendations) { recommendation in
                    RecommendationCard(
                        recommendation: recommendation,
                        onRead: {
                            selectedArticle = recommendation.article
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private func loadRecommendations() async {
        isLoading = true
        recommendations = []

        let readArticles = (viewModel.articles + viewModel.archivedArticles).filter { $0.isRead }
        let unreadArticles = (viewModel.articles + viewModel.archivedArticles).filter { !$0.isRead }

        // Use a brief delay so loading state is visible
        try? await Task.sleep(nanoseconds: 600_000_000)

        recommendations = RecommendationService.shared.recommend(
            from: unreadArticles,
            readArticles: readArticles,
            limit: 10
        )

        isLoading = false
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: RecommendationService.Recommendation
    let onRead: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(recommendation.article.domain)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        // Reason badge
                        Text(recommendation.reason)
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.surfaceElevated)
                            .clipShape(Capsule())
                    }

                    Text(recommendation.article.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                }

                Spacer()

                // AI confidence indicator
                VStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.primary)

                    Text("\(Int(recommendation.score * 10))%")
                        .font(.caption2)
                        .foregroundColor(.textTertiary)
                }
            }

            if !recommendation.article.articleDescription.isEmpty {
                Text(recommendation.article.articleDescription)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(recommendation.article.readingTimeMinutes) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.textTertiary)

                if recommendation.article.readingProgress > 0 {
                    Label("\(Int(recommendation.article.readingProgress * 100))% read", systemImage: "book")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }

                Spacer()

                Button {
                    onRead()
                } label: {
                    Text("Read")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.background)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.primary)
                        .clipShape(Capsule())
                }
                .accessibilityLabel("Read \(recommendation.article.title)")
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        RecommendationsView(viewModel: LibraryViewModel())
    }
}
