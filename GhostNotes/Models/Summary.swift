import Foundation

/// R11: AI Reading Intelligence
/// Represents an AI-generated summary of an article.

struct Summary: Identifiable, Codable, Equatable {
    let id: UUID
    let articleId: UUID
    let summaryText: String
    let keyInsights: [String]
    let readingMode: ReadingMode
    let generatedAt: Date

    enum ReadingMode: String, Codable {
        case full       // Full summary
        case threeMinute // Condensed key points only (~3 min read)
    }

    init(
        id: UUID = UUID(),
        articleId: UUID,
        summaryText: String,
        keyInsights: [String] = [],
        readingMode: ReadingMode = .full,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.articleId = articleId
        self.summaryText = summaryText
        self.keyInsights = keyInsights
        self.readingMode = readingMode
        self.generatedAt = generatedAt
    }
}
