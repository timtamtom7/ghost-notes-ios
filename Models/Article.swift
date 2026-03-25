import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: UUID
    let url: String
    var title: String
    let domain: String
    var faviconURL: String?
    var content: String?
    var summary: String?
    var estimatedReadingTime: Int
    let dateAdded: Date
    var status: ArticleStatus

    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        domain: String,
        faviconURL: String? = nil,
        content: String? = nil,
        summary: String? = nil,
        estimatedReadingTime: Int = 0,
        dateAdded: Date = Date(),
        status: ArticleStatus = .unread
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.domain = domain
        self.faviconURL = faviconURL
        self.content = content
        self.summary = summary
        self.estimatedReadingTime = estimatedReadingTime
        self.dateAdded = dateAdded
        self.status = status
    }
}

enum ArticleStatus: String, Codable, CaseIterable {
    case unread
    case read
    case archived

    var displayName: String {
        switch self {
        case .unread: return "Unread"
        case .read: return "Read"
        case .archived: return "Archived"
        }
    }
}

enum FilterOption: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case archived = "Archived"
}
