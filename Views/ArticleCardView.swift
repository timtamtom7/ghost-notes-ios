import SwiftUI

struct ArticleCardView: View {
    let article: Article
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            faviconView
            contentView
            Spacer()
            unreadIndicator
        }
        .padding(Theme.cardPadding)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusCard)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }) {}
    }

    private var faviconView: some View {
        AsyncImage(url: URL(string: article.faviconURL ?? "")) { phase in
            switch phase {
            case .success:
                phase.image?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure, .empty:
                Image(systemName: "globe")
                    .foregroundColor(Theme.textTertiary)
            @unknown default:
                Image(systemName: "globe")
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(width: 32, height: 32)
        .background(Theme.surfaceSecondary)
        .cornerRadius(6)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.domain)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)

            Text(article.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label("\(article.estimatedReadingTime) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)

                if article.summary != nil {
                    Text("•")
                        .foregroundColor(Theme.textTertiary)
                    Text("Summarized")
                        .font(.caption)
                        .foregroundColor(Theme.accentSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var unreadIndicator: some View {
        if article.status == .unread {
            Circle()
                .fill(Theme.accent)
                .frame(width: 8, height: 8)
        }
    }
}

#Preview {
    VStack {
        ArticleCardView(article: Article(
            url: "https://example.com/article",
            title: "How to Build a Great iOS App with SwiftUI and XcodeGen",
            domain: "example.com",
            summary: "• Key point one\n• Key point two",
            estimatedReadingTime: 8
        ))
        ArticleCardView(article: Article(
            url: "https://swift.org",
            title: "Swift Programming Language",
            domain: "swift.org",
            estimatedReadingTime: 5
        ))
    }
    .padding()
    .background(Theme.background)
}
