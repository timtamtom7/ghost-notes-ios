import SwiftUI

struct MacAIHighlightsView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.macSeparator)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryCard
                    keyTakeawaysSection
                    highlightsSection
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 560)
        .background(Color.macBackground)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Summary")
                    .font(.headline)
                    .foregroundColor(.macTextPrimary)
                Text(article.domain)
                    .font(.caption)
                    .foregroundColor(.macTextSecondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.macTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.macSurfaceElevated)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.macSurface)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack")
                    .foregroundColor(.macPrimary)
                Text("Summary")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.macTextPrimary)
                Spacer()
            }

            if article.bodyContent.isEmpty {
                Text("Save the article to see a generated summary.")
                    .font(.subheadline)
                    .foregroundColor(.macTextTertiary)
                    .italic()
            } else {
                let summaryText = aiSummaryText
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundColor(.macTextSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(Color.macSurface)
        .cornerRadius(MacTheme.cornerRadiusMedium)
    }

    private var keyTakeawaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                Text("Key Takeaways")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.macTextPrimary)
                Spacer()
            }

            if article.bodyContent.isEmpty {
                Text("Save the article to see key takeaways.")
                    .font(.subheadline)
                    .foregroundColor(.macTextTertiary)
                    .italic()
            } else {
                let takeaways = aiKeyTakeaways
                ForEach(takeaways, id: \.self) { takeaway in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.macPrimary)
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                        Text(takeaway)
                            .font(.subheadline)
                            .foregroundColor(.macTextSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.macSurface)
        .cornerRadius(MacTheme.cornerRadiusMedium)
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "highlighter")
                    .foregroundColor(.macPrimary)
                Text("Suggested Highlights")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.macTextPrimary)
                Spacer()
            }

            if article.bodyContent.isEmpty {
                Text("Save the article to see AI-suggested highlights.")
                    .font(.subheadline)
                    .foregroundColor(.macTextTertiary)
                    .italic()
            } else {
                let highlights = aiSuggestedHighlights
                ForEach(highlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                            .foregroundColor(.macPrimary)
                            .padding(.top, 2)
                        Text(highlight)
                            .font(.subheadline)
                            .foregroundColor(.macTextSecondary)
                            .lineLimit(3)
                    }
                    .padding(10)
                    .background(Color.macSurfaceElevated)
                    .cornerRadius(MacTheme.cornerRadiusSmall)
                }
            }
        }
        .padding(16)
        .background(Color.macSurface)
        .cornerRadius(MacTheme.cornerRadiusMedium)
    }

    // MARK: - AI Logic

    private var aiSummaryText: String {
        let content = article.bodyContent
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.split(separator: " ").count > 3 }
        let top = Array(sentences.prefix(3))
        return top.map { "• " + $0 + "." }.joined(separator: "\n")
    }

    private var aiKeyTakeaways: [String] {
        let content = article.bodyContent
        let words = content.split(separator: " ")
        let midStart = words.count / 4
        let midLength = words.count / 2
        let midWords = Array(words.dropFirst(midStart).prefix(midLength))
        let midText = midWords.joined(separator: " ")
        let sentences = midText.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(sentences.prefix(3))
    }

    private var aiSuggestedHighlights: [String] {
        let content = article.bodyContent
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let important = sentences.filter { sentence in
            let lower = sentence.lowercased()
            let lengthOk = sentence.count > 30 && sentence.count < 150
            return (lower.contains("important") || lower.contains("key") ||
                    lower.contains("main") || lower.contains("significant")) && lengthOk
        }
        return Array(important.prefix(4))
    }
}

#Preview {
    MacAIHighlightsView(
        article: Article(
            url: "https://example.com",
            title: "The Future of SwiftUI",
            domain: "example.com",
            bodyContent: "SwiftUI continues to evolve with each release. The new features are significant and important for developers. The main improvements focus on performance and developer experience. Key innovations include better layout systems and improved animation primitives.",
            readingTimeMinutes: 5
        )
    )
}
