import Foundation
import NaturalLanguage

final class ArticleService: @unchecked Sendable {
    static let shared = ArticleService()
    
    private init() {}
    
    func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
    
    func estimateReadingTime(text: String) -> Int {
        let wordCount = text.split(separator: " ").count
        let wordsPerMinute = 238
        return max(1, wordCount / wordsPerMinute)
    }
    
    func summarize(text: String, maxLength: Int = 150) async -> String {
        let words = text.split(separator: " ").map(String.init)
        guard words.count > 20 else { return String(text.prefix(maxLength)) }
        
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.split(separator: " ").count > 3 }
        
        var sentenceScores: [(String, Double)] = []
        
        let importantKeywords = ["key", "important", "significant", "main", "核心", "重点", "critical", "essential", "primary", "discover", "find", "reveal", "show", "demonstrate", "prove", "according", "report", "study", "research"]
        
        for sentence in sentences {
            let lowercased = sentence.lowercased()
            var score: Double = 0
            
            for keyword in importantKeywords {
                if lowercased.contains(keyword) {
                    score += 1.5
                }
            }
            
            let wordCount = sentence.split(separator: " ").count
            if wordCount > 5 && wordCount < 40 {
                score += 1.0
            }
            
            sentenceScores.append((sentence, score))
        }
        
        sentenceScores.sort { $0.1 > $1.1 }
        
        var summary: [String] = []
        var currentLength = 0
        
        for (sentence, _) in sentenceScores {
            if currentLength + sentence.count > maxLength && !summary.isEmpty {
                break
            }
            summary.append(sentence)
            currentLength += sentence.count
        }
        
        let result = summary.joined(separator: ". ")
        return result.isEmpty ? String(text.prefix(maxLength)) + "..." : result + "."
    }
    
    func processURL(_ urlString: String) async -> Article {
        let domain = extractDomain(from: urlString)
        
        let placeholderText = """
        This is a placeholder article body. In a real implementation, 
        this would be fetched from the URL using a content parser 
        like Mercury Parser or Readability. The AI would then summarize 
        the actual content.
        """
        
        let readingTime = estimateReadingTime(text: placeholderText)
        let summary = await summarize(text: placeholderText)
        
        return Article(
            url: urlString,
            title: domain.capitalized,
            domain: domain,
            articleDescription: summary,
            readingTimeMinutes: readingTime
        )
    }
}
