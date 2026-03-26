import Foundation

// R12: Social Features — Shared Libraries, Collaborative Annotation, Reading Circles, Community
@MainActor
final class GhostNotesR12Service: ObservableObject {
    static let shared = GhostNotesR12Service()

    @Published var sharedLibraries: [SharedLibrary] = []
    @Published var readingCircles: [ReadingCircle] = []
    @Published var communityPosts: [CommunityPost] = []
    @Published var isLoadingSocial = false

    private let socialKey = "ghostNotesSocialData"

    private init() {
        loadSocialData()
    }

    // MARK: - Shared Libraries

    struct SharedLibrary: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var ownerId: String
        var ownerDisplayName: String
        var articleIds: [UUID]
        var collaboratorIds: [String]
        var isPublic: Bool
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            name: String,
            ownerId: String = "local",
            ownerDisplayName: String = "You",
            articleIds: [UUID] = [],
            collaboratorIds: [String] = [],
            isPublic: Bool = false,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.ownerId = ownerId
            self.ownerDisplayName = ownerDisplayName
            self.articleIds = articleIds
            self.collaboratorIds = collaboratorIds
            self.isPublic = isPublic
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }

        var memberCount: Int { collaboratorIds.count + 1 }
    }

    func createSharedLibrary(name: String, articleIds: [UUID] = [], isPublic: Bool = false) -> SharedLibrary {
        let library = SharedLibrary(name: name, articleIds: articleIds, isPublic: isPublic)
        sharedLibraries.append(library)
        saveSocialData()
        return library
    }

    func addArticleToSharedLibrary(_ libraryId: UUID, articleId: UUID) {
        guard let index = sharedLibraries.firstIndex(where: { $0.id == libraryId }) else { return }
        if !sharedLibraries[index].articleIds.contains(articleId) {
            sharedLibraries[index].articleIds.append(articleId)
            sharedLibraries[index].updatedAt = Date()
            saveSocialData()
        }
    }

    func removeArticleFromSharedLibrary(_ libraryId: UUID, articleId: UUID) {
        guard let index = sharedLibraries.firstIndex(where: { $0.id == libraryId }) else { return }
        sharedLibraries[index].articleIds.removeAll { $0 == articleId }
        sharedLibraries[index].updatedAt = Date()
        saveSocialData()
    }

    func deleteSharedLibrary(_ libraryId: UUID) {
        sharedLibraries.removeAll { $0.id == libraryId }
        saveSocialData()
    }

    // MARK: - Reading Circles

    struct ReadingCircle: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var description: String
        var currentBookId: UUID?  // Current article being read
        var currentBookTitle: String?
        var memberIds: [String]
        var createdAt: Date
        var isActive: Bool

        init(
            id: UUID = UUID(),
            name: String,
            description: String = "",
            currentBookId: UUID? = nil,
            currentBookTitle: String? = nil,
            memberIds: [String] = ["local"],
            createdAt: Date = Date(),
            isActive: Bool = true
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.currentBookId = currentBookId
            self.currentBookTitle = currentBookTitle
            self.memberIds = memberIds
            self.createdAt = createdAt
            self.isActive = isActive
        }

        var memberCount: Int { memberIds.count }
    }

    func createReadingCircle(name: String, description: String = "", articleId: UUID? = nil, articleTitle: String? = nil) -> ReadingCircle {
        let circle = ReadingCircle(name: name, description: description, currentBookId: articleId, currentBookTitle: articleTitle)
        readingCircles.append(circle)
        saveSocialData()
        return circle
    }

    func joinReadingCircle(_ circleId: UUID) {
        guard let index = readingCircles.firstIndex(where: { $0.id == circleId }) else { return }
        if !readingCircles[index].memberIds.contains("local") {
            readingCircles[index].memberIds.append("local")
            saveSocialData()
        }
    }

    func leaveReadingCircle(_ circleId: UUID) {
        guard let index = readingCircles.firstIndex(where: { $0.id == circleId }) else { return }
        readingCircles[index].memberIds.removeAll { $0 == "local" }
        if readingCircles[index].memberIds.isEmpty {
            readingCircles.remove(at: index)
        }
        saveSocialData()
    }

    func setCurrentBook(_ circleId: UUID, articleId: UUID, title: String) {
        guard let index = readingCircles.firstIndex(where: { $0.id == circleId }) else { return }
        readingCircles[index].currentBookId = articleId
        readingCircles[index].currentBookTitle = title
        saveSocialData()
    }

    func deleteReadingCircle(_ circleId: UUID) {
        readingCircles.removeAll { $0.id == circleId }
        saveSocialData()
    }

    // MARK: - Community Posts

    struct CommunityPost: Identifiable, Codable, Equatable {
        let id: UUID
        var authorId: String
        var authorDisplayName: String
        var isAnonymous: Bool
        var content: String
        var articleId: UUID?
        var articleTitle: String?
        var articleURL: String?
        var highlightText: String?  // Shared highlight with post
        var reactions: [Reaction]
        var commentCount: Int
        var createdAt: Date

        init(
            id: UUID = UUID(),
            authorId: String = "local",
            authorDisplayName: String = "You",
            isAnonymous: Bool = false,
            content: String,
            articleId: UUID? = nil,
            articleTitle: String? = nil,
            articleURL: String? = nil,
            highlightText: String? = nil,
            reactions: [Reaction] = [],
            commentCount: Int = 0,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.authorId = authorId
            self.authorDisplayName = authorDisplayName
            self.isAnonymous = isAnonymous
            self.content = content
            self.articleId = articleId
            self.articleTitle = articleTitle
            self.articleURL = articleURL
            self.highlightText = highlightText
            self.reactions = reactions
            self.commentCount = commentCount
            self.createdAt = createdAt
        }

        var displayName: String { isAnonymous ? "Anonymous Reader" : authorDisplayName }

        struct Reaction: Codable, Equatable {
            var type: ReactionType
            var count: Int
            var hasReacted: Bool

            enum ReactionType: String, Codable, CaseIterable {
                case like = "👍"
                case love = "❤️"
                case insightful = "💡"
                case save = "🔖"
            }
        }
    }

    func createPost(
        content: String,
        articleId: UUID? = nil,
        articleTitle: String? = nil,
        articleURL: String? = nil,
        highlightText: String? = nil,
        isAnonymous: Bool = false
    ) -> CommunityPost {
        let post = CommunityPost(
            isAnonymous: isAnonymous,
            content: content,
            articleId: articleId,
            articleTitle: articleTitle,
            articleURL: articleURL,
            highlightText: highlightText
        )
        communityPosts.insert(post, at: 0)
        saveSocialData()
        return post
    }

    func reactToPost(_ postId: UUID, reaction: CommunityPost.Reaction.ReactionType) {
        guard let index = communityPosts.firstIndex(where: { $0.id == postId }) else { return }
        if let reactionIndex = communityPosts[index].reactions.firstIndex(where: { $0.type == reaction }) {
            if communityPosts[index].reactions[reactionIndex].hasReacted {
                communityPosts[index].reactions[reactionIndex].count -= 1
                communityPosts[index].reactions[reactionIndex].hasReacted = false
            } else {
                communityPosts[index].reactions[reactionIndex].count += 1
                communityPosts[index].reactions[reactionIndex].hasReacted = true
            }
        } else {
            communityPosts[index].reactions.append(CommunityPost.Reaction(type: reaction, count: 1, hasReacted: true))
        }
        saveSocialData()
    }

    func deletePost(_ postId: UUID) {
        communityPosts.removeAll { $0.id == postId }
        saveSocialData()
    }

    // MARK: - Collaborative Annotation

    struct CollaborativeAnnotation: Identifiable, Codable, Equatable {
        let id: UUID
        var articleId: UUID
        var authorId: String
        var authorDisplayName: String
        var isAnonymous: Bool
        var text: String
        var note: String?
        var pageLocation: Double
        var createdAt: Date
        var replies: [AnnotationReply]

        init(
            id: UUID = UUID(),
            articleId: UUID,
            authorId: String = "local",
            authorDisplayName: String = "You",
            isAnonymous: Bool = false,
            text: String,
            note: String? = nil,
            pageLocation: Double = 0,
            createdAt: Date = Date(),
            replies: [AnnotationReply] = []
        ) {
            self.id = id
            self.articleId = articleId
            self.authorId = authorId
            self.authorDisplayName = authorDisplayName
            self.isAnonymous = isAnonymous
            self.text = text
            self.note = note
            self.pageLocation = pageLocation
            self.createdAt = createdAt
            self.replies = replies
        }

        struct AnnotationReply: Identifiable, Codable, Equatable {
            let id: UUID
            var authorId: String
            var authorDisplayName: String
            var isAnonymous: Bool
            var content: String
            var createdAt: Date

            init(
                id: UUID = UUID(),
                authorId: String = "local",
                authorDisplayName: String = "You",
                isAnonymous: Bool = false,
                content: String,
                createdAt: Date = Date()
            ) {
                self.id = id
                self.authorId = authorId
                self.authorDisplayName = authorDisplayName
                self.isAnonymous = isAnonymous
                self.content = content
                self.createdAt = createdAt
            }
        }
    }

    @Published var annotations: [CollaborativeAnnotation] = []

    func addAnnotation(articleId: UUID, text: String, note: String? = nil, pageLocation: Double = 0, isAnonymous: Bool = false) -> CollaborativeAnnotation {
        let annotation = CollaborativeAnnotation(articleId: articleId, isAnonymous: isAnonymous, text: text, note: note, pageLocation: pageLocation)
        annotations.append(annotation)
        saveSocialData()
        return annotation
    }

    func replyToAnnotation(_ annotationId: UUID, content: String, isAnonymous: Bool = false) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        let reply = CollaborativeAnnotation.AnnotationReply(isAnonymous: isAnonymous, content: content)
        annotations[index].replies.append(reply)
        saveSocialData()
    }

    func annotationsForArticle(_ articleId: UUID) -> [CollaborativeAnnotation] {
        annotations.filter { $0.articleId == articleId }
    }

    func deleteAnnotation(_ annotationId: UUID) {
        annotations.removeAll { $0.id == annotationId }
        saveSocialData()
    }

    // MARK: - Privacy Controls

    struct PrivacySettings: Codable {
        var anonymizeBeforeSharing: Bool
        var defaultPostVisibility: PostVisibility
        var shareReadingActivity: Bool
        var allowCollaborativeAnnotation: Bool

        enum PostVisibility: String, Codable, CaseIterable {
            case publicAll = "Public"
            case communityOnly = "Community Only"
            case privateOnly = "Private"
        }

        static var `default`: PrivacySettings {
            PrivacySettings(
                anonymizeBeforeSharing: true,
                defaultPostVisibility: .communityOnly,
                shareReadingActivity: false,
                allowCollaborativeAnnotation: true
            )
        }
    }

    @Published var privacySettings: PrivacySettings = .default

    func updatePrivacySettings(_ settings: PrivacySettings) {
        privacySettings = settings
        saveSocialData()
    }

    // MARK: - Persistence

    private struct SocialData: Codable {
        var sharedLibraries: [SharedLibrary]
        var readingCircles: [ReadingCircle]
        var communityPosts: [CommunityPost]
        var annotations: [CollaborativeAnnotation]
        var privacySettings: PrivacySettings
    }

    private func loadSocialData() {
        guard let data = UserDefaults.standard.data(forKey: socialKey),
              let socialData = try? JSONDecoder().decode(SocialData.self, from: data) else {
            return
        }
        sharedLibraries = socialData.sharedLibraries
        readingCircles = socialData.readingCircles
        communityPosts = socialData.communityPosts
        annotations = socialData.annotations
        privacySettings = socialData.privacySettings
    }

    private func saveSocialData() {
        let socialData = SocialData(
            sharedLibraries: sharedLibraries,
            readingCircles: readingCircles,
            communityPosts: communityPosts,
            annotations: annotations,
            privacySettings: privacySettings
        )
        if let data = try? JSONEncoder().encode(socialData) {
            UserDefaults.standard.set(data, forKey: socialKey)
        }
    }

    // MARK: - Demo Data

    func loadDemoData() {
        guard sharedLibraries.isEmpty && readingCircles.isEmpty && communityPosts.isEmpty else { return }

        let circle = ReadingCircle(name: "Philosophy Club", description: "Weekly deep reads on philosophy and ethics", currentBookTitle: "Meditations by Marcus Aurelius")
        readingCircles = [circle]

        let post = CommunityPost(isAnonymous: false, content: "Just finished this article on attention. The section on digital minimalism completely changed how I approach my morning routine.", articleTitle: "The Art of Attention", highlightText: "What we pay attention to is who we become.")
        communityPosts = [post]

        let library = SharedLibrary(name: "Tech Reading List", articleIds: [], isPublic: true)
        sharedLibraries = [library]

        saveSocialData()
    }
}
