import Foundation
import SwiftUI
import CoreHaptics
import UserNotifications

@MainActor
@Observable
class LibraryViewModel {
    var articles: [Article] = []
    var archivedArticles: [Article] = []
    var collections: [Collection] = []
    var stats: ReadingStats = ReadingStats()
    var streak: ReadingStreak = ReadingStreak()
    var highlights: [Highlight] = []
    var bookmarks: [Bookmark] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""
    var showingAddArticle = false
    var showingCollections = false
    var showingStats = false
    var selectedTab: Tab = .library
    var selectedHighlightArticle: Article?
    
    // R7: Search filters
    var filterReadStatus: FilterStatus = .all
    var filterDomain: String = ""
    
    enum FilterStatus {
        case all, unread, read
    }
    
    enum Tab {
        case library, archive, collections, highlights
    }
    
    private var hapticEngine: CHHapticEngine?
    
    init() {
        setupHaptics()
        requestNotificationPermission()
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                Task { @MainActor in
                    self.scheduleRetentionNudge()
                }
            }
        }
    }
    
    func scheduleRetentionNudge() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Your reading list is waiting"
        content.body = "You have \(articles.count) unread articles. Perfect time for a deep dive."
        content.sound = .default
        
        // Schedule for 3 days from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 24 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: "retention_nudge", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func playHaptic(_ style: HapticStyle) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events: [CHHapticEvent] = []
        
        switch style {
        case .light:
            events = [CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0)]
        case .medium:
            events = [CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ], relativeTime: 0)]
        case .success:
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ], relativeTime: 0.1)
            ]
        case .error:
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ], relativeTime: 0.15)
            ]
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptic error: \(error)")
        }
    }
    
    enum HapticStyle {
        case light, medium, success, error
    }
    
    var filteredArticles: [Article] {
        var result = articles
        
        switch filterReadStatus {
        case .unread:
            result = result.filter { !$0.isRead }
        case .read:
            result = result.filter { $0.isRead }
        case .all:
            break
        }
        
        if !filterDomain.isEmpty {
            result = result.filter { $0.domain.lowercased().contains(filterDomain.lowercased()) }
        }
        
        return result
    }
    
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
            errorMessage = "Failed to load articles. Pull to refresh."
        }
        isLoading = false
    }
    
    func addArticle(url: String) async {
        guard !url.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        // R6: URL deduplication — prevent saving the same article twice
        let normalizedURL = url.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if articles.contains(where: { $0.url.lowercased() == normalizedURL }) {
            errorMessage = "This article is already in your library."
            playHaptic(.error)
            isLoading = false
            return
        }

        do {
            let article = await ArticleService.shared.processURL(url)
            try DatabaseService.shared.insertArticle(article)
            articles.insert(article, at: 0)
            stats = try DatabaseService.shared.fetchStats()
            playHaptic(.success)
        } catch {
            errorMessage = "Failed to save article. Check the URL and try again."
            playHaptic(.error)
        }
        isLoading = false
    }

    func deleteArticle(_ article: Article) async {
        do {
            try DatabaseService.shared.deleteArticle(article)
            articles.removeAll { $0.id == article.id }
            archivedArticles.removeAll { $0.id == article.id }
            stats = try DatabaseService.shared.fetchStats()
            playHaptic(.medium)
        } catch {
            errorMessage = "Failed to delete article."
            playHaptic(.error)
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
            playHaptic(.success)
        } catch {
            errorMessage = "Failed to archive article."
            playHaptic(.error)
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
            playHaptic(.light)
        } catch {
            errorMessage = "Failed to mark as read."
            playHaptic(.error)
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
            stats = try DatabaseService.shared.fetchStats()
            playHaptic(.light)
        } catch {
            errorMessage = "Failed to mark as unread."
            playHaptic(.error)
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
            playHaptic(.success)
        } catch {
            errorMessage = "Failed to restore article."
            playHaptic(.error)
        }
    }

    func addCollection(name: String) async {
        guard !name.isEmpty else { return }
        let collection = Collection(name: name)
        do {
            try DatabaseService.shared.insertCollection(collection)
            collections.append(collection)
            playHaptic(.success)
        } catch {
            errorMessage = "Failed to create collection."
            playHaptic(.error)
        }
    }

    func deleteCollection(_ collection: Collection) async {
        do {
            try DatabaseService.shared.deleteCollection(collection)
            collections.removeAll { $0.id == collection.id }
            playHaptic(.medium)
        } catch {
            errorMessage = "Failed to delete collection."
            playHaptic(.error)
        }
    }

    func search() async {
        guard !searchQuery.isEmpty else {
            await load()
            return
        }
        isLoading = true
        do {
            // R7: Full-text search including article body content
            articles = try DatabaseService.shared.searchArticlesFullText(query: searchQuery)
        } catch {
            errorMessage = "Search failed."
        }
        isLoading = false
    }
    
    // MARK: - R7: Highlights
    
    func addHighlight(text: String, articleId: UUID, color: HighlightColor = .primary, note: String? = nil) async {
        let highlight = Highlight(articleId: articleId, text: text, note: note, color: color)
        do {
            try DatabaseService.shared.insertHighlight(highlight)
            highlights.insert(highlight, at: 0)
            playHaptic(.success)
        } catch {
            errorMessage = "Failed to save highlight."
            playHaptic(.error)
        }
    }
    
    func deleteHighlight(_ highlight: Highlight) async {
        do {
            try DatabaseService.shared.deleteHighlight(highlight)
            highlights.removeAll { $0.id == highlight.id }
            playHaptic(.medium)
        } catch {
            errorMessage = "Failed to delete highlight."
            playHaptic(.error)
        }
    }
    
    func highlightsForArticle(_ articleId: UUID) -> [Highlight] {
        highlights.filter { $0.articleId == articleId }
    }
    
    // MARK: - R7: Bookmarks
    
    func addBookmark(articleId: UUID, label: String, position: Double) async {
        let bookmark = Bookmark(articleId: articleId, label: label, scrollPosition: position)
        do {
            try DatabaseService.shared.insertBookmark(bookmark)
            bookmarks.insert(bookmark, at: 0)
            playHaptic(.success)
        } catch {
            errorMessage = "Failed to save bookmark."
            playHaptic(.error)
        }
    }
    
    func deleteBookmark(_ bookmark: Bookmark) async {
        do {
            try DatabaseService.shared.deleteBookmark(bookmark)
            bookmarks.removeAll { $0.id == bookmark.id }
            playHaptic(.medium)
        } catch {
            errorMessage = "Failed to delete bookmark."
            playHaptic(.error)
        }
    }
    
    func bookmarksForArticle(_ articleId: UUID) -> [Bookmark] {
        bookmarks.filter { $0.articleId == articleId }
    }
    
    // MARK: - R7: Reading Streak
    
    func recordRead() async {
        var updatedStreak = streak
        updatedStreak.onArticleRead()
        do {
            try DatabaseService.shared.saveStreak(updatedStreak)
            streak = updatedStreak
        } catch {
            print("Failed to save streak: \(error)")
        }
    }
}
