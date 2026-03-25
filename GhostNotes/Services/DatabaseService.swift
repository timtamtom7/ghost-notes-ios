import Foundation

final class DatabaseService: @unchecked Sendable {
    static let shared = DatabaseService()

    private let articlesKey = "ghost_notes_articles"
    private let collectionsKey = "ghost_notes_collections"
    private let sharedArticlesKey = "shared_articles"  // R5: App Group shared articles from share extension
    private let importedIdsKey = "imported_shared_article_ids"  // Track already-imported share extension articles

    // R5: Use App Group UserDefaults so share extension and main app share storage
    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: "group.com.tomalabs.ghostnotes") ?? UserDefaults.standard
    }

    private init() {
        // R5: On init, import any new articles from share extension App Group
        importSharedArticles()
    }

    // MARK: - R5: Share Extension Sync
    private func importSharedArticles() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.tomalabs.ghostnotes"),
              let data = sharedDefaults.data(forKey: sharedArticlesKey),
              let sharedArticles = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return
        }

        let importedIds = userDefaults.stringArray(forKey: importedIdsKey) ?? []

        for articleDict in sharedArticles {
            guard let idString = articleDict["id"] as? String,
                  !importedIds.contains(idString) else { continue }

            let article = Article(
                id: UUID(uuidString: idString) ?? UUID(),
                url: articleDict["url"] as? String ?? "",
                title: articleDict["title"] as? String ?? "",
                domain: articleDict["domain"] as? String ?? "",
                articleDescription: articleDict["articleDescription"] as? String ?? "",
                bodyContent: articleDict["bodyContent"] as? String ?? "",
                readingTimeMinutes: articleDict["readingTimeMinutes"] as? Int ?? 5,
                isRead: false,
                isArchived: false,
                collectionName: nil,
                savedAt: Date(timeIntervalSince1970: articleDict["savedAt"] as? TimeInterval ?? Date().timeIntervalSince1970),
                readAt: nil,
                readingProgress: 0
            )

            do {
                try insertArticle(article)
                var ids = importedIds
                ids.append(idString)
                userDefaults.set(ids, forKey: importedIdsKey)
            } catch {
                print("Failed to import shared article: \(error)")
            }
        }
    }


    
    // MARK: - Articles
    
    func insertArticle(_ article: Article) throws {
        var articles = try fetchAllArticles()
        articles.insert(article, at: 0)
        try saveArticles(articles)
    }
    
    func fetchAllArticles() throws -> [Article] {
        guard let data = userDefaults.data(forKey: articlesKey) else { return [] }
        let decoder = JSONDecoder()
        let all = try decoder.decode([Article].self, from: data)
        return all.filter { !$0.isArchived }.sorted { $0.savedAt > $1.savedAt }
    }
    
    func fetchArchivedArticles() throws -> [Article] {
        guard let data = userDefaults.data(forKey: articlesKey) else { return [] }
        let decoder = JSONDecoder()
        let all = try decoder.decode([Article].self, from: data)
        return all.filter { $0.isArchived }.sorted { ($0.readAt ?? Date.distantPast) > ($1.readAt ?? Date.distantPast) }
    }
    
    func updateArticle(_ article: Article) throws {
        var articles = try fetchAllArticlesIncludingArchived()
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index] = article
            try saveArticles(articles)
        }
    }
    
    private func fetchAllArticlesIncludingArchived() throws -> [Article] {
        guard let data = userDefaults.data(forKey: articlesKey) else { return [] }
        let decoder = JSONDecoder()
        return try decoder.decode([Article].self, from: data)
    }
    
    func deleteArticle(_ article: Article) throws {
        var articles = try fetchAllArticlesIncludingArchived()
        articles.removeAll { $0.id == article.id }
        try saveArticles(articles)
    }
    
    private func saveArticles(_ articles: [Article]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(articles)
        userDefaults.set(data, forKey: articlesKey)
    }
    
    func searchArticles(query: String) throws -> [Article] {
        let all = try fetchAllArticlesIncludingArchived()
        let lowercased = query.lowercased()
        return all.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.domain.lowercased().contains(lowercased) ||
            $0.articleDescription.lowercased().contains(lowercased
            )
        }.sorted { $0.savedAt > $1.savedAt }
    }
    
    // MARK: - Collections
    
    func insertCollection(_ collection: Collection) throws {
        var collections = try fetchAllCollections()
        collections.insert(collection, at: 0)
        try saveCollections(collections)
    }
    
    func fetchAllCollections() throws -> [Collection] {
        guard let data = userDefaults.data(forKey: collectionsKey) else { return [] }
        let decoder = JSONDecoder()
        return try decoder.decode([Collection].self, from: data)
    }
    
    private func saveCollections(_ collections: [Collection]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(collections)
        userDefaults.set(data, forKey: collectionsKey)
    }
    
    func deleteCollection(_ collection: Collection) throws {
        var collections = try fetchAllCollections()
        collections.removeAll { $0.id == collection.id }
        try saveCollections(collections)
    }
    
    // MARK: - Stats
    
    func fetchStats() throws -> ReadingStats {
        let all = try fetchAllArticlesIncludingArchived()
        let total = all.count
        let read = all.filter { $0.isRead }.count
        let archived = all.filter { $0.isArchived }.count
        let totalTime = all.reduce(0) { $0 + $1.readingTimeMinutes }
        return ReadingStats(totalSaved: total, totalRead: read, totalArchived: archived, totalReadingTimeMinutes: totalTime)
    }
    
    // MARK: - R7: Highlights
    
    private let highlightsKey = "ghost_notes_highlights"
    
    func insertHighlight(_ highlight: Highlight) throws {
        var highlights = try fetchHighlights()
        highlights.insert(highlight, at: 0)
        try saveHighlights(highlights)
    }
    
    func fetchHighlights(forArticle articleId: UUID? = nil) throws -> [Highlight] {
        guard let data = userDefaults.data(forKey: highlightsKey) else { return [] }
        let decoder = JSONDecoder()
        let all = try decoder.decode([Highlight].self, from: data)
        if let articleId = articleId {
            return all.filter { $0.articleId == articleId }.sorted { $0.selectedAt > $1.selectedAt }
        }
        return all.sorted { $0.selectedAt > $1.selectedAt }
    }
    
    func updateHighlight(_ highlight: Highlight) throws {
        var highlights = try fetchHighlights()
        if let index = highlights.firstIndex(where: { $0.id == highlight.id }) {
            highlights[index] = highlight
            try saveHighlights(highlights)
        }
    }
    
    func deleteHighlight(_ highlight: Highlight) throws {
        var highlights = try fetchHighlights()
        highlights.removeAll { $0.id == highlight.id }
        try saveHighlights(highlights)
    }
    
    private func saveHighlights(_ highlights: [Highlight]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(highlights)
        userDefaults.set(data, forKey: highlightsKey)
    }
    
    // MARK: - R7: Bookmarks
    
    private let bookmarksKey = "ghost_notes_bookmarks"
    
    func insertBookmark(_ bookmark: Bookmark) throws {
        var bookmarks = try fetchBookmarks()
        bookmarks.insert(bookmark, at: 0)
        try saveBookmarks(bookmarks)
    }
    
    func fetchBookmarks(forArticle articleId: UUID? = nil) throws -> [Bookmark] {
        guard let data = userDefaults.data(forKey: bookmarksKey) else { return [] }
        let decoder = JSONDecoder()
        let all = try decoder.decode([Bookmark].self, from: data)
        if let articleId = articleId {
            return all.filter { $0.articleId == articleId }.sorted { $0.scrollPosition < $1.scrollPosition }
        }
        return all.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteBookmark(_ bookmark: Bookmark) throws {
        var bookmarks = try fetchBookmarks()
        bookmarks.removeAll { $0.id == bookmark.id }
        try saveBookmarks(bookmarks)
    }
    
    private func saveBookmarks(_ bookmarks: [Bookmark]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(bookmarks)
        userDefaults.set(data, forKey: bookmarksKey)
    }
    
    // MARK: - R7: Reading Streaks
    
    private let streakKey = "ghost_notes_streak"
    
    func fetchStreak() throws -> ReadingStreak {
        guard let data = userDefaults.data(forKey: streakKey) else { return ReadingStreak() }
        let decoder = JSONDecoder()
        return try decoder.decode(ReadingStreak.self, from: data)
    }
    
    func saveStreak(_ streak: ReadingStreak) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(streak)
        userDefaults.set(data, forKey: streakKey)
    }
    
    // MARK: - R7: Full-text Search (searches article body content too)
    
    func searchArticlesFullText(query: String) throws -> [Article] {
        let all = try fetchAllArticlesIncludingArchived()
        let lowercased = query.lowercased()
        return all.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.domain.lowercased().contains(lowercased) ||
            $0.articleDescription.lowercased().contains(lowercased) ||
            $0.bodyContent.lowercased().contains(lowercased)
        }.sorted { $0.savedAt > $1.savedAt }
    }
}
