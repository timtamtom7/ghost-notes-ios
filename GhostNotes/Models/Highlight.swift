import Foundation

/// A highlighted passage within an article
struct Highlight: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let articleId: UUID
    var text: String
    var note: String?  // User's optional note about this highlight
    var color: HighlightColor
    var selectedAt: Date
    var chapterRef: String?  // Optional chapter/section reference
    
    init(
        id: UUID = UUID(),
        articleId: UUID,
        text: String,
        note: String? = nil,
        color: HighlightColor = .primary,
        selectedAt: Date = Date(),
        chapterRef: String? = nil
    ) {
        self.id = id
        self.articleId = articleId
        self.text = text
        self.note = note
        self.color = color
        self.selectedAt = selectedAt
        self.chapterRef = chapterRef
    }
}

enum HighlightColor: String, Codable, CaseIterable {
    case primary = "Purple"
    case gold = "Gold"
    case rose = "Rose"
    case teal = "Teal"
    
    var hex: String {
        switch self {
        case .primary: return "7B6CF6"
        case .gold: return "F5A623"
        case .rose: return "FF6B6B"
        case .teal: return "00D4AA"
        }
    }
}

/// A bookmark within an article at a specific scroll position
struct Bookmark: Identifiable, Codable, Equatable {
    let id: UUID
    let articleId: UUID
    var label: String
    var scrollPosition: Double  // 0.0 to 1.0
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        articleId: UUID,
        label: String = "Bookmark",
        scrollPosition: Double = 0.0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.articleId = articleId
        self.label = label
        self.scrollPosition = scrollPosition
        self.createdAt = createdAt
    }
}

/// Reading streak data
struct ReadingStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastReadDate: Date?
    var totalDaysRead: Int
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, lastReadDate: Date? = nil, totalDaysRead: Int = 0) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastReadDate = lastReadDate
        self.totalDaysRead = totalDaysRead
    }
    
    mutating func onArticleRead() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastRead = lastReadDate {
            let lastReadDay = Calendar.current.startOfDay(for: lastRead)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastReadDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day — increment streak
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken — reset
                currentStreak = 1
            }
            // daysDiff == 0 means same day, don't change streak
        } else {
            // First read ever
            currentStreak = 1
            totalDaysRead = 1
        }
        
        longestStreak = max(longestStreak, currentStreak)
        lastReadDate = Date()
        totalDaysRead += 1
    }
}

/// Weekly reading stats for enhanced analytics
struct WeeklyStats: Codable {
    var weekOf: Date
    var articlesRead: Int
    var articlesSaved: Int
    var minutesRead: Int
    var highlightsCreated: Int
    var streaksActive: Int  // Days with at least one read
    
    init(weekOf: Date = Date(), articlesRead: Int = 0, articlesSaved: Int = 0, minutesRead: Int = 0, highlightsCreated: Int = 0, streaksActive: Int = 0) {
        self.weekOf = weekOf
        self.articlesRead = articlesRead
        self.articlesSaved = articlesSaved
        self.minutesRead = minutesRead
        self.highlightsCreated = highlightsCreated
        self.streaksActive = streaksActive
    }
    
    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: weekOf)
    }
}
