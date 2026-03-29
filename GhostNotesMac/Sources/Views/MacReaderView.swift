import SwiftUI

struct MacReaderView: View {
    let article: Article
    @Bindable var viewModel: MacLibraryViewModel
    @State private var fontSize: CGFloat = 18
    @State private var useSerif = true
    @State private var showingHighlights = false
    @State private var showingAI = false

    var body: some View {
        VStack(spacing: 0) {
            // Reader toolbar
            readerToolbar

            Divider()
                .background(Color.macSeparator)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Article header
                    articleHeader

                    Divider()
                        .background(Color.macSeparator)

                    // Article body
                    articleBody

                    // Article footer
                    articleFooter
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 32)
                .frame(maxWidth: 720)
            }
        }
        .background(Color.macBackground)
        .sheet(isPresented: $showingAI) {
            MacAIHighlightsView(article: article)
        }
    }

    private var readerToolbar: some View {
        HStack(spacing: 12) {
            // Font size controls
            HStack(spacing: 8) {
                Button {
                    fontSize = max(14, fontSize - 2)
                } label: {
                    Image(systemName: "textformat.size.smaller")
                        .font(.caption)
                        .foregroundColor(.macTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.macSurfaceElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text("\(Int(fontSize))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.macTextTertiary)
                    .frame(width: 24)

                Button {
                    fontSize = min(28, fontSize + 2)
                } label: {
                    Image(systemName: "textformat.size.larger")
                        .font(.caption)
                        .foregroundColor(.macTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.macSurfaceElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 20)
                    .background(Color.macSeparator)

                Button {
                    useSerif.toggle()
                } label: {
                    Text(useSerif ? "Aa" : "Aa")
                        .font(.system(size: 12, weight: .medium, design: useSerif ? .serif : .default))
                        .foregroundColor(.macTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.macSurfaceElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Article actions
            HStack(spacing: 8) {
                Button {
                    showingAI = true
                } label: {
                    Label("AI Summary", systemImage: "sparkles")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.macPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.macPrimary.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if !article.isRead {
                    Button {
                        Task { await viewModel.markAsRead(article) }
                    } label: {
                        Text("Mark as Read")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.macTextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.macSurfaceElevated)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Task { await viewModel.archiveArticle(article) }
                } label: {
                    Image(systemName: "archivebox")
                        .font(.caption)
                        .foregroundColor(.macTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.macSurfaceElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.macSurface)
    }

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(article.domain)
                .font(.caption.weight(.medium))
                .foregroundColor(.macPrimary)
                .textCase(.uppercase)
                .tracking(1)

            Text(article.title)
                .font(useSerif ? .system(size: fontSize + 10, weight: .bold, design: .serif) : .system(size: fontSize + 10, weight: .bold))
                .foregroundColor(.macTextPrimary)
                .lineSpacing(4)

            HStack(spacing: 12) {
                Label(formatDate(article.savedAt), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.macTextSecondary)

                Label("\(article.readingTimeMinutes) min read", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.macTextSecondary)

                if article.readingProgress > 0 {
                    Label("\(Int(article.readingProgress * 100))% complete", systemImage: "chart.bar")
                        .font(.caption)
                        .foregroundColor(.macPrimary)
                }
            }
        }
    }

    private var articleBody: some View {
        Group {
            if article.bodyContent.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.macGhost)
                    Text("Full article content not available")
                        .font(.subheadline)
                        .foregroundColor(.macTextSecondary)
                    if let url = URL(string: article.url) {
                        Link(destination: url) {
                            Text("Open original article")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.macPrimary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Text(article.bodyContent)
                    .font(useSerif ? .system(size: fontSize, design: .serif) : .system(size: fontSize))
                    .foregroundColor(.macTextPrimary)
                    .lineSpacing(fontSize * 0.5)
                    .textSelection(.enabled)
            }
        }
    }

    private var articleFooter: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.macSeparator)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Source")
                        .font(.caption2)
                        .foregroundColor(.macTextTertiary)
                    if let url = URL(string: article.url) {
                        Link(destination: url) {
                            Text(article.url)
                                .font(.caption)
                                .foregroundColor(.macPrimary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.top, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    MacReaderView(
        article: Article(
            url: "https://example.com/article",
            title: "The Future of SwiftUI: What's New in iOS 26",
            domain: "example.com",
            articleDescription: "A deep dive into the latest SwiftUI features",
            bodyContent: "SwiftUI continues to evolve with each release, bringing new capabilities that make building macOS and iOS apps more expressive and performant than ever before. In this article, we explore the key improvements coming in the latest SDK.",
            readingTimeMinutes: 8,
            savedAt: Date()
        ),
        viewModel: MacLibraryViewModel()
    )
    .frame(width: 700, height: 700)
}
