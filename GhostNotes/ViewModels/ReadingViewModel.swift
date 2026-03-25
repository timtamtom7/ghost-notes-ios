import Foundation
import SwiftUI

@MainActor
@Observable
class ReadingViewModel {
    var article: Article
    var fontSize: FontSize = .medium
    var readingTheme: ReadingTheme = .dark
    var isLoading = false
    
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
    }
    
    func markAsRead() async {
        var updated = article
        updated.isRead = true
        updated.readAt = Date()
        updated.readingProgress = 1.0
        do {
            try await DatabaseService.shared.updateArticle(updated)
            article = updated
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
            try await DatabaseService.shared.updateArticle(updated)
            article = updated
        } catch {
            print("Failed to update progress: \(error)")
        }
    }
}

