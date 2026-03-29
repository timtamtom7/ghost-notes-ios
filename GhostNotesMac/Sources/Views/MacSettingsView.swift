import SwiftUI
import UniformTypeIdentifiers

struct MacSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 18
    @AppStorage("defaultSerif") private var defaultSerif: Bool = true
    @State private var showingExport = false
    @State private var exportMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.macTextPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.macTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.macSurfaceElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Color.macSurface)

            Divider()
                .background(Color.macSeparator)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Reading preferences
                    readingSection

                    Divider()
                        .background(Color.macSeparator)

                    // Data section
                    dataSection

                    Divider()
                        .background(Color.macSeparator)

                    // About section
                    aboutSection
                }
                .padding(20)
            }
        }
        .frame(width: 460, height: 520)
        .background(Color.macBackground)
        .alert("Export", isPresented: $showingExport) {
            Button("OK") {}
        } message: {
            Text(exportMessage ?? "Export complete.")
        }
    }

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Reading", systemImage: "text.alignleft")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.macTextPrimary)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Default font size")
                        .font(.subheadline)
                        .foregroundColor(.macTextSecondary)
                    Spacer()
                    Text("\(Int(defaultFontSize))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.macTextTertiary)
                }
                Slider(value: $defaultFontSize, in: 14...28, step: 1)
                    .tint(.macPrimary)

                HStack {
                    Text("Serif font in reader")
                        .font(.subheadline)
                        .foregroundColor(.macTextSecondary)
                    Spacer()
                    Toggle("", isOn: $defaultSerif)
                        .tint(.macPrimary)
                        .labelsHidden()
                }
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Data", systemImage: "externaldrive")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.macTextPrimary)

            VStack(alignment: .leading, spacing: 10) {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                        Text("Export Articles (JSON)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.macPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.macPrimary.opacity(0.15))
                    .cornerRadius(MacTheme.cornerRadiusSmall)
                }
                .buttonStyle(.plain)

                Text("Export all your saved articles as a JSON file.")
                    .font(.caption)
                    .foregroundColor(.macTextTertiary)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("About", systemImage: "info.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.macTextPrimary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Ghost Notes")
                        .font(.subheadline)
                        .foregroundColor(.macTextPrimary)
                    Spacer()
                    Text("v1.0.0")
                        .font(.caption)
                        .foregroundColor(.macTextTertiary)
                }

                Text("A quiet reading space. Save articles, read distraction-free, let AI surface what matters.")
                    .font(.caption)
                    .foregroundColor(.macTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func exportData() {
        do {
            let active = try DatabaseService.shared.fetchAllArticles()
            let archived = try DatabaseService.shared.fetchArchivedArticles()
            let articles = active + archived
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(articles)

            let panel = NSSavePanel()
            panel.allowedContentTypes = [UTType.json]
            panel.nameFieldStringValue = "ghost-notes-export.json"
            panel.canCreateDirectories = true

            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url)
                exportMessage = "Exported \(articles.count) articles to \(url.lastPathComponent)"
            } else {
                exportMessage = "Export cancelled."
            }
        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
        }
        showingExport = true
    }
}

#Preview {
    MacSettingsView()
}
