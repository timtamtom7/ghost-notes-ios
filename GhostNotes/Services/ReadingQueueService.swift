import Foundation

// MARK: - Shared Reading Queue Models

struct SharedArticle: Identifiable, Codable, Equatable {
    let id: UUID
    let articleId: UUID
    let articleTitle: String
    let sharedBy: String
    let sharedByUserId: String
    let sharedAt: Date
    let note: String?

    init(
        id: UUID = UUID(),
        articleId: UUID,
        articleTitle: String,
        sharedBy: String,
        sharedByUserId: String = "local",
        sharedAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.articleId = articleId
        self.articleTitle = articleTitle
        self.sharedBy = sharedBy
        self.sharedByUserId = sharedByUserId
        self.sharedAt = sharedAt
        self.note = note
    }
}

struct Friend: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    var userId: String
    var avatarInitials: String
    var isFollowing: Bool
    var commonArticlesCount: Int
    var joinedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        userId: String,
        avatarInitials: String,
        isFollowing: Bool = false,
        commonArticlesCount: Int = 0,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.userId = userId
        self.avatarInitials = avatarInitials
        self.isFollowing = isFollowing
        self.commonArticlesCount = commonArticlesCount
        self.joinedAt = joinedAt
    }
}

struct FriendRecommendation: Identifiable, Codable, Equatable {
    let id: UUID
    let articleId: UUID
    let articleTitle: String
    let recommendedBy: String
    let recommendedByUserId: String
    let reason: RecommendationReason
    let recommendedAt: Date

    enum RecommendationReason: String, Codable {
        case friendLoved = "loved"
        case friendRead = "read"
        case friendSimilar = "similar_taste"
        case popular = "popular"
        case trending = "trending"
        case basedOnReading = "based_on_your_reading"
    }

    init(
        id: UUID = UUID(),
        articleId: UUID,
        articleTitle: String,
        recommendedBy: String,
        recommendedByUserId: String,
        reason: RecommendationReason,
        recommendedAt: Date = Date()
    ) {
        self.id = id
        self.articleId = articleId
        self.articleTitle = articleTitle
        self.recommendedBy = recommendedBy
        self.recommendedByUserId = recommendedByUserId
        self.reason = reason
        self.recommendedAt = recommendedAt
    }

    var reasonText: String {
        switch reason {
        case .friendLoved:
            return "\(recommendedBy) loved this"
        case .friendRead:
            return "\(recommendedBy) read this"
        case .friendSimilar:
            return "\(recommendedBy) has similar taste"
        case .popular:
            return "Popular with readers"
        case .trending:
            return "Trending now"
        case .basedOnReading:
            return "Based on your reading"
        }
    }
}

// MARK: - Reading Queue Service

final class ReadingQueueService: @unchecked Sendable {
    static let shared = ReadingQueueService()

    private let sharedArticlesKey = "ghostNotesSharedArticles"
    private let friendsKey = "ghostNotesFriends"
    private let recommendationsKey = "ghostNotesRecommendations"

    private init() {
        loadDemoDataIfNeeded()
    }

    // MARK: - Shared Articles

    func shareArticle(articleId: UUID, articleTitle: String, to userId: UUID, note: String? = nil) async throws {
        var shared = loadSharedArticles()
        let article = SharedArticle(
            articleId: articleId,
            articleTitle: articleTitle,
            sharedBy: "You",
            sharedByUserId: "local",
            note: note
        )
        shared.append(article)
        saveSharedArticles(shared)
    }

    func getSharedWithMe() -> [SharedArticle] {
        loadSharedArticles().filter { $0.sharedByUserId != "local" }
    }

    func getMyShares() -> [SharedArticle] {
        loadSharedArticles().filter { $0.sharedByUserId == "local" }
    }

    func removeSharedArticle(_ id: UUID) {
        var shared = loadSharedArticles()
        shared.removeAll { $0.id == id }
        saveSharedArticles(shared)
    }

    // MARK: - Friends

    func getFriends() -> [Friend] {
        guard let data = UserDefaults.standard.data(forKey: friendsKey),
              let friends = try? JSONDecoder().decode([Friend].self, from: data) else {
            return []
        }
        return friends
    }

    func addFriend(_ friend: Friend) {
        var friends = getFriends()
        if !friends.contains(where: { $0.userId == friend.userId }) {
            friends.append(friend)
            saveFriends(friends)
        }
    }

    func removeFriend(_ userId: String) {
        var friends = getFriends()
        friends.removeAll { $0.userId == userId }
        saveFriends(friends)
    }

