import SwiftUI

struct MacRecommendationsView: View {
    @State private var recommendations: [FriendRecommendation] = []
    @State private var friends: [Friend] = []
    @State private var selectedTab: RecommendationTab = .forYou
    @State private var selectedFriend: Friend?

    private let queueService = ReadingQueueService.shared

    enum RecommendationTab: String, CaseIterable {
        case forYou = "For You"
        case friends = "Friends"
        case discover = "Discover"
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider().background(Color.macSeparator)

            TabView(selection: $selectedTab) {
                forYouTab.tag(RecommendationTab.forYou)
                friendsTab.tag(RecommendationTab.friends)
                discoverTab.tag(RecommendationTab.discover)
            }
            .tabViewStyle(.automatic)
        }
        .background(Color.macBackground)
        .task {
            loadData()
        }
    }

    private func loadData() {
        recommendations = queueService.getRecommendations()
        friends = queueService.getFriends()
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(RecommendationTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .macPrimary : .macTextSecondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.macPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, MacTheme.spacing24)
        .background(Color.macSurface)
    }

    // MARK: - For You Tab

    private var forYouTab: some View {
        ScrollView {
            LazyVStack(spacing: MacTheme.spacing12) {
                if recommendations.isEmpty {
                    emptyStateView(
                        icon: "sparkles",
                        title: "No recommendations yet",
                        subtitle: "Read more articles to get personalized suggestions"
                    )
                } else {
                    ForEach(recommendations) { rec in
                        RecommendationCard(recommendation: rec) {
                            queueService.dismissRecommendation(rec.id)
                            loadData()
                        }
                    }
                }
            }
            .padding(MacTheme.spacing24)
        }
    }

    // MARK: - Friends Tab

    private var friendsTab: some View {
        ScrollView {
            LazyVStack(spacing: MacTheme.spacing16) {
                if friends.isEmpty {
                    emptyStateView(
                        icon: "person.2",
                        title: "No friends yet",
                        subtitle: "Connect with other readers to see their recommendations"
                    )
                } else {
                    followingSection
                    Divider().background(Color.macSeparator)
                    suggestedSection
                }
            }
            .padding(MacTheme.spacing24)
        }
    }

    private var followingSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacing12) {
            Text("Following")
                .font(.headline)
                .foregroundColor(.macTextPrimary)

            let following = friends.filter { $0.isFollowing }
            if following.isEmpty {
                Text("You're not following anyone yet")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            } else {
                ForEach(following) { friend in
                    FriendRow(friend: friend) {
                        queueService.toggleFollow(friend.userId)
                        loadData()
                    }
                }
            }
        }
    }

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacing12) {
            Text("Suggested")
                .font(.headline)
                .foregroundColor(.macTextPrimary)

            let suggested = friends.filter { !$0.isFollowing }
            if suggested.isEmpty {
                Text("No suggestions right now")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            } else {
                ForEach(suggested) { friend in
                    FriendRow(friend: friend, showFollowButton: true) {
                        queueService.toggleFollow(friend.userId)
                        loadData()
                    }
                }
            }
        }
    }

    // MARK: - Discover Tab

    private var discoverTab: some View {
        ScrollView {
            LazyVStack(spacing: MacTheme.spacing16) {
                trendingSection
                Divider().background(Color.macSeparator)
                basedOnYourReadingSection
                Divider().background(Color.macSeparator)
                popularInCommunitySection
            }
            .padding(MacTheme.spacing24)
        }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacing12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.macError)
                Text("Trending")
                    .font(.headline)
                    .foregroundColor(.macTextPrimary)
            }

            let trending = recommendations.filter { $0.reason == .trending || $0.reason == .popular }
            if trending.isEmpty {
                Text("Nothing trending right now")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            } else {
                ForEach(trending.prefix(3)) { rec in
                    DiscoverRecommendationRow(recommendation: rec)
                }
            }
        }
    }

    private var basedOnYourReadingSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacing12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.macPrimary)
                Text("Based on Your Reading")
                    .font(.headline)
                    .foregroundColor(.macTextPrimary)
            }

            let personalized = recommendations.filter { $0.reason == .basedOnReading }
            if personalized.isEmpty {
                Text("Read more to get personalized recommendations")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            } else {
                ForEach(personalized.prefix(3)) { rec in
                    DiscoverRecommendationRow(recommendation: rec)
                }
            }
        }
    }

    private var popularInCommunitySection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacing12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.macSuccess)
                Text("Popular in Community")
                    .font(.headline)
                    .foregroundColor(.macTextPrimary)
            }

            let community = recommendations.filter { $0.reason == .friendSimilar || $0.reason == .friendRead }
            if community.isEmpty {
                Text("Popular articles will appear here")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            } else {
                ForEach(community.prefix(3)) { rec in
                    DiscoverRecommendationRow(recommendation: rec)
                }
            }
        }
    }

    // MARK: - Recommendation Card

    struct RecommendationCard: View {
        let recommendation: FriendRecommendation
        let onDismiss: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: MacTheme.spacing8) {
                HStack {
                    Circle()
                        .fill(Color.macPrimary.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(recommendation.recommendedBy.prefix(1)))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.macPrimary)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.recommendedBy)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.macPrimary)
                        Text(recommendation.reasonText)
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                    }
                    Spacer()
                    Text(recommendation.recommendedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.macTextTertiary)
                }

                Text(recommendation.articleTitle)
                    .font(.body.weight(.medium))
                    .foregroundColor(.macTextPrimary)
                    .lineLimit(2)

                HStack {
                    Button("Save") {
                        // Save to library
                    }
                    .buttonStyle(MacPrimaryButtonStyle())

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.macTextTertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
                .padding(.top, 4)
            }
            .padding(MacTheme.spacing16)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusMedium)
        }
    }

    // MARK: - Friend Row

    struct FriendRow: View {
        let friend: Friend
        var showFollowButton: Bool = false
        let onToggleFollow: () -> Void

        var body: some View {
            HStack {
                Circle()
                    .fill(Color.macPrimary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(friend.avatarInitials)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.macPrimary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.macTextPrimary)
                    if friend.commonArticlesCount > 0 {
                        Text("\(friend.commonArticlesCount) articles in common")
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                    }
                }

                Spacer()

                if showFollowButton {
                    Button("Follow") {
                        onToggleFollow()
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                } else {
                    Button("Following") {
                        onToggleFollow()
                    }
                    .buttonStyle(MacSecondaryButtonStyle())
                }
            }
            .padding(MacTheme.spacing12)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusSmall)
        }
    }

    // MARK: - Discover Recommendation Row

    struct DiscoverRecommendationRow: View {
        let recommendation: FriendRecommendation

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.articleTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.macTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if recommendation.reason != .basedOnReading {
                            Text("via \(recommendation.recommendedBy)")
                                .font(.caption)
                                .foregroundColor(.macPrimary)
                        }
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                        Text(recommendation.reasonText)
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                    }
                }
                Spacer()
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.macTextTertiary)
            }
            .padding(MacTheme.spacing12)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusSmall)
        }
    }

    // MARK: - Empty State

    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: MacTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.macGhost)
            Text(title)
                .font(.headline)
                .foregroundColor(.macTextSecondary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.macTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MacTheme.spacing32)
    }
}

#Preview {
    MacRecommendationsView()
        .frame(width: 600, height: 500)
}
