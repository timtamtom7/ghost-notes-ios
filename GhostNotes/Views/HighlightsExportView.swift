import SwiftUI

/// R8: Highlights export — Readwise, Markdown, and plain text export
struct HighlightsExportView: View {
    @Bindable var viewModel: LibraryViewModel
    @State private var selectedFormat: ExportFormat = .markdown
    @State private var isExporting = false
    @State private var exportResult: ExportResult?
    @State private var showingShareSheet = false
    @State private var exportedText = ""

    enum ExportFormat: String, CaseIterable {
        case markdown = "Markdown"
        case plainText = "Plain Text"
        case readwise = "Readwise"

        var icon: String {
            switch self {
            case .markdown: return "doc.richtext"
            case .plainText: return "doc.text"
            case .readwise: return "square.and.arrow.up.on.square"
            }
        }

        var description: String {
            switch self {
            case .markdown: return "Formatted notes with article titles and highlights"
            case .plainText: return "Simple text export for any app"
            case .readwise: return "Sync highlights directly to your Readwise account"
            }
        }
    }

    struct ExportResult: Identifiable, Equatable {
        let id = UUID()
        let format: ExportFormat
        let highlightsCount: Int
        let message: String
        let isError: Bool
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            if viewModel.highlights.isEmpty {
                emptyState
            } else {
                exportContent
            }
        }
        .navigationTitle("Export Highlights")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingShareSheet) {
            ShareExportSheet(text: exportedText, format: selectedFormat)
        }
        .alert(item: $exportResult) { result in
            Alert(
                title: Text(result.isError ? "Export Failed" : "Export Complete"),
                message: Text(result.message),
                dismissButton: .default(result.isError ? Text("OK") : Text("Share")) {
                    if !result.isError && (selectedFormat == .markdown || selectedFormat == .plainText) {
                        showingShareSheet = true
                    }
                }
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 56))
                .foregroundColor(.ghost)

            Text("No highlights to export")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text("Highlight text while reading\nto save passages here.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var exportContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Preview section
                previewSection

                // Format picker
                formatPickerSection

                // Export button
                exportButton

                // Summary
                summarySection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("\(min(3, viewModel.highlights.count)) of \(viewModel.highlights.count)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.highlights.prefix(3)) { highlight in
                    HStack(alignment: .top, spacing: 12) {
                        Rectangle()
                            .fill(Color(hex: highlight.color.hex))
                            .frame(width: 4)
                            .clipShape(RoundedRectangle(cornerRadius: 2))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(highlight.text)
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)
                                .lineLimit(3)

                            if let article = articleForHighlight(highlight) {
                                Text(article.title)
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if highlight.id != viewModel.highlights.prefix(3).last?.id {
                        Divider()
                    }
                }

                if viewModel.highlights.count > 3 {
                    Text("+ \(viewModel.highlights.count - 3) more highlights")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var formatPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(.headline)
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    formatRow(format)
                }
            }
        }
    }

    private func formatRow(_ format: ExportFormat) -> some View {
        Button {
            selectedFormat = format
        } label: {
            HStack(spacing: 16) {
                Image(systemName: format.icon)
                    .font(.title3)
                    .foregroundColor(selectedFormat == format ? .primary : .textTertiary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    Text(format.description)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if selectedFormat == format {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(selectedFormat == format ? Color.primary.opacity(0.08) : Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedFormat == format ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(format.rawValue): \(format.description)")
    }

    private var exportButton: some View {
        Button {
            Task { await performExport() }
        } label: {
            HStack(spacing: 8) {
                if isExporting {
                    ProgressView()
                        .tint(.background)
                } else {
                    Image(systemName: selectedFormat == .readwise ? "arrow.triangle.2.circlepath" : "square.and.arrow.up")
                }

                Text(buttonTitle)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.highlights.isEmpty ? Color.ghost : Color.primary)
            .foregroundColor(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.highlights.isEmpty || isExporting)
        .accessibilityLabel(buttonTitle)
    }

    private var buttonTitle: String {
        switch selectedFormat {
        case .markdown, .plainText:
            return "Export & Share"
        case .readwise:
            return "Sync to Readwise"
        }
    }

    private var summarySection: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(viewModel.highlights.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Highlights")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(articlesWithHighlights)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Text("Articles")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text(colorBreakdown)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Text("Colors")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var articlesWithHighlights: Int {
        Set(viewModel.highlights.map { $0.articleId }).count
    }

    private var colorBreakdown: String {
        let colors = Set(viewModel.highlights.map { $0.color })
        return "\(colors.count)/\(HighlightColor.allCases.count)"
    }

    // MARK: - Export Logic

    private func performExport() async {
        isExporting = true

        let allArticles = viewModel.articles + viewModel.archivedArticles

        switch selectedFormat {
        case .markdown, .plainText:
            let text = ExportService.shared.exportAsText(highlights: viewModel.highlights, articles: allArticles)
            exportedText = text
            exportResult = ExportResult(
                format: selectedFormat,
                highlightsCount: viewModel.highlights.count,
                message: "Exported \(viewModel.highlights.count) highlights as \(selectedFormat.rawValue).",
                isError: false
            )

        case .readwise:
            let result = await ExportService.shared.exportToReadwise(
                highlights: viewModel.highlights,
                articles: allArticles
            )
            if result.success {
                exportResult = ExportResult(
                    format: .readwise,
                    highlightsCount: result.highlightsExported,
                    message: "Successfully synced \(result.highlightsExported) highlights to Readwise.",
                    isError: false
                )
            } else {
                exportResult = ExportResult(
                    format: .readwise,
                    highlightsCount: 0,
                    message: result.errorMessage ?? "Export failed. Check your API key.",
                    isError: true
                )
            }
        }

        isExporting = false
    }

    private func articleForHighlight(_ highlight: Highlight) -> Article? {
        (viewModel.articles + viewModel.archivedArticles).first { $0.id == highlight.articleId }
    }
}

// MARK: - Share Export Sheet

struct ShareExportSheet: View {
    let text: String
    let format: HighlightsExportView.ExportFormat
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    TextEditor(text: .constant(text))
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxHeight: .infinity)

                    ShareLink(
                        item: text,
                        subject: Text("My Ghost Notes Highlights"),
                        message: Text("Exported from Ghost Notes")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.primary)
                            .foregroundColor(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Export Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HighlightsExportView(viewModel: LibraryViewModel())
    }
}
