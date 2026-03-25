import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: UUID
    var url: String
    var title: String
    var domain: String
    var articleDescription: String
    var bodyContent: String  // R5: Offline reading — full article text saved locally
    var readingTimeMinutes: Int
    var isRead: Bool
    var isArchived: Bool
    var collectionName: String?
    var savedAt: Date
    var readAt: Date?
    var readingProgress: Double

    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        domain: String = "",
        articleDescription: String = "",
        bodyContent: String = "",
        readingTimeMinutes: Int = 0,
        isRead: Bool = false,
        isArchived: Bool = false,
        collectionName: String? = nil,
        savedAt: Date = Date(),
        readAt: Date? = nil,
        readingProgress: Double = 0
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.domain = domain
        self.articleDescription = articleDescription
        self.bodyContent = bodyContent
        self.readingTimeMinutes = readingTimeMinutes
        self.isRead = isRead
        self.isArchived = isArchived
        self.collectionName = collectionName
        self.savedAt = savedAt
        self.readAt = readAt
        self.readingProgress = readingProgress
    }
}

struct Collection: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var articleCount: Int
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, articleCount: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.articleCount = articleCount
        self.createdAt = createdAt
    }
}

struct ReadingStats: Codable {
    var totalSaved: Int
    var totalRead: Int
    var totalArchived: Int
    var totalReadingTimeMinutes: Int
    
    init(totalSaved: Int = 0, totalRead: Int = 0, totalArchived: Int = 0, totalReadingTimeMinutes: Int = 0) {
        self.totalSaved = totalSaved
        self.totalRead = totalRead
        self.totalArchived = totalArchived
        self.totalReadingTimeMinutes = totalReadingTimeMinutes
    }
    
    var cullRate: Double {
        guard totalSaved > 0 else { return 0 }
        return Double(totalArchived) / Double(totalSaved)
    }
}
