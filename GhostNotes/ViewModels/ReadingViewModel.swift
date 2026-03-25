import Foundation
import SwiftUI

@MainActor
@Observable
class ReadingViewModel {
    var article: Article
    var fontSize: FontSize = .medium
    var readingTheme: ReadingTheme = .dark
    var isLoading = false
    var highlights: [Highlight] = []
    var bookmarks: [Bookmark] = []
    var selectedText: String = ""
    var showingHighlightPicker = false
    var showingBookmarkSheet = false
    var selectedBookmarkLabel = ""
    
    enum FontSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var size: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 18
            case .large: return 22
            }
        }
    }
    
    enum ReadingTheme: String, CaseIterable {
        case dark = "Dark"
        case light = "Light"
        case sepia = "Sepia"
        
        var backgroundColor: Color {
            switch self {
            case .dark: return Color(hex: "0A0A0F")
            case .light: return Color(hex: "F5F5F7")
            case .sepia: return Color(hex: "F4ECD8")
            }
        }
        
        var textColor: Color {
            switch self {
            case .dark: return Color(hex: "E5E5E7")
            case .light: return Color(hex: "1C1C1E")
            case .sepia: return Color(hex: "3D3426")
            }
        }
    }
    
    init(article: Article) {
        self.article = article
        loadHighlightsAndBookmarks()
    }
    
    func loadHighlightsAndBookmarks() {
        do {
            highlights = try DatabaseService.shared.fetchHighlights(forArticle: article.id)
            bookmarks = try DatabaseService.shared.fetchBookmarks(forArticle: article.id)
        } catch {
            print("Failed to load highlights/bookmarks: \(error)")
        }
    }
    
    func markAsRead() async {
        var updated = article
        updated.isRead = true
        updated.readAt = Date()
        updated.readingProgress = 1.0
        do {
            try DatabaseService.shared.updateArticle(updated)
            article = updated
            // Update streak
            var streak = try DatabaseService.shared.fetchStreak()
            streak.onArticleRead()
            try DatabaseService.shared.saveStreak(streak)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }

    func updateProgress(_ progress: Double) async {
        var updated = article
        updated.readingProgress = progress
        if progress >= 0.9 {
            updated.isRead = true
            updated.readAt = Date()
        }
        do {
            try DatabaseService.shared.updateArticle(updated)
            article = updated
        } catch {
            print("Failed to update progress: \(error)")
        }
    }
    
    func addHighlight(text: String, color: HighlightColor) async {
        let highlight = Highlight(articleId: article.id, text: text, color: color)
        do {
            try DatabaseService.shared.insertHighlight(highlight)
            highlights.insert(highlight, at: 0)
        } catch {
            print("Failed to save highlight: \(error)")
        }
    }
    
    func deleteHighlight(_ highlight: Highlight) async {
        do {
            try DatabaseService.shared.deleteHighlight(highlight)
            highlights.removeAll { $0.id == highlight.id }
        } catch {
            print("Failed to delete highlight: \(error)")
        }
    }
    
    func addBookmark(label: String, position: Double) async {
        let bookmark = Bookmark(articleId: article.id, label: label, scrollPosition: position)
        do {
            try DatabaseService.shared.insertBookmark(bookmark)
            bookmarks.append(bookmark)
            bookmarks.sort { $0.scrollPosition < $1.scrollPosition }
        } catch {
            print("Failed to save bookmark: \(error)")
        }
    }
    
    func deleteBookmark(_ bookmark: Bookmark) async {
        do {
            try DatabaseService.shared.deleteBookmark(bookmark)
            bookmarks.removeAll { $0.id == bookmark.id }
        } catch {
            print("Failed to delete bookmark: \(error)")
        }
    }
}

