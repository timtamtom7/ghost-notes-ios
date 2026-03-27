import SwiftUI

struct ArticleCard: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(article.domain)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        if article.isRead {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.success)
                        }
                    }

                    Text(article.title)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                }

                Spacer()

                if article.readingProgress > 0 && article.readingProgress < 1 {
                    CircularProgressView(progress: article.readingProgress)
                        .frame(width: 24, height: 24)
                }
            }

            if !article.articleDescription.isEmpty {
                Text(article.articleDescription)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(article.readingTimeMinutes) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.textTertiary)

                if let collection = article.collectionName {
                    Label(collection, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.primary)
                }

                Spacer()

                Text(article.savedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge))
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: article.id)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var desc = "\(article.title), from \(article.domain), \(article.readingTimeMinutes) minute read"
        if article.isRead {
            desc += ", read"
        }
        if !article.articleDescription.isEmpty {
            desc += ". \(article.articleDescription)"
        }
        return desc
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.ghost, lineWidth: 2)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ArticleCard(article: Article(
            url: "https://example.com/article",
            title: "How to Build a Reading Habit That Actually Sticks",
            domain: "example.com",
            articleDescription: "Reading more is a common goal, but most people fail. Here's why — and what to do instead.",
            readingTimeMinutes: 8,
            isRead: false
        ))

        ArticleCard(article: Article(
            url: "https://example.com/article2",
            title: "The Quiet Revolution in AI Reasoning",
            domain: "example.com",
            articleDescription: "A deep dive into chain-of-thought reasoning and what it means for the future of AI.",
            readingTimeMinutes: 12,
            isRead: true,
            collectionName: "Research"
        ))
    }
    .padding()
    .background(Color.background)
}
