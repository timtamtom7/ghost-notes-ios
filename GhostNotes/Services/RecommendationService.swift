import Foundation
import NaturalLanguage

/// R8: AI-powered article recommendations based on reading patterns
final class RecommendationService: @unchecked Sendable {
    static let shared = RecommendationService()
    
    private init() {}
    
    struct Recommendation: Identifiable {
        let id: UUID
        let article: Article
        let reason: String
        let score: Double
    }
    
    /// Recommend articles based on reading history and content similarity
    func recommend(from articles: [Article], readArticles: [Article], limit: Int = 5) -> [Recommendation] {
        guard articles.count > readArticles.count else { return [] }
        
        let readDomains = Set(readArticles.map { $0.domain })
        let readTitles = readArticles.map { $0.title.lowercased() }
        
        var scored: [(Article, Double, String)] = []
        
        for article in articles where !readArticles.contains(where: { $0.id == article.id }) {
            var score: Double = 0
            var reason = ""
            
            // Boost articles from domains user reads frequently
            if readDomains.contains(article.domain) {
                score += 2.0
                reason = "From a domain you read often"
            }
            
            // Boost based on recency
            let daysSinceSaved = Calendar.current.dateComponents([.day], from: article.savedAt, to: Date()).day ?? 0
            if daysSinceSaved <= 7 {
                score += 1.5
                if reason.isEmpty { reason = "Recently saved" }
            }
            
            // Boost based on reading time (medium-length articles tend to be most valuable)
            if article.readingTimeMinutes >= 5 && article.readingTimeMinutes <= 15 {
                score += 0.5
            }
            
            // Analyze content themes
            let contentToAnalyze = article.title + " " + article.articleDescription
            for readTitle in readTitles.prefix(5) {
                let similarity = calculateSimilarity(contentToAnalyze, readTitle)
                if similarity > 0.3 {
                    score += similarity
                    if reason.isEmpty { reason = "Related to something you read" }
                }
            }
            
            scored.append((article, score, reason.isEmpty ? "Recommended for you" : reason))
        }
        
        scored.sort { $0.1 > $1.1 }
        return scored.prefix(limit).enumerated().map { index, item in
            Recommendation(id: UUID(), article: item.0, reason: item.2, score: item.1)
        }
    }
    
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english),
              let vector1 = embedding.vector(for: text1),
              let vector2 = embedding.vector(for: text2) else {
            return 0
        }
        
        var dotProduct: Double = 0
        var norm1: Double = 0
        var norm2: Double = 0
        
        for i in 0..<vector1.count {
            dotProduct += vector1[i] * vector2[i]
            norm1 += vector1[i] * vector1[i]
            norm2 += vector2[i] * vector2[i]
        }
        
        let denominator = sqrt(norm1) * sqrt(norm2)
        return denominator > 0 ? dotProduct / denominator : 0
    }
}

/// R8: Auto-organize articles by topic using NLP
final class TopicClusterService: @unchecked Sendable {
    static let shared = TopicClusterService()
    
    private init() {}
    
    struct Topic: Identifiable {
        let id: UUID
        let name: String
        let keywords: [String]
        var articles: [Article]
    }
    
    /// Cluster articles by detected topic using keyword extraction
    func clusterArticles(_ articles: [Article]) -> [Topic] {
        let knownTopics: [(name: String, keywords: [String])] = [
            ("Technology", ["AI", "tech", "software", "app", "computer", "digital", "code", "programming", "machine learning", "data"]),
            ("Science", ["research", "study", "scientific", "experiment", "physics", "biology", "climate", "space", "NASA"]),
            ("Business", ["startup", "company", "market", "revenue", "investment", "founder", "CEO", "growth", "strategy"]),
            ("Health", ["health", "medical", "doctor", "wellness", "fitness", "mental", "diet", "sleep", "exercise"]),
            ("Design", ["design", "UI", "UX", "creative", "visual", "brand", "art", "typography", "color"]),
            ("Politics", ["government", "policy", "election", "vote", "political", "congress", "law", "regulation"]),
            ("Culture", ["culture", "society", "community", "people", "life", "story", "experience", "relationship"])
        ]
        
        var topics: [Topic] = []
        
        for (name, keywords) in knownTopics {
            let matching = articles.filter { article in
                let text = (article.title + " " + article.articleDescription).lowercased()
                return keywords.contains { text.contains($0.lowercased()) }
            }
            
            if !matching.isEmpty {
                topics.append(Topic(id: UUID(), name: name, keywords: keywords, articles: matching))
            }
        }
        
        // Add uncategorized
        let categorizedIds = Set(topics.flatMap { $0.articles.map { $0.id } })
        let uncategorized = articles.filter { !categorizedIds.contains($0.id) }
        if !uncategorized.isEmpty {
            topics.append(Topic(id: UUID(), name: "General", keywords: [], articles: uncategorized))
        }
        
        return topics
    }
    
