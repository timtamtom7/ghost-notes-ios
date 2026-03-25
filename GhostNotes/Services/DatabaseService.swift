import Foundation

final class DatabaseService: @unchecked Sendable {
    static let shared = DatabaseService()
    
    private let articlesKey = "ghost_notes_articles"
    private let collectionsKey = "ghost_notes_collections"
    
    private var userDefaults: UserDefaults {
        UserDefaults.standard
    }
    
    private init() {}
    
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
}
