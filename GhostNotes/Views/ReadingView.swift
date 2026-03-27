import SwiftUI

struct ReadingView: View {
    @State private var viewModel: ReadingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    @State private var showingHighlightSheet = false
    @State private var showingBookmarkSheet = false
    @State private var selectedParagraph = ""
    @State private var selectedColor: HighlightColor = .primary

    init(article: Article) {
        _viewModel = State(initialValue: ReadingViewModel(article: article))
    }

    var body: some View {
        ZStack {
            viewModel.readingTheme.backgroundColor
                .ignoresSafeArea()

            ScrollViewReader { _ in
                ScrollView {
                    readingContent
                }
            }

            VStack {
                Spacer()
                readingToolbar
            }

            progressBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Theme.haptic(.light)
                    showingSettings = true
                } label: {
                    Image(systemName: "textformat.size")
                }
                .tint(viewModel.readingTheme.textColor)
                .accessibilityLabel("Reading settings")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Theme.haptic(.light)
                    showingBookmarkSheet = true
                } label: {
                    Image(systemName: "bookmark")
                }
                .tint(viewModel.readingTheme.textColor)
                .accessibilityLabel("View bookmarks")
            }
        }
        .toolbarBackground(viewModel.readingTheme.backgroundColor, for: .navigationBar)
        .sheet(isPresented: $showingSettings) {
            ReadingSettingsSheet(viewModel: viewModel)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingHighlightSheet) {
            HighlightPickerSheet(
                text: selectedParagraph,
                selectedColor: $selectedColor,
                onSave: { color in
                    Theme.haptic(.success)
                    Task {
                        await viewModel.addHighlight(text: selectedParagraph, color: color)
                    }
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingBookmarkSheet) {
            BookmarkSheet(
                bookmarks: viewModel.bookmarks,
                onSave: { label, position in
                    Theme.haptic(.success)
                    Task {
                        await viewModel.addBookmark(label: label, position: position)
                    }
                },
                onDelete: { bookmark in
                    Theme.haptic(.warning)
                    Task {
                        await viewModel.deleteBookmark(bookmark)
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onDisappear {
            Task { await viewModel.markAsRead() }
        }
    }

    private var readingContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection
            Divider().background(Color.separator).padding(.horizontal, 24)
            bodySection
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 120)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.article.domain)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(viewModel.article.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(viewModel.readingTheme.textColor)

            HStack(spacing: 16) {
                Label("\(viewModel.article.readingTimeMinutes) min read", systemImage: "clock")
                Label("\(Int(viewModel.article.readingProgress * 100))% complete", systemImage: "book")
            }
            .font(.caption)
            .foregroundColor(.textSecondary)

            // R7: Show article highlights count
            if !viewModel.highlights.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "highlighter")
                        .font(.caption)
                    Text("\(viewModel.highlights.count) highlights")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
        }
        .padding(.top, 16)
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(readingParagraphs.enumerated()), id: \.offset) { _, paragraph in
                HighlightableText(
                    text: paragraph,
                    highlights: viewModel.highlights,
                    textColor: viewModel.readingTheme.textColor,
                    fontSize: viewModel.fontSize.size,
                    onHighlight: { selectedText in
                        Theme.haptic(.medium)
                        selectedParagraph = selectedText
                        showingHighlightSheet = true
                    }
                )
            }
        }
    }

    private var progressBar: some View {
        VStack {
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: geometry.size.width * viewModel.article.readingProgress, height: 3)
            }
            .frame(height: 3)
            Spacer()
        }
        .ignoresSafeArea()
    }

    private var readingToolbar: some View {
        HStack(spacing: 24) {
            Button {
                Theme.haptic(.light)
                // Previous paragraph navigation
            } label: {
                Image(systemName: "chevron.up")
                    .font(.body)
                    .foregroundColor(viewModel.readingTheme.textColor.opacity(0.6))
            }
            .accessibilityLabel("Previous section")

            Text("\(viewModel.highlights.count) highlights")
                .font(.caption)
                .foregroundColor(viewModel.readingTheme.textColor.opacity(0.6))

            Button {
                Theme.haptic(.light)
                // Next paragraph navigation
            } label: {
                Image(systemName: "chevron.down")
                    .font(.body)
                    .foregroundColor(viewModel.readingTheme.textColor.opacity(0.6))
            }
            .accessibilityLabel("Next section")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(viewModel.readingTheme.backgroundColor.opacity(0.95))
        .clipShape(Capsule())
        .padding(.bottom, 8)
    }

    private var readingParagraphs: [String] {
        let content = viewModel.article.bodyContent.isEmpty
            ? (viewModel.article.articleDescription.isEmpty
                ? "Article content could not be loaded. Please check your internet connection and try again."
                : viewModel.article.articleDescription)
            : viewModel.article.bodyContent
        return content.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }
}

