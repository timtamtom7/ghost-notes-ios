import SwiftUI

struct ReadingView: View {
    @State private var viewModel: ReadingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    @State private var scrollOffset: CGFloat = 0
    
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
            
            progressBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "textformat.size")
                }
                .tint(viewModel.readingTheme.textColor)
            }
        }
        .toolbarBackground(viewModel.readingTheme.backgroundColor, for: .navigationBar)
        .sheet(isPresented: $showingSettings) {
            ReadingSettingsSheet(viewModel: viewModel)
                .presentationDetents([.height(300)])
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
        .padding(.bottom, 100)
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
        }
        .padding(.top, 16)
    }
    
    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(readingParagraphs, id: \.self) { paragraph in
                Text(paragraph)
                    .font(.custom("NewYork-Regular", size: viewModel.fontSize.size))
                    .foregroundColor(viewModel.readingTheme.textColor)
                    .lineSpacing(8)
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
    
    private var readingParagraphs: [String] {
        // R5: Display actual saved article body, fallback to description if unavailable
        let content = viewModel.article.bodyContent.isEmpty
            ? (viewModel.article.articleDescription.isEmpty
                ? "Article content could not be loaded. Please check your internet connection and try again."
                : viewModel.article.articleDescription)
            : viewModel.article.bodyContent
        return content.components(separatedBy: "\n\n").filter { !$0.isEmpty }
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
            viewModel.fontSize = size
        } label: {
            Text(size.rawValue)
                .font(.body)
                .fontWeight(viewModel.fontSize == size ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.fontSize == size ? Color.primary : Color.surface)
                .foregroundColor(viewModel.fontSize == size ? Color.background : Color.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
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
