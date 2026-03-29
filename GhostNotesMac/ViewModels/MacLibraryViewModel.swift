import Foundation
import SwiftUI

@MainActor
@Observable
class MacLibraryViewModel {
    var articles: [Article] = []
    var archivedArticles: [Article] = []
    var collections: [Collection] = []
    var stats: ReadingStats = ReadingStats()
    var streak: ReadingStreak = ReadingStreak()
    var highlights: [Highlight] = []
    var bookmarks: [Bookmark] = []
    var isLoading = false
    var errorMessage: String?
    var urlInput = ""

    private var hapticEngine: Any? = nil

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            articles = try DatabaseService.shared.fetchAllArticles()
            archivedArticles = try DatabaseService.shared.fetchArchivedArticles()
            collections = try DatabaseService.shared.fetchAllCollections()
            stats = try DatabaseService.shared.fetchStats()
            streak = try DatabaseService.shared.fetchStreak()
            highlights = try DatabaseService.shared.fetchHighlights()
            bookmarks = try DatabaseService.shared.fetchBookmarks()
        } catch {
            errorMessage = "Failed to load articles."
        }
        isLoading = false
    }

    func addArticleFromInput() async {
        guard !urlInput.isEmpty else { return }
        await addArticle(url: urlInput)
        urlInput = ""
    }

    func addArticle(url: String) async {
        guard !url.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        let normalizedURL = url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if articles.contains(where: { $0.url.lowercased() == normalizedURL }) {
            errorMessage = "This article is already in your library."
            isLoading = false
            return
        }

        do {
            let article = await ArticleService.shared.processURL(url)
            try DatabaseService.shared.insertArticle(article)
            articles.insert(article, at: 0)
            stats = try DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to save article. Check the URL and try again."
        }
        isLoading = false
    }

    func deleteArticle(_ article: Article) async {
        do {
            try DatabaseService.shared.deleteArticle(article)
            articles.removeAll { $0.id == article.id }
            archivedArticles.removeAll { $0.id == article.id }
            stats = try DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to delete article."
        }
    }

    func archiveArticle(_ article: Article) async {
        var updated = article
        updated.isArchived = true
        updated.readAt = Date()
        do {
            try DatabaseService.shared.updateArticle(updated)
            articles.removeAll { $0.id == article.id }
            archivedArticles.insert(updated, at: 0)
            stats = try DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to archive article."
        }
    }

    func markAsRead(_ article: Article) async {
        var updated = article
        updated.isRead = true
        updated.readAt = Date()
        do {
            try DatabaseService.shared.updateArticle(updated)
            if let index = articles.firstIndex(where: { $0.id == article.id }) {
                articles[index] = updated
            }
            stats = try DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to mark as read."
        }
    }

    func markAsUnread(_ article: Article) async {
        var updated = article
        updated.isRead = false
        do {
            try DatabaseService.shared.updateArticle(updated)
            if let index = articles.firstIndex(where: { $0.id == article.id }) {
                articles[index] = updated
            }
            stats = try DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to mark as unread."
        }
    }

    func unarchiveArticle(_ article: Article) async {
        var updated = article
        updated.isArchived = false
        do {
            try DatabaseService.shared.updateArticle(updated)
            archivedArticles.removeAll { $0.id == article.id }
            articles.insert(updated, at: 0)
            stats = try DatabaseService.shared.fetchStats()
        } catch {
            errorMessage = "Failed to restore article."
        }
    }

    func addCollection(name: String) async {
        guard !name.isEmpty else { return }
        let collection = Collection(name: name)
        do {
            try DatabaseService.shared.insertCollection(collection)
            collections.append(collection)
        } catch {
            errorMessage = "Failed to create collection."
        }
    }

    func deleteCollection(_ collection: Collection) async {
        do {
            try DatabaseService.shared.deleteCollection(collection)
            collections.removeAll { $0.id == collection.id }
        } catch {
            errorMessage = "Failed to delete collection."
        }
    }

    func deleteHighlight(_ highlight: Highlight) async {
        do {
            try DatabaseService.shared.deleteHighlight(highlight)
            highlights.removeAll { $0.id == highlight.id }
        } catch {
            errorMessage = "Failed to delete highlight."
        }
    }
}
