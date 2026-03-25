import Foundation
import SQLite

class ArticleStore: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var db: Connection?

    // Table definition
    private let articlesTable = Table("articles")
    private let colId = Expression<String>("id")
    private let colURL = Expression<String>("url")
    private let colTitle = Expression<String>("title")
    private let colDomain = Expression<String>("domain")
    private let colFaviconURL = Expression<String?>("favicon_url")
    private let colContent = Expression<String?>("content")
    private let colSummary = Expression<String?>("summary")
    private let colEstimatedReadingTime = Expression<Int>("estimated_reading_time")
    private let colDateAdded = Expression<Double>("date_added")
    private let colStatus = Expression<String>("status")

    init() {
        setupDatabase()
        loadArticles()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            db = try Connection("\(path)/ghostnotes.sqlite3")
            try createTable()
        } catch {
            errorMessage = "Database setup failed: \(error.localizedDescription)"
        }
    }

    private func createTable() throws {
        try db?.run(articlesTable.create(ifNotExists: true) { t in
            t.column(colId, primaryKey: true)
            t.column(colURL)
            t.column(colTitle)
            t.column(colDomain)
            t.column(colFaviconURL)
            t.column(colContent)
            t.column(colSummary)
            t.column(colEstimatedReadingTime)
            t.column(colDateAdded)
            t.column(colStatus)
        })
    }

    func loadArticles() {
        guard let db = db else { return }
        do {
            var loaded: [Article] = []
            for row in try db.prepare(articlesTable.order(colDateAdded.desc)) {
                let article = Article(
                    id: UUID(uuidString: row[colId]) ?? UUID(),
                    url: row[colURL],
                    title: row[colTitle],
                    domain: row[colDomain],
                    faviconURL: row[colFaviconURL],
                    content: row[colContent],
                    summary: row[colSummary],
                    estimatedReadingTime: row[colEstimatedReadingTime],
                    dateAdded: Date(timeIntervalSince1970: row[colDateAdded]),
                    status: ArticleStatus(rawValue: row[colStatus]) ?? .unread
                )
                loaded.append(article)
            }
            DispatchQueue.main.async {
                self.articles = loaded
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load articles: \(error.localizedDescription)"
            }
        }
    }

    func addArticle(url urlString: String) async throws -> Article {
        guard let url = URL(string: urlString) else {
            throw ArticleStoreError.invalidURL
        }

        let domain = url.host ?? urlString
        let title = url.host ?? "Untitled Article"
        let wordCount = 800
        let readingTime = max(1, wordCount / 200)

        let article = Article(
            url: urlString,
            title: title,
            domain: domain,
            estimatedReadingTime: readingTime,
            dateAdded: Date()
        )

        try await saveArticle(article)
        await fetchAndUpdateArticleContent(article)
        return article
    }

    private func saveArticle(_ article: Article) async throws {
        guard let db = db else { throw ArticleStoreError.databaseNotInitialized }

        let insert = articlesTable.insert(
            colId <- article.id.uuidString,
            colURL <- article.url,
            colTitle <- article.title,
            colDomain <- article.domain,
            colFaviconURL <- article.faviconURL,
            colContent <- article.content,
            colSummary <- article.summary,
            colEstimatedReadingTime <- article.estimatedReadingTime,
            colDateAdded <- article.dateAdded.timeIntervalSince1970,
            colStatus <- article.status.rawValue
        )

        try db.run(insert)
        await MainActor.run {
            self.articles.insert(article, at: 0)
        }
    }

    private func fetchAndUpdateArticleContent(_ article: Article) async {
        guard let url = URL(string: article.url) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let html = String(data: data, encoding: .utf8) {
                let content = extractTextFromHTML(html)
                let summary = generateMockSummary(from: content)
                var updated = article
                updated.content = content
                updated.summary = summary
                updated.estimatedReadingTime = max(1, content.split(separator: " ").count / 200)
                await updateArticle(updated)
            }
        } catch {
            // Silently fail for now
        }
    }

    private func extractTextFromHTML(_ html: String) -> String {
        var text = html
        let patterns = [
            "<script[^>]*>[\\s\\S]*?</script>",
            "<style[^>]*>[\\s\\S]*?</style>",
            "<[^>]+>",
            "&nbsp;",
            "&amp;",
            "&lt;",
            "&gt;",
            "\\s+"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                text = regex.stringByReplacingMatches(
                    in: text, range: NSRange(text.startIndex..., in: text),
                    withTemplate: " "
                )
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateMockSummary(from content: String) -> String {
        let sentences = content.components(separatedBy: ". ")
        let keySentences = sentences.prefix(3).map { $0.trimmingCharacters(in: .whitespaces) }
        let summaryItems = keySentences.map { "• \($0)." }
        return summaryItems.joined(separator: "\n")
    }

    func updateArticle(_ article: Article) async {
        guard let db = db else { return }
        let target = articlesTable.filter(colId == article.id.uuidString)
        do {
            try db.run(target.update(
                colTitle <- article.title,
                colFaviconURL <- article.faviconURL,
                colContent <- article.content,
                colSummary <- article.summary,
                colEstimatedReadingTime <- article.estimatedReadingTime,
                colStatus <- article.status.rawValue
            ))
            await MainActor.run {
                if let index = self.articles.firstIndex(where: { $0.id == article.id }) {
                    self.articles[index] = article
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update article: \(error.localizedDescription)"
            }
        }
    }

    func deleteArticle(_ article: Article) {
        guard let db = db else { return }
        let target = articlesTable.filter(colId == article.id.uuidString)
        do {
            try db.run(target.delete())
            articles.removeAll { $0.id == article.id }
        } catch {
            errorMessage = "Failed to delete article: \(error.localizedDescription)"
        }
    }

    func archiveArticle(_ article: Article) async {
        var updated = article
        updated.status = .archived
        await updateArticle(updated)
    }

    func markAsRead(_ article: Article) async {
        var updated = article
        updated.status = .read
        await updateArticle(updated)
    }

    func regenerateSummary(for article: Article) async {
        guard let content = article.content else { return }
        let summary = generateMockSummary(from: content)
        var updated = article
        updated.summary = summary
        await updateArticle(updated)
    }

    func filteredArticles(filter: FilterOption, searchText: String) -> [Article] {
        var result = articles

        switch filter {
        case .all:
            result = result.filter { $0.status != .archived }
        case .unread:
            result = result.filter { $0.status == .unread }
        case .archived:
            result = result.filter { $0.status == .archived }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.domain.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }
}

enum ArticleStoreError: LocalizedError {
    case invalidURL
    case databaseNotInitialized
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .databaseNotInitialized: return "Database not initialized"
        case .fetchFailed: return "Failed to fetch article"
        }
    }
}
