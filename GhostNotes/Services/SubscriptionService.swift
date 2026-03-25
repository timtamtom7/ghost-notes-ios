import Foundation

/// R9: Subscription tier management
final class SubscriptionService: @unchecked Sendable {
    static let shared = SubscriptionService()
    
    private let tierKey = "ghost_notes_subscription_tier"
    private let expirationKey = "ghost_notes_subscription_expiration"
    
    private init() {}
    
    enum SubscriptionTier: String, Codable {
        case free = "Free"
        case pro = "Pro"
        case team = "Team"
        
        var displayName: String { rawValue }
        
        var maxArticlesPerMonth: Int {
            switch self {
            case .free: return 5
            case .pro: return -1  // unlimited
            case .team: return -1
            }
        }
        
        var includesAIRecommendations: Bool {
            switch self {
            case .free: return false
            case .pro, .team: return true
            }
        }
        
        var includesHighlights: Bool {
            switch self {
            case .free: return false
            case .pro, .team: return true
            }
        }
        
        var includesExport: Bool {
            switch self {
            case .free: return false
            case .pro, .team: return true
            }
        }
        
        var includesAnalytics: Bool {
            switch self {
            case .free: return false
            case .pro, .team: return true
            }
        }
        
        var includesTeamSharing: Bool {
            switch self {
            case .free, .pro: return false
            case .team: return true
            }
        }
        
        var price: String {
            switch self {
            case .free: return "Free"
            case .pro: return "$4.99/mo"
            case .team: return "$9.99/mo"
            }
        }
    }
    
    var currentTier: SubscriptionTier {
        get {
            guard let raw = UserDefaults.standard.string(forKey: tierKey),
                  let tier = SubscriptionTier(rawValue: raw) else {
                return .free
            }
            
            // Check expiration if applicable
            if let expiration = UserDefaults.standard.object(forKey: expirationKey) as? Date {
                if Date() > expiration && tier != .free {
                    return .free
                }
            }
            
            return tier
        }
    }
    
    func setTier(_ tier: SubscriptionTier, expirationDate: Date? = nil) {
        UserDefaults.standard.set(tier.rawValue, forKey: tierKey)
        if let exp = expirationDate {
            UserDefaults.standard.set(exp, forKey: expirationKey)
        } else {
            UserDefaults.standard.removeObject(forKey: expirationKey)
        }
    }
    
    /// Check if user can save more articles this month (Free tier limit)
    func canSaveArticle(totalSavedThisMonth: Int) -> Bool {
        switch currentTier {
        case .free:
            return totalSavedThisMonth < 5
        case .pro, .team:
            return true
        }
    }
    
    /// Check if a feature is available for current subscription tier
    func isFeatureAvailable(_ feature: Feature) -> Bool {
        switch feature {
        case .highlights:
            return currentTier.includesHighlights
        case .aiRecommendations:
            return currentTier.includesAIRecommendations
        case .export:
            return currentTier.includesExport
        case .analytics:
            return currentTier.includesAnalytics
        case .teamSharing:
            return currentTier.includesTeamSharing
        case .unlimitedArticles:
            return currentTier != .free
        }
    }
    
    enum Feature {
        case highlights
        case aiRecommendations
        case export
        case analytics
        case teamSharing
        case unlimitedArticles
    }
    
    /// Monthly article usage tracking
    private let monthlySaveCountKey = "ghost_notes_monthly_save_count"
    private let monthlySaveMonthKey = "ghost_notes_monthly_save_month"
    
    var articlesSavedThisMonth: Int {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let storedMonth = UserDefaults.standard.integer(forKey: monthlySaveMonthKey)
        
        if currentMonth != storedMonth {
            // New month - reset count
            UserDefaults.standard.set(currentMonth, forKey: monthlySaveMonthKey)
            UserDefaults.standard.set(0, forKey: monthlySaveCountKey)
            return 0
        }
        
        return UserDefaults.standard.integer(forKey: monthlySaveCountKey)
    }
    
    func incrementSaveCount() {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let storedMonth = UserDefaults.standard.integer(forKey: monthlySaveMonthKey)
        
        if currentMonth != storedMonth {
            UserDefaults.standard.set(currentMonth, forKey: monthlySaveMonthKey)
            UserDefaults.standard.set(1, forKey: monthlySaveCountKey)
        } else {
            let count = UserDefaults.standard.integer(forKey: monthlySaveCountKey)
            UserDefaults.standard.set(count + 1, forKey: monthlySaveCountKey)
        }
    }
}
