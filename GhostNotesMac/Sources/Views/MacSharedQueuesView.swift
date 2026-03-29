import SwiftUI

struct MacSharedQueuesView: View {
    @StateObject private var r12Service = GhostNotesR12Service.shared
    @State private var selectedTab: SharedTab = .sharedWithMe
    @State private var selectedAnnotation: GhostNotesR12Service.CollaborativeAnnotation?
    @State private var showingAnnotationDetail = false
    @State private var newPostContent = ""
    @State private var showingNewPost = false

    private let queueService = ReadingQueueService.shared

    enum SharedTab: String, CaseIterable {
        case sharedWithMe = "Shared with Me"
        case myShares = "My Shares"
        case circles = "Reading Circles"
        case community = "Community"
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider().background(Color.macSeparator)

            TabView(selection: $selectedTab) {
                sharedWithMeTab.tag(SharedTab.sharedWithMe)
                mySharesTab.tag(SharedTab.myShares)
                circlesTab.tag(SharedTab.circles)
                communityTab.tag(SharedTab.community)
            }
            .tabViewStyle(.automatic)
        }
        .background(Color.macBackground)
        .sheet(isPresented: $showingAnnotationDetail) {
            if let annotation = selectedAnnotation {
                annotationDetailView(annotation)
            }
        }
        .sheet(isPresented: $showingNewPost) {
            newPostSheet
        }
        .task {
            r12Service.loadDemoData()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(SharedTab.allCases, id: \.self) { tab in
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

    // MARK: - Shared With Me Tab

    private var sharedWithMeTab: some View {
        ScrollView {
            LazyVStack(spacing: MacTheme.spacing12) {
                let articles = queueService.getSharedWithMe()
                if articles.isEmpty {
                    emptyStateView(
                        icon: "person.2",
                        title: "Nothing shared yet",
                        subtitle: "Articles shared with you will appear here"
                    )
                } else {
                    ForEach(articles) { article in
                        SharedArticleCard(article: article)
                    }
                }
            }
            .padding(MacTheme.spacing24)
        }
    }

    // MARK: - My Shares Tab

    private var mySharesTab: some View {
        ScrollView {
            LazyVStack(spacing: MacTheme.spacing12) {
                let shares = queueService.getMyShares()
                if shares.isEmpty {
                    emptyStateView(
                        icon: "square.and.arrow.up",
                        title: "No shares yet",
                        subtitle: "Share articles from your library with friends"
                    )
                } else {
                    ForEach(shares) { share in
                        MyShareCard(share: share)
                    }
                }

                Divider().background(Color.macSeparator).padding(.vertical, 8)

                sharedLibrariesSection
            }
            .padding(MacTheme.spacing24)
        }
    }

    // MARK: - Shared Libraries Section

    private var sharedLibrariesSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacing12) {
            HStack {
                Text("Shared Libraries")
                    .font(.headline)
                    .foregroundColor(.macTextPrimary)
                Spacer()
                Button {
                    let _ = r12Service.createSharedLibrary(name: "New Library")
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.macPrimary)
                }
            }

            if r12Service.sharedLibraries.isEmpty {
                Text("Create a shared library to curate articles for friends")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            } else {
                ForEach(r12Service.sharedLibraries) { library in
                    SharedLibraryRow(library: library)
                }
            }
        }
    }

    // MARK: - Reading Circles Tab

    private var circlesTab: some View {
        ScrollView {
            LazyVStack(spacing: MacTheme.spacing12) {
                if r12Service.readingCircles.isEmpty {
                    emptyStateView(
                        icon: "circle.dashed",
                        title: "No reading circles",
                        subtitle: "Start or join a circle to read together"
                    )
                } else {
                    ForEach(r12Service.readingCircles) { circle in
                        ReadingCircleCard(circle: circle)
                    }
                }

                Divider().background(Color.macSeparator).padding(.vertical, 8)

                annotationsSection
            }
            .padding(MacTheme.spacing24)
        }
    }

    // MARK: - Annotations Section

    private var annotationsSection: some View {
        VStack(alignment: .leading, spacing: MacTheme.spacing12) {
            HStack {
                Text("Collaborative Annotations")
                    .font(.headline)
                    .foregroundColor(.macTextPrimary)
                Spacer()
            }

            let annotations = r12Service.annotations
            if annotations.isEmpty {
                Text("Highlight text in articles to add collaborative annotations")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            } else {
                ForEach(annotations) { annotation in
                    AnnotationRow(annotation: annotation) {
                        selectedAnnotation = annotation
                        showingAnnotationDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Community Tab

    private var communityTab: some View {
        ScrollView {
            LazyVStack(spacing: MacTheme.spacing12) {
                HStack {
                    Text("Community Posts")
                        .font(.headline)
                        .foregroundColor(.macTextPrimary)
                    Spacer()
                    Button {
                        showingNewPost = true
                    } label: {
                        Label("New Post", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.macPrimary)
                    }
                }

                if r12Service.communityPosts.isEmpty {
                    emptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "No posts yet",
                        subtitle: "Share your reading thoughts with the community"
                    )
                } else {
                    ForEach(r12Service.communityPosts) { post in
                        CommunityPostCard(post: post)
                    }
                }
            }
            .padding(MacTheme.spacing24)
        }
    }

    // MARK: - Shared Article Card

    struct SharedArticleCard: View {
        let article: SharedArticle

        var body: some View {
            VStack(alignment: .leading, spacing: MacTheme.spacing8) {
                HStack {
                    Circle()
                        .fill(Color.macPrimary.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(article.sharedBy.prefix(1)))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.macPrimary)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.sharedBy)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.macTextPrimary)
                        Text(article.sharedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.macTextTertiary)
                }

                Text(article.articleTitle)
                    .font(.body.weight(.medium))
                    .foregroundColor(.macTextPrimary)
                    .lineLimit(2)

                if let note = article.note {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.macTextSecondary)
                        .padding(.top, 4)
                }
            }
            .padding(MacTheme.spacing16)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusMedium)
        }
    }

    // MARK: - My Share Card

    struct MyShareCard: View {
        let share: SharedArticle

        var body: some View {
            VStack(alignment: .leading, spacing: MacTheme.spacing8) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.macPrimary)
                    Text("Shared with")
                        .font(.caption)
                        .foregroundColor(.macTextSecondary)
                    Text("Unknown")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.macTextPrimary)
                    Spacer()
                    Text(share.sharedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.macTextTertiary)
                }
                Text(share.articleTitle)
                    .font(.body.weight(.medium))
                    .foregroundColor(.macTextPrimary)
                    .lineLimit(2)
            }
            .padding(MacTheme.spacing16)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusMedium)
        }
    }

    // MARK: - Shared Library Row

    struct SharedLibraryRow: View {
        let library: GhostNotesR12Service.SharedLibrary

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(library.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.macTextPrimary)
                    Text("\(library.articleIds.count) articles • \(library.memberCount) members")
                        .font(.caption)
                        .foregroundColor(.macTextTertiary)
                }
                Spacer()
                Image(systemName: library.isPublic ? "globe" : "lock")
                    .foregroundColor(.macTextTertiary)
            }
            .padding(MacTheme.spacing12)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusSmall)
        }
    }

    // MARK: - Reading Circle Card

    struct ReadingCircleCard: View {
        let circle: GhostNotesR12Service.ReadingCircle

        var body: some View {
            VStack(alignment: .leading, spacing: MacTheme.spacing8) {
                HStack {
                    Circle()
                        .fill(Color.macPrimary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "book.circle")
                                .foregroundColor(.macPrimary)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(circle.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.macTextPrimary)
                        Text("\(circle.memberCount) members")
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                    }
                    Spacer()
                    Circle()
                        .fill(circle.isActive ? Color.macSuccess : Color.macTextTertiary)
                        .frame(width: 8, height: 8)
                }

                if let bookTitle = circle.currentBookTitle {
                    HStack {
                        Image(systemName: "book")
                            .foregroundColor(.macTextTertiary)
                        Text("Currently reading: \(bookTitle)")
                            .font(.caption)
                            .foregroundColor(.macTextSecondary)
                    }
                }

                Text(circle.description)
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
                    .lineLimit(2)
            }
            .padding(MacTheme.spacing16)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusMedium)
        }
    }

    // MARK: - Annotation Row

    struct AnnotationRow: View {
        let annotation: GhostNotesR12Service.CollaborativeAnnotation
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: MacTheme.spacing4) {
                    HStack {
                        Text(annotation.isAnonymous ? "Anonymous Reader" : annotation.authorDisplayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.macPrimary)
                        Spacer()
                        Text(annotation.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                    }
                    Text(annotation.text)
                        .font(.subheadline)
                        .foregroundColor(.macTextPrimary)
                        .lineLimit(3)
                    if !annotation.replies.isEmpty {
                        Text("\(annotation.replies.count) replies")
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                    }
                }
                .padding(MacTheme.spacing12)
                .background(Color.macSurfaceElevated)
                .cornerRadius(MacTheme.cornerRadiusSmall)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Community Post Card

    struct CommunityPostCard: View {
        let post: GhostNotesR12Service.CommunityPost

        var body: some View {
            VStack(alignment: .leading, spacing: MacTheme.spacing8) {
                HStack {
                    Circle()
                        .fill(Color.macPrimary.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(post.displayName.prefix(1)))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.macPrimary)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.macTextPrimary)
                        Text(post.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.macTextTertiary)
                    }
                    Spacer()
                }

                Text(post.content)
                    .font(.subheadline)
                    .foregroundColor(.macTextPrimary)
                    .lineLimit(4)

                if let articleTitle = post.articleTitle {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.macTextTertiary)
                        Text(articleTitle)
                            .font(.caption)
                            .foregroundColor(.macTextSecondary)
                    }
                    .padding(.top, 4)
                }

                if let highlight = post.highlightText {
                    Text(highlight)
                        .font(.caption.italic())
                        .foregroundColor(.macAccent)
                        .padding(.horizontal, MacTheme.spacing8)
                        .padding(.vertical, MacTheme.spacing4)
                        .background(Color.macPrimary.opacity(0.1))
                        .cornerRadius(MacTheme.cornerRadiusSmall)
                        .padding(.top, 4)
                }

                HStack(spacing: MacTheme.spacing16) {
                    ForEach(post.reactions, id: \.type) { reaction in
                        HStack(spacing: 4) {
                            Text(reaction.type.rawValue)
                            Text("\(reaction.count)")
                                .font(.caption)
                                .foregroundColor(.macTextSecondary)
                        }
                    }
                    if post.commentCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                            Text("\(post.commentCount)")
                        }
                        .font(.caption)
                        .foregroundColor(.macTextSecondary)
                    }
                }
                .padding(.top, 4)
            }
            .padding(MacTheme.spacing16)
            .background(Color.macSurfaceElevated)
            .cornerRadius(MacTheme.cornerRadiusMedium)
        }
    }

    // MARK: - Annotation Detail View

    private func annotationDetailView(_ annotation: GhostNotesR12Service.CollaborativeAnnotation) -> some View {
        VStack(alignment: .leading, spacing: MacTheme.spacing16) {
            HStack {
                Text("Annotation")
                    .font(.title2.bold())
                    .foregroundColor(.macTextPrimary)
                Spacer()
                Button {
                    showingAnnotationDetail = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.macTextTertiary)
                }
            }

            Text(annotation.text)
                .font(.body)
                .foregroundColor(.macTextPrimary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.macSurfaceElevated)
                .cornerRadius(MacTheme.cornerRadiusSmall)

            if let note = annotation.note {
                Text("Note: \(note)")
                    .font(.subheadline)
                    .foregroundColor(.macTextSecondary)
            }

            Text("By \(annotation.isAnonymous ? "Anonymous Reader" : annotation.authorDisplayName) • \(annotation.createdAt, style: .relative)")
                .font(.caption)
                .foregroundColor(.macTextTertiary)

            Divider()

            Text("Replies (\(annotation.replies.count))")
                .font(.headline)
                .foregroundColor(.macTextPrimary)

            ScrollView {
                LazyVStack(spacing: MacTheme.spacing8) {
                    ForEach(annotation.replies) { reply in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reply.isAnonymous ? "Anonymous Reader" : reply.authorDisplayName)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.macPrimary)
                            Text(reply.content)
                                .font(.subheadline)
                                .foregroundColor(.macTextPrimary)
                        }
                        .padding(MacTheme.spacing8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.macSurfaceElevated)
                        .cornerRadius(MacTheme.cornerRadiusSmall)
                    }
                }
            }

            Spacer()
        }
        .padding(MacTheme.spacing24)
        .frame(width: 500, height: 450)
        .background(Color.macSurface)
    }

    // MARK: - New Post Sheet

    private var newPostSheet: some View {
        VStack(spacing: MacTheme.spacing16) {
            HStack {
                Text("New Community Post")
                    .font(.title2.bold())
                    .foregroundColor(.macTextPrimary)
                Spacer()
                Button {
                    showingNewPost = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.macTextTertiary)
                }
            }

            TextEditor(text: $newPostContent)
                .font(.body)
                .foregroundColor(.macTextPrimary)
                .scrollContentBackground(.hidden)
                .padding(MacTheme.spacing12)
                .background(Color.macSurfaceElevated)
                .cornerRadius(MacTheme.cornerRadiusSmall)
                .frame(height: 120)

            HStack {
                Button("Cancel") {
                    newPostContent = ""
                    showingNewPost = false
                }
                .buttonStyle(MacSecondaryButtonStyle())

                Spacer()

                Button("Post") {
                    let _ = r12Service.createPost(content: newPostContent)
                    newPostContent = ""
                    showingNewPost = false
                }
                .buttonStyle(MacPrimaryButtonStyle())
                .disabled(newPostContent.isEmpty)
            }
        }
        .padding(MacTheme.spacing24)
        .frame(width: 450)
        .background(Color.macSurface)
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
    MacSharedQueuesView()
        .frame(width: 600, height: 500)
}