struct HighlightableText: View {
    let text: String
    let highlights: [Highlight]
    let textColor: Color
    let fontSize: CGFloat
    let onHighlight: (String) -> Void

    var body: some View {
        Text(text)
            .font(.system(size: max(fontSize, 17), design: .serif))
            .foregroundColor(textColor)
            .lineSpacing(8)
            .textSelection(.enabled)
            .onTapGesture(count: 2) {
                // Double-tap to highlight selected text
                onHighlight(text)
            }
    }
}

struct HighlightPickerSheet: View {
    let text: String
    @Binding var selectedColor: HighlightColor
    let onSave: (HighlightColor) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Preview
                    Text(text)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .lineLimit(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))

                    // Color picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Highlight Color")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: 16) {
                            ForEach(HighlightColor.allCases, id: \.self) { color in
                                Button {
                                    Theme.haptic(.light)
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color.hex))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                                        )
                                        .shadow(color: selectedColor == color ? Color(hex: color.hex).opacity(0.5) : Color.clear, radius: 8)
                                }
                                .accessibilityLabel("Highlight color: \(color.rawValue)")
                            }
                        }
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Highlight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Theme.haptic(.light)
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .foregroundColor(.textSecondary)
                    .accessibilityLabel("Cancel highlight")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Theme.haptic(.success)
                        onSave(selectedColor)
                        dismiss()
                    } label: {
                        Text("Save")
                    }
                    .foregroundColor(.primary)
                    .accessibilityLabel("Save highlight")
                }
            }
        }
    }
}

struct BookmarkSheet: View {
    let bookmarks: [Bookmark]
    let onSave: (String, Double) -> Void
    let onDelete: (Bookmark) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var position: Double = 0.5

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Existing bookmarks
                    if !bookmarks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bookmarks")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            ForEach(bookmarks) { bookmark in
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundColor(.primary)

                                    Text(bookmark.label)
                                        .font(.body)
                                        .foregroundColor(.textPrimary)

                                    Spacer()

                                    Button {
                                        Theme.haptic(.warning)
                                        onDelete(bookmark)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.error)
                                    }
                                    .accessibilityLabel("Delete bookmark: \(bookmark.label)")
                                }
                                .padding(12)
                                .background(Color.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
                            }
                        }
                    }

                    // Add bookmark
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add Bookmark")
                            .font(.headline)
                            .foregroundColor(.textPrimary)

                        TextField("Bookmark label", text: $label)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding(12)
                            .background(Color.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Position in article: \(Int(position * 100))%")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Slider(value: $position, in: 0...1)
                                .tint(.primary)
                        }

                        Button {
                            Theme.haptic(.success)
                            onSave(label.isEmpty ? "Bookmark" : label, position)
                            label = ""
                            dismiss()
                        } label: {
                            Text("Add Bookmark")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.primary)
                                .foregroundColor(.background)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
                        }
                        .accessibilityLabel("Add bookmark at current position")
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Theme.haptic(.light)
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .foregroundColor(.primary)
                    .accessibilityLabel("Done with bookmarks")
                }
            }
        }
    }
}

struct ReadingSettingsSheet: View {
    @Bindable var viewModel: ReadingViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                VStack(spacing: 32) {
                    fontSizeSection
                    themeSection
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Reading Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Font Size")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                ForEach(ReadingViewModel.FontSize.allCases, id: \.self) { size in
                    fontSizeButton(for: size)
                }
            }
        }
    }

    private func fontSizeButton(for size: ReadingViewModel.FontSize) -> some View {
        Button {
            Theme.haptic(.light)
            viewModel.fontSize = size
        } label: {
            Text(size.rawValue)
                .font(.body)
                .fontWeight(viewModel.fontSize == size ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.fontSize == size ? Color.primary : Color.surface)
                .foregroundColor(viewModel.fontSize == size ? Color.background : Color.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
        }
        .accessibilityLabel("Font size: \(size.rawValue)")
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Theme")
                .font(.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: 12) {
                ForEach(ReadingViewModel.ReadingTheme.allCases, id: \.self) { theme in
                    themeButton(for: theme)
                }
            }
        }
    }

    private func themeButton(for theme: ReadingViewModel.ReadingTheme) -> some View {
        let isSelected = viewModel.readingTheme == theme
        return Button {
            Theme.haptic(.light)
            viewModel.readingTheme = theme
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(theme.backgroundColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primary : Color.separator, lineWidth: 2)
                    )

                Text(theme.rawValue)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .accessibilityLabel("Reading theme: \(theme.rawValue)")
    }
}

#Preview {
    NavigationStack {
        ReadingView(article: Article(
            url: "https://example.com",
            title: "How to Build a Reading Habit That Actually Sticks",
            domain: "example.com",
            articleDescription: "Reading more is a common goal.",
            readingTimeMinutes: 8
        ))
    }
}