    func toggleFollow(_ userId: String) {
        var friends = getFriends()
        if let index = friends.firstIndex(where: { $0.userId == userId }) {
            friends[index].isFollowing.toggle()
            saveFriends(friends)
        }
    }

    // MARK: - Recommendations

    func getRecommendations() -> [FriendRecommendation] {
        guard let data = UserDefaults.standard.data(forKey: recommendationsKey),
              let recommendations = try? JSONDecoder().decode([FriendRecommendation].self, from: data) else {
            return []
        }
        return recommendations
    }

    func addRecommendation(_ recommendation: FriendRecommendation) {
        var recommendations = getRecommendations()
        recommendations.insert(recommendation, at: 0)
        saveRecommendations(recommendations)
    }

    func dismissRecommendation(_ id: UUID) {
        var recommendations = getRecommendations()
        recommendations.removeAll { $0.id == id }
        saveRecommendations(recommendations)
    }

    // MARK: - Persistence

    private func loadSharedArticles() -> [SharedArticle] {
        guard let data = UserDefaults.standard.data(forKey: sharedArticlesKey),
              let articles = try? JSONDecoder().decode([SharedArticle].self, from: data) else {
            return []
        }
        return articles
    }

    private func saveSharedArticles(_ articles: [SharedArticle]) {
        if let data = try? JSONEncoder().encode(articles) {
            UserDefaults.standard.set(data, forKey: sharedArticlesKey)
        }
    }

    private func saveFriends(_ friends: [Friend]) {
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: friendsKey)
        }
    }

    private func saveRecommendations(_ recommendations: [FriendRecommendation]) {
        if let data = try? JSONEncoder().encode(recommendations) {
            UserDefaults.standard.set(data, forKey: recommendationsKey)
        }
    }

    // MARK: - Demo Data

    private var isDemoDataLoaded = false

    private func loadDemoDataIfNeeded() {
        guard !isDemoDataLoaded else { return }
        isDemoDataLoaded = true

        if getFriends().isEmpty {
            let demoFriends = [
                Friend(displayName: "Elena", userId: "elena_123", avatarInitials: "EL", isFollowing: true, commonArticlesCount: 12),
                Friend(displayName: "Marco", userId: "marco_456", avatarInitials: "MA", isFollowing: true, commonArticlesCount: 8),
                Friend(displayName: "Sofia", userId: "sofia_789", avatarInitials: "SO", isFollowing: false, commonArticlesCount: 5),
                Friend(displayName: "Luca", userId: "luca_321", avatarInitials: "LU", isFollowing: false, commonArticlesCount: 3)
            ]
            if let data = try? JSONEncoder().encode(demoFriends) {
                UserDefaults.standard.set(data, forKey: friendsKey)
            }
        }

        if getRecommendations().isEmpty {
            let demoRecommendations = [
                FriendRecommendation(articleId: UUID(), articleTitle: "The Future of AI", recommendedBy: "Elena", recommendedByUserId: "elena_123", reason: .friendLoved),
                FriendRecommendation(articleId: UUID(), articleTitle: "Understanding Attention", recommendedBy: "Marco", recommendedByUserId: "marco_456", reason: .friendRead),
                FriendRecommendation(articleId: UUID(), articleTitle: "Digital Minimalism Guide", recommendedBy: "Sofia", recommendedByUserId: "sofia_789", reason: .basedOnReading),
                FriendRecommendation(articleId: UUID(), articleTitle: "The Art of Focus", recommendedBy: "Elena", recommendedByUserId: "elena_123", reason: .friendSimilar)
            ]
            if let data = try? JSONEncoder().encode(demoRecommendations) {
                UserDefaults.standard.set(data, forKey: recommendationsKey)
            }
        }

        if loadSharedArticles().isEmpty {
            let demoShared = [
                SharedArticle(articleId: UUID(), articleTitle: "Why Walking Matters", sharedBy: "Elena", sharedByUserId: "elena_123", note: "This changed how I think about creativity!"),
                SharedArticle(articleId: UUID(), articleTitle: "The Deep Work Hypothesis", sharedBy: "Marco", sharedByUserId: "marco_456", note: nil),
                SharedArticle(articleId: UUID(), articleTitle: "My reading list", sharedBy: "Sofia", sharedByUserId: "sofia_789", note: "Start with this one")
            ]
            if let data = try? JSONEncoder().encode(demoShared) {
                UserDefaults.standard.set(data, forKey: sharedArticlesKey)
            }
        }
    }
}
