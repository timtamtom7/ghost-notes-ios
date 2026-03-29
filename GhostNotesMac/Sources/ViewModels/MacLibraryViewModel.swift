import Foundation
import SwiftUI

@MainActor
@Observable
class MacLibraryViewModel {
    var articles: [Article] = []
    var archivedArticles: [Article] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var selectedFilter: MacFilterOption = .all
    var selectedArticle: Article?

    var filteredArticles: [Article] {
        var result: [Article]

        switch selectedFilter {
        case .all:
            result = articles.filter { !$0.isArchived }
        case .unread:
            result = articles.filter { !$0.isRead && !$0.isArchived }
        case .archived:
            result = archivedArticles
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.domain.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var unreadCount: Int {
        articles.filter { !$0.isRead && !$0.isArchived }.count
    }

    init() {}

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            articles = try DatabaseService.shared.fetchAllArticles()
            archivedArticles = try DatabaseService.shared.fetchArchivedArticles()
        } catch {
            errorMessage = "Failed to load articles."
        }
        isLoading = false
    }

    func addArticle(url: String) async {
        guard !url.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        // Deduplicate by URL
        let normalized = url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if articles.contains(where: { $0.url.lowercased() == normalized }) {
            errorMessage = "This article is already saved."
            isLoading = false
            return
        }

        do {
            let article = await ArticleService.shared.processURL(url)
            try DatabaseService.shared.insertArticle(article)
            articles.insert(article, at: 0)
        } catch {
            errorMessage = "Failed to save article."
        }
        isLoading = false
    }

    func deleteArticle(_ article: Article) async {
        do {
            try DatabaseService.shared.deleteArticle(article)
            articles.removeAll { $0.id == article.id }
            archivedArticles.removeAll { $0.id == article.id }
            if selectedArticle?.id == article.id {
                selectedArticle = nil
            }
        } catch {
            errorMessage = "Failed to delete."
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
            if selectedArticle?.id == article.id {
                selectedArticle = nil
            }
        } catch {
            errorMessage = "Failed to archive."
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
            } else if let index = archivedArticles.firstIndex(where: { $0.id == article.id }) {
                archivedArticles[index] = updated
            }
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
        } catch {
            errorMessage = "Failed to restore."
        }
    }

    func selectArticle(_ article: Article) {
        selectedArticle = article
        if !article.isRead {
            Task { await markAsRead(article) }
        }
    }
}

enum MacFilterOption: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case archived = "Archived"
}