    /// Extract top keywords from article content
    func extractKeywords(from text: String, limit: Int = 5) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var nouns: [String: Int] = [:]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun {
                let word = String(text[range]).lowercased()
                if word.count > 3 {
                    nouns[word, default: 0] += 1
                }
            }
            return true
        }
        
        return nouns.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
}

/// R8: Export highlights to Readwise and other platforms
final class ExportService: @unchecked Sendable {
    static let shared = ExportService()
    
    private init() {}
    
    struct ReadwiseHighlight: Codable {
        let text: String
        let title: String
        let author: String?
        let sourceUrl: String
        let sourceType: String
        let highlightAt: Date
        let note: String?
    }
    
    struct ReadwiseExportResult {
        let success: Bool
        let highlightsExported: Int
        let errorMessage: String?
    }
    
    /// Export highlights to Readwise via their API
    /// Note: Requires READWISE_API_KEY to be set
    func exportToReadwise(highlights: [Highlight], articles: [Article]) async -> ReadwiseExportResult {
        guard let apiKey = ProcessInfo.processInfo.environment["READWISE_API_KEY"] else {
            return ReadwiseExportResult(success: false, highlightsExported: 0, errorMessage: "READWISE_API_KEY not configured")
        }
        
        let articleMap = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
        
        var readwiseHighlights: [ReadwiseHighlight] = []
        for highlight in highlights {
            guard let article = articleMap[highlight.articleId] else { continue }
            
            readwiseHighlights.append(ReadwiseHighlight(
                text: highlight.text,
                title: article.title,
                author: nil,
                sourceUrl: article.url,
                sourceType: "article",
                highlightAt: highlight.selectedAt,
                note: highlight.note
            ))
        }
        
        guard !readwiseHighlights.isEmpty else {
            return ReadwiseExportResult(success: true, highlightsExported: 0, errorMessage: nil)
        }
        
        guard let url = URL(string: "https://readwise.io/api/v2/highlights/") else {
            return ReadwiseExportResult(success: false, highlightsExported: 0, errorMessage: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "highlights": readwiseHighlights.map { h -> [String: Any] in
                var dict: [String: Any] = [
                    "text": h.text,
                    "title": h.title,
                    "source_url": h.sourceUrl,
                    "source_type": h.sourceType,
                    "highlighted_at": ISO8601DateFormatter().string(from: h.highlightAt)
                ]
                if let note = h.note { dict["note"] = note }
                if let author = h.author { dict["author"] = author }
                return dict
            }
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                return ReadwiseExportResult(success: true, highlightsExported: readwiseHighlights.count, errorMessage: nil)
            } else {
                return ReadwiseExportResult(success: false, highlightsExported: 0, errorMessage: "Export failed with status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            }
        } catch {
            return ReadwiseExportResult(success: false, highlightsExported: 0, errorMessage: error.localizedDescription)
        }
    }
    
    /// Export highlights as formatted text for sharing
    func exportAsText(highlights: [Highlight], articles: [Article]) -> String {
        let articleMap = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
        
        var output = "# My Ghost Notes Highlights\n\n"
        
        for highlight in highlights {
            guard let article = articleMap[highlight.articleId] else { continue }
            output += "## \(article.title)\n"
            output += "Source: \(article.url)\n\n"
            output += "> \(highlight.text)\n\n"
            if let note = highlight.note, !note.isEmpty {
                output += "Note: \(note)\n\n"
            }
            output += "---\n\n"
        }
        
        return output
    }
}
