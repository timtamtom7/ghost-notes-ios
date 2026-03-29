import Foundation
import NaturalLanguage

// MARK: - R11: AI Reading Intelligence

final class AISummarizationService: @unchecked Sendable {
    static let shared = AISummarizationService()

    private init() {}

    // MARK: - Public API

    /// Generate a full AI summary for an article.
    func summarize(_ article: Article) -> Summary {
        let text = article.bodyContent.isEmpty ? article.articleDescription : article.bodyContent
        let summaryText = generateSummaryText(from: text, maxSentences: 5)
        let insights = extractKeyInsights(from: article)

        return Summary(
            articleId: article.id,
            summaryText: summaryText,
            keyInsights: insights,
            readingMode: .full
        )
    }

    /// Extract condensed key insights for 3-Minute Mode.
    func extractKeyInsights(_ article: Article) -> [String] {
        let text = article.bodyContent.isEmpty ? article.articleDescription : article.bodyContent
        let sentences = splitIntoSentences(text)

        guard !sentences.isEmpty else { return [] }

        let scored = sentences.enumerated().map { (index, sentence) -> (String, Double) in
            (sentence, scoreSentence(sentence, position: index, total: sentences.count))
        }

        let top = scored
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0.0 }

        return top.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    /// Generate a 3-minute condensed summary.
    func generateThreeMinuteSummary(_ article: Article) -> Summary {
        let text = article.bodyContent.isEmpty ? article.articleDescription : article.bodyContent
        let keyInsights = extractKeyInsights(article)
        let summaryText = keyInsights.joined(separator: " ")

        return Summary(
            articleId: article.id,
            summaryText: summaryText.isEmpty ? "No content available." : summaryText,
            keyInsights: keyInsights,
            readingMode: .threeMinute
        )
    }

    // MARK: - Private Implementation

    private func generateSummaryText(from text: String, maxSentences: Int) -> String {
        let sentences = splitIntoSentences(text).filter { $0.split(separator: " ").count > 4 }
        guard !sentences.isEmpty else { return String(text.prefix(200)) }

        let scored = sentences.enumerated().map { (index, sentence) -> (String, Double) in
            (sentence, scoreSentence(sentence, position: index, total: sentences.count))
        }

        let top = scored
            .sorted { $0.1 > $1.1 }
            .prefix(maxSentences)
            .sorted { scoredSentence1, scoredSentence2 in
                // Restore original order
                let idx1 = sentences.firstIndex(of: scoredSentence1.0) ?? 0
                let idx2 = sentences.firstIndex(of: scoredSentence2.0) ?? 0
                return idx1 < idx2
            }
            .map { $0.0 }

        return top.joined(separator: ". ").trimmingCharacters(in: .whitespacesAndNewlines) + "."
    }

    private func extractKeyInsights(from article: Article) -> [String] {
        let text = article.bodyContent.isEmpty ? article.articleDescription : article.bodyContent

        // Use NLP entity extraction to find key topics
        var insights: [String] = []
        let entitySet = extractNamedEntities(text)
        insights.append(contentsOf: entitySet.prefix(3))

        // Extract sentences with strong signal keywords
        let sentences = splitIntoSentences(text)
        let signalKeywords = [
            "key finding", "significant", "important", "main point", "crucial",
            "discover", "reveal", "demonstrate", "evidence", "conclusion",
            "according to", "research shows", "study found", "report", "data"
        ]

        for sentence in sentences {
            let lower = sentence.lowercased()
            if signalKeywords.contains(where: { lower.contains($0) }) {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !insights.contains(trimmed) && insights.count < 5 {
                    insights.append(trimmed)
                }
            }
        }

        // Fill remaining slots with top-scored sentences
        if insights.count < 5 {
            let scored = sentences.enumerated().map { (index, sentence) in
                (sentence, scoreSentence(sentence, position: index, total: sentences.count))
            }
            for (sentence, _) in scored.sorted(by: { $0.1 > $1.1 }) {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !insights.contains(trimmed) && insights.count < 5 {
                    insights.append(trimmed)
                }
            }
        }

        return Array(insights.prefix(5))
    }

    private func extractNamedEntities(_ text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var entities: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .nameType, options: options) { tag, range in
            if let tag = tag, tag == .personalName || tag == .organizationName || tag == .placeName {
                let entity = String(text[range])
                if entity.split(separator: " ").count <= 4 && !entities.contains(entity) {
                    entities.append(entity)
                }
            }
            return true
        }

        return entities
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        let sentenceEnds = CharacterSet(charactersIn: ".!?")
        var sentences: [String] = []
        var current = ""

        for char in text {
            current.append(char)
            if sentenceEnds.contains(char.unicodeScalars.first!) {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    sentences.append(trimmed)
                }
                current = ""
            }
        }

        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return sentences
    }

    private func scoreSentence(_ sentence: String, position: Int, total: Int) -> Double {
        let lower = sentence.lowercased()
        var score: Double = 0

        // Position bonus: first and last sentences often carry key info
        if position == 0 { score += 2.0 }
        if position == total - 1 { score += 1.5 }

        // Recency bonus for early-middle sentences
        let earlyMiddle = total / 4
        if position > 0 && position <= earlyMiddle { score += 1.0 }

        // Keyword signal bonus
        let signals = [
            "important", "significant", "key", "main", "primary", "essential",
            "discover", "reveal", "show", "demonstrate", "prove", "evidence",
            "according", "report", "study", "research", "find", "conclusion",
            "result", "effect", "impact", "suggest", "indicates"
        ]

        for signal in signals {
            if lower.contains(signal) {
                score += 1.5
            }
        }

        // Length scoring: penalize very short or very long sentences
        let wordCount = sentence.split(separator: " ").count
        if wordCount < 5 { score -= 1.0 }
        if wordCount > 50 { score -= 0.5 }
        if wordCount >= 10 && wordCount <= 35 { score += 1.0 }

        // Penalize questions and exclamations (usually not key insights)
        if sentence.hasSuffix("?") || sentence.hasSuffix("!") { score -= 0.5 }

        return score
    }
}
