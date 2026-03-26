import Foundation

// R11: Browser Extension, Email Digest, Import Expansion for Ghost Notes
@MainActor
final class GhostNotesR11Service: ObservableObject {
    static let shared = GhostNotesR11Service()

    @Published var digestFrequency: DigestFrequency = .weekly
    @Published var unreadCount = 0

    enum DigestFrequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    private init() {}

    // MARK: - Browser Extension Data

    struct BrowserExtensionData: Codable {
        let articleURL: String
        let articleTitle: String
        let savedAt: Date
        let tags: [String]
    }

    func saveFromBrowserExtension(data: BrowserExtensionData) {
        // Save to shared container for main app to process
        var saved = loadBrowserExtensionData()
        saved.append(data)
        saveBrowserExtensionData(saved)
    }

    private func loadBrowserExtensionData() -> [BrowserExtensionData] {
        guard let data = UserDefaults.standard.data(forKey: "browserExtensionData"),
              let items = try? JSONDecoder().decode([BrowserExtensionData].self, from: data) else {
            return []
        }
        return items
    }

    private func saveBrowserExtensionData(_ items: [BrowserExtensionData]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "browserExtensionData")
        }
    }

    // MARK: - Email Digest

    func generateDigestEmail(articles: [Article]) -> String {
        var email = "Your Weekly Reading Digest\n\n"

        for article in articles.prefix(5) {
            email += "📖 \(article.title)\n"
            email += "   \(article.url)\n"
            email += "   Saved \(formatDate(article.savedAt))\n\n"
        }

        // Old articles reminder
        let oldArticles = articles.filter {
            Calendar.current.dateComponents([.day], from: $0.savedAt, to: Date()).day ?? 0 > 30
        }

        if !oldArticles.isEmpty {
            email += "\n🕐 Still on your list:\n"
            for article in oldArticles.prefix(3) {
                email += "   \(article.title)\n"
            }
        }

        return email
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Import Expansion

    enum ImportSource: String, CaseIterable {
        case pocket = "Pocket"
        case instapaper = "Instapaper"
        case safari = "Safari Reading List"
        case pinboard = "Pinboard"
    }

    func importFrom(source: ImportSource) async throws -> Int {
        switch source {
        case .pocket:
            return try await importFromPocket()
        case .instapaper:
            return try await importFromInstapaper()
        case .safari:
            return importFromSafari()
        case .pinboard:
            return try await importFromPinboard()
        }
    }

    private func importFromPocket() async throws -> Int {
        // Would use Pocket API
        return 0
    }

    private func importFromInstapaper() async throws -> Int {
        // Would use Instapaper API
        return 0
    }

    private func importFromSafari() -> Int {
        // Read from iCloud Safari Reading List
        return 0
    }

    private func importFromPinboard() async throws -> Int {
        // Would use Pinboard API
        return 0
    }

    // MARK: - Retention

    func sendRetentionNudge(for articleId: UUID) {
        unreadCount += 1
    }

    func archiveOldArticles(olderThan days: Int = 90) {
        // Archive articles not opened in X days
    }
}
