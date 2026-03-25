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
        
        let importantKeywords = ["key", "important", "significant", "main", "critical", "essential", "primary", "discover", "find", "reveal", "show", "demonstrate", "prove", "according", "report", "study", "research"]
        
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
    
    func extractTitleAndDescription(from html: String) -> (title: String, description: String) {
        var title = ""
        var description = ""
        
        // Extract title
        if let titleRange = html.range(of: "<title>"),
           let titleEndRange = html.range(of: "</title>") {
            title = String(html[titleRange.upperBound..<titleEndRange.lowerBound])
            title = title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract meta description
        let metaPatterns = [
            "<meta name=\"description\" content=\"([^\"]+)\"",
            "<meta property=\"og:description\" content=\"([^\"]+)\""
        ]
        
        for pattern in metaPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                description = String(html[range])
                break
            }
        }
        
        // Also try og:title if no proper title found
        if title.isEmpty {
            if let ogTitleRange = html.range(of: "<meta property=\"og:title\" content=\"([^\"]+)\"", options: .regularExpression),
               let regex = try? NSRegularExpression(pattern: "<meta property=\"og:title\" content=\"([^\"]+)\"", options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(ogTitleRange.lowerBound..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                title = String(html[range])
            }
        }
        
        return (title, description)
    }
    
    func extractMainContent(from html: String) -> String {
        // Simple content extraction - find the largest text block
        // Remove script, style, nav, footer, header
        var cleaned = html
        let removePatterns = [
            "<script[^>]*>[\\s\\S]*?</script>",
            "<style[^>]*>[\\s\\S]*?</style>",
            "<nav[^>]*>[\\s\\S]*?</nav>",
            "<footer[^>]*>[\\s\\S]*?</footer>",
            "<header[^>]*>[\\s\\S]*?</header>",
            "<aside[^>]*>[\\s\\S]*?</aside>"
        ]
        
        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
            }
        }
        
        // Remove all HTML tags
        cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        
        // Decode HTML entities
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
        cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "<")
        cleaned = cleaned.replacingOccurrences(of: "&gt;", with: ">")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")
        cleaned = cleaned.replacingOccurrences(of: "&#39;", with: "'")
        
        // Clean whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    func processURL(_ urlString: String) async -> Article {
        let domain = extractDomain(from: urlString)
        var title = domain.capitalized
        var articleDescription = ""
        var bodyText = ""
        
        guard let url = URL(string: urlString) else {
            return Article(url: urlString, title: title, domain: domain, articleDescription: articleDescription, readingTimeMinutes: 1)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                return Article(url: urlString, title: title, domain: domain, articleDescription: articleDescription, readingTimeMinutes: 1)
            }
            
            let (extractedTitle, extractedDesc) = extractTitleAndDescription(from: html)
            if !extractedTitle.isEmpty { title = extractedTitle }
            if !extractedDesc.isEmpty { articleDescription = extractedDesc }
            
            bodyText = extractMainContent(from: html)
            
        } catch {
            // URL fetch failed - use placeholder
        }
        
        if bodyText.isEmpty {
            bodyText = "Article content would be displayed here. In production, this would show the full article text fetched from \(domain)."
        }
        
        let readingTime = estimateReadingTime(text: bodyText)
        let summary = await summarize(text: bodyText)
        
        return Article(
            url: urlString,
            title: title,
            domain: domain,
            articleDescription: summary,
            readingTimeMinutes: readingTime
        )
    }
}
