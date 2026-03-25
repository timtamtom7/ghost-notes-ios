import Foundation
import SwiftUI

@MainActor
@Observable
class LibraryViewModel {
    var articles: [Article] = []
    var archivedArticles: [Article] = []
    var collections: [Collection] = []
    var stats: ReadingStats = ReadingStats()
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""
    var showingAddArticle = false
    var showingCollections = false
    var showingStats = false
    var selectedTab: Tab = .library
    
    enum Tab {
        case library, archive, collections
    }
    
    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            articles = try await DatabaseService.shared.fetchAllArticles()
            archivedArticles = try await DatabaseService.shared.fetchArchivedArticles()
            collections = try await DatabaseService.shared.fetchAllCollections()
            stats = try await DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to load articles. Pull to refresh."
        }
        isLoading = false
    }
    
    func addArticle(url: String) async {
        guard !url.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let article = await ArticleService.shared.processURL(url)
            try await DatabaseService.shared.insertArticle(article)
            articles.insert(article, at: 0)
            stats = try await DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to save article. Check the URL and try again."
        }
        isLoading = false
    }
    
    func deleteArticle(_ article: Article) async {
        do {
            try await DatabaseService.shared.deleteArticle(article)
            articles.removeAll { $0.id == article.id }
            archivedArticles.removeAll { $0.id == article.id }
            stats = try await DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to delete article."
        }
    }
    
    func archiveArticle(_ article: Article) async {
        var updated = article
        updated.isArchived = true
        updated.readAt = Date()
        do {
            try await DatabaseService.shared.updateArticle(updated)
            articles.removeAll { $0.id == article.id }
            archivedArticles.insert(updated, at: 0)
            stats = try await DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to archive article."
        }
    }
    
    func markAsRead(_ article: Article) async {
        var updated = article
        updated.isRead = true
        updated.readAt = Date()
        do {
            try await DatabaseService.shared.updateArticle(updated)
            if let index = articles.firstIndex(where: { $0.id == article.id }) {
                articles[index] = updated
            }
            stats = try await DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to mark as read."
        }
    }
    
    func markAsUnread(_ article: Article) async {
        var updated = article
        updated.isRead = false
        do {
            try await DatabaseService.shared.updateArticle(updated)
            if let index = articles.firstIndex(where: { $0.id == article.id }) {
                articles[index] = updated
            } else if let index = archivedArticles.firstIndex(where: { $0.id == article.id }) {
                archivedArticles[index] = updated
            }
            stats = try await DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to mark as unread."
        }
    }
    
    func unarchiveArticle(_ article: Article) async {
        var updated = article
        updated.isArchived = false
        do {
            try await DatabaseService.shared.updateArticle(updated)
            archivedArticles.removeAll { $0.id == article.id }
            articles.insert(updated, at: 0)
            stats = try await DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to restore article."
        }
    }
    
    func addCollection(name: String) async {
        guard !name.isEmpty else { return }
        let collection = Collection(name: name)
        do {
            try await DatabaseService.shared.insertCollection(collection)
            collections.append(collection)
        } catch {
            errorMessage = "Failed to create collection."
        }
    }
    
    func deleteCollection(_ collection: Collection) async {
        do {
            try await DatabaseService.shared.deleteCollection(collection)
            collections.removeAll { $0.id == collection.id }
        } catch {
            errorMessage = "Failed to delete collection."
        }
    }
    
    func search() async {
        guard !searchQuery.isEmpty else {
            await load()
            return
        }
        isLoading = true
        do {
            articles = try await DatabaseService.shared.searchArticles(query: searchQuery)
        } catch {
            errorMessage = "Search failed."
        }
        isLoading = false
    }
}
