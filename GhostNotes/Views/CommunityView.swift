import SwiftUI

// R12: Community & Social Features View
struct CommunityView: View {
    @State private var socialService = GhostNotesR12Service.shared
    @State private var selectedTab: CommunityTab = .feed
    @State private var showingNewPost = false
    @State private var showingNewLibrary = false
    @State private var showingNewCircle = false

    var viewModel: LibraryViewModel? = nil

    // Lazily create internal VM only when no viewModel is provided (e.g., in previews)
    @State private var internalViewModel: LibraryViewModel?

    private var vm: LibraryViewModel {
        // When viewModel is provided (normal usage from ContentView), use it directly.
        // Only create internalViewModel lazily for preview contexts.
        if let vm = viewModel {
            return vm
        }
        if let cached = internalViewModel {
            return cached
        }
        let newVM = LibraryViewModel()
        internalViewModel = newVM
        return newVM
    }

    enum CommunityTab: String, CaseIterable {
        case feed = "Feed"
        case circles = "Circles"
        case libraries = "Libraries"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Community tab picker
                    Picker("", selection: $selectedTab) {
                        ForEach(CommunityTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    ScrollView {
                        switch selectedTab {
                        case .feed:
                            feedView
                        case .circles:
                            circlesView
                        case .libraries:
                            librariesView
                        }
                    }
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        switch selectedTab {
                        case .feed:
                            showingNewPost = true
                        case .circles:
                            showingNewCircle = true
                        case .libraries:
                            showingNewLibrary = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.accent)
                    }
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostSheet(socialService: socialService)
            }
            .sheet(isPresented: $showingNewLibrary) {
                NewLibrarySheet(socialService: socialService, viewModel: vm)
            }
            .sheet(isPresented: $showingNewCircle) {
                NewCircleSheet(socialService: socialService)
            }
            .onAppear {
                socialService.loadDemoData()
            }
        }
    }

    // MARK: - Feed View

    private var feedView: some View {
        LazyVStack(spacing: 16) {
            ForEach(socialService.communityPosts) { post in
                CommunityPostCard(post: post, socialService: socialService)
            }

            if socialService.communityPosts.isEmpty {
                emptyFeedView
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var emptyFeedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.ghost)

            Text("No posts yet")
                .font(.headline)
                .foregroundStyle(.textSecondary)

            Text("Be the first to share what you're reading")
                .font(.subheadline)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                showingNewPost = true
            } label: {
                Text("Create Post")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 48)
    }

    // MARK: - Reading Circles View

    private var circlesView: some View {
        LazyVStack(spacing: 12) {
            ForEach(socialService.readingCircles) { circle in
                ReadingCircleCard(circle: circle, socialService: socialService)
            }

            if socialService.readingCircles.isEmpty {
                emptyCirclesView
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var emptyCirclesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundStyle(.ghost)

            Text("No reading circles")
                .font(.headline)
                .foregroundStyle(.textSecondary)

            Text("Start a circle to read together with friends")
                .font(.subheadline)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                showingNewCircle = true
            } label: {
                Text("Start a Circle")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 48)
    }

    // MARK: - Shared Libraries View

    private var librariesView: some View {
        LazyVStack(spacing: 12) {
            ForEach(socialService.sharedLibraries) { library in
                SharedLibraryCard(library: library, socialService: socialService, viewModel: vm)
            }

            if socialService.sharedLibraries.isEmpty {
                emptyLibrariesView
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var emptyLibrariesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundStyle(.ghost)

            Text("No shared libraries")
                .font(.headline)
                .foregroundStyle(.textSecondary)

            Text("Share your reading list with friends or the community")
                .font(.subheadline)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                showingNewLibrary = true
            } label: {
                Text("Create Library")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 48)
    }
}

// MARK: - Community Post Card

struct CommunityPostCard: View {
    let post: GhostNotesR12Service.CommunityPost
    @State private var socialService: GhostNotesR12Service
    @State private var showingShareSheet = false

    init(post: GhostNotesR12Service.CommunityPost, socialService: GhostNotesR12Service) {
        self.post = post
        self._socialService = State(initialValue: socialService)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author row
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.ghost)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(String(post.displayName.prefix(1)))
                            .font(.headline)
                            .foregroundStyle(.textPrimary)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textPrimary)

                    Text(formatDate(post.createdAt))
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }

                Spacer()

                if post.isAnonymous {
                    Image(systemName: "eye.slash")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
            }

            // Content
            Text(post.content)
                .font(.body)
                .foregroundStyle(.textPrimary)
                .lineLimit(5)

            // Article reference
            if let articleTitle = post.articleTitle {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.accent)

                    Text(articleTitle)
                        .font(.caption)
                        .foregroundStyle(.accent)
                        .lineLimit(1)
                }
                .padding(8)
                .background(Color.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Shared highlight
            if let highlight = post.highlightText {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.accent)
                        .frame(width: 3)

                    Text("\"\(highlight)\"")
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.textSecondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }

            Divider()

            // Reactions row
            HStack(spacing: 16) {
                ForEach(GhostNotesR12Service.CommunityPost.Reaction.ReactionType.allCases, id: \.self) { reactionType in
                    let reaction = post.reactions.first { $0.type == reactionType }
                    let count = reaction?.count ?? 0
                    let hasReacted = reaction?.hasReacted ?? false

                    Button {
                        socialService.reactToPost(post.id, reaction: reactionType)
                    } label: {
                        HStack(spacing: 4) {
                            Text(reactionType.rawValue)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundStyle(hasReacted ? .accent : .textTertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .opacity(count > 0 || hasReacted ? 1 : 0.5)
                }

                Spacer()

                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingShareSheet) {
            SharePostSheet(post: post)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Reading Circle Card

struct ReadingCircleCard: View {
    let circle: GhostNotesR12Service.ReadingCircle
    @State private var socialService: GhostNotesR12Service
    @State private var isJoined: Bool = true

    init(circle: GhostNotesR12Service.ReadingCircle, socialService: GhostNotesR12Service) {
        self.circle = circle
        self._socialService = State(initialValue: socialService)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(.headline)
                        .foregroundStyle(.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption2)
                        Text("\(circle.memberCount) members")
                            .font(.caption)
                    }
                    .foregroundStyle(.textTertiary)
                }

                Spacer()

                Circle()
                    .fill(circle.isActive ? Color.success : Color.ghost)
                    .frame(width: 8, height: 8)

                Text(circle.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundStyle(circle.isActive ? .success : .textTertiary)
            }

            if !circle.description.isEmpty {
                Text(circle.description)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(2)
            }

            if let currentBook = circle.currentBookTitle {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.caption)
                        .foregroundStyle(.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Currently Reading")
                            .font(.caption2)
                            .foregroundStyle(.textTertiary)
                        Text(currentBook)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.textPrimary)
                            .lineLimit(1)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                if isJoined {
                    socialService.leaveReadingCircle(circle.id)
                } else {
                    socialService.joinReadingCircle(circle.id)
                }
                isJoined.toggle()
            } label: {
                Text(isJoined ? "Leave Circle" : "Join Circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isJoined ? .textSecondary : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isJoined ? Color.surfaceElevated : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Shared Library Card

struct SharedLibraryCard: View {
    let library: GhostNotesR12Service.SharedLibrary
    @State private var socialService: GhostNotesR12Service
    @State private var viewModel: LibraryViewModel
    @State private var showingArticlePicker = false

    init(library: GhostNotesR12Service.SharedLibrary, socialService: GhostNotesR12Service, viewModel: LibraryViewModel) {
        self.library = library
        self._socialService = State(initialValue: socialService)
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(library.name)
                        .font(.headline)
                        .foregroundStyle(.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: library.isPublic ? "globe" : "lock")
                            .font(.caption2)
                        Text(library.isPublic ? "Public" : "Private")
                            .font(.caption)
                    }
                    .foregroundStyle(library.isPublic ? .accent : .textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(library.articleIds.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimary)
                    Text("articles")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
            }

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption2)
                    Text("\(library.memberCount) members")
                        .font(.caption)
                }
                .foregroundStyle(.textTertiary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.caption2)
                    Text("Collaborators")
                        .font(.caption)
                }
                .foregroundStyle(.textTertiary)
            }

            HStack(spacing: 8) {
                Button {
                    showingArticlePicker = true
                } label: {
                    Label("Add Article", systemImage: "plus")
                        .font(.caption)
                        .foregroundStyle(.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accent.opacity(0.1))
                        .clipShape(Capsule())
                }

                Button {
                    socialService.deleteSharedLibrary(library.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption)
                        .foregroundStyle(.error)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.error.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingArticlePicker) {
            AddArticleToLibrarySheet(libraryId: library.id, socialService: socialService, viewModel: viewModel)
        }
    }
}

// MARK: - New Post Sheet

struct NewPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var socialService: GhostNotesR12Service
    @State private var content = ""
    @State private var isAnonymous = false
    @State private var selectedArticle: Article?
    @State private var highlightText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    TextEditor(text: $content)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(minHeight: 120)
                        .padding(.horizontal, 16)

                    Toggle("Post Anonymously", isOn: $isAnonymous)
                        .padding(.horizontal, 16)
                        .tint(.primary)

                    if !highlightText.isEmpty {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.accent)
                                .frame(width: 3)

                            Text("\"\(highlightText)\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundStyle(.textSecondary)
                                .lineLimit(3)
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer()

                    Button {
                        _ = socialService.createPost(
                            content: content,
                            articleId: selectedArticle?.id,
                            articleTitle: selectedArticle?.title,
                            highlightText: highlightText.isEmpty ? nil : highlightText,
                            isAnonymous: isAnonymous
                        )
                        dismiss()
                    } label: {
                        Text("Post")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(content.isEmpty ? Color.ghost : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(content.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Share Post Sheet

struct SharePostSheet: View {
    @Environment(\.dismiss) private var dismiss
    let post: GhostNotesR12Service.CommunityPost
    @State private var privacyService = GhostNotesR12Service.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(post.content)
                            .font(.body)
                            .foregroundStyle(.textPrimary)
                            .multilineTextAlignment(.center)

                        if let highlight = post.highlightText {
                            Text("\"\(highlight)\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundStyle(.textSecondary)
                        }
                    }
                    .padding(24)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(spacing: 12) {
                        Text("Privacy: \(privacyService.privacySettings.anonymizeBeforeSharing ? "Anonymized" : "Public")")
                            .font(.caption)
                            .foregroundStyle(.textTertiary)

                        if privacyService.privacySettings.anonymizeBeforeSharing {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.shield")
                                    .foregroundStyle(.success)
                                Text("Your identity will be hidden when sharing")
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Share Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - New Library Sheet

struct NewLibrarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var socialService: GhostNotesR12Service
    var viewModel: LibraryViewModel
    @State private var name = ""
    @State private var isPublic = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    TextField("Library Name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding(16)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Toggle("Make Public", isOn: $isPublic)
                        .padding(.horizontal, 16)
                        .tint(.primary)

                    Text("Public libraries can be discovered by other readers")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                        .padding(.horizontal, 16)

                    Spacer()

                    Button {
                        _ = socialService.createSharedLibrary(name: name, isPublic: isPublic)
                        dismiss()
                    } label: {
                        Text("Create Library")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(name.isEmpty ? Color.ghost : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(name.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .padding(.top, 24)
            }
            .navigationTitle("New Shared Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Article To Library Sheet

struct AddArticleToLibrarySheet: View {
    @Environment(\.dismiss) private var dismiss
    let libraryId: UUID
    @ObservedObject var socialService: GhostNotesR12Service
    var viewModel: LibraryViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                if viewModel.articles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundStyle(.ghost)
                        Text("No articles in your library")
                            .font(.headline)
                            .foregroundStyle(.textSecondary)
                    }
                } else {
                    List(viewModel.articles) { article in
                        Button {
                            socialService.addArticleToSharedLibrary(libraryId, articleId: article.id)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(article.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.textPrimary)
                                        .lineLimit(2)
                                    Text(article.domain)
                                        .font(.caption)
                                        .foregroundStyle(.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.accent)
                            }
                        }
                        .listRowBackground(Color.surface)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - New Circle Sheet

struct NewCircleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var socialService: GhostNotesR12Service
    @State private var name = ""
    @State private var description = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    TextField("Circle Name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .padding(16)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField("Description (optional)", text: $description)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(16)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(minHeight: 80)

                    Spacer()

                    Button {
                        _ = socialService.createReadingCircle(name: name, description: description)
                        dismiss()
                    } label: {
                        Text("Start Circle")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(name.isEmpty ? Color.ghost : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(name.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .padding(.top, 24)
            }
            .navigationTitle("New Reading Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CommunityView()
}
