import SwiftUI

struct AISummaryCard: View {
    let summary: String
    let isGenerating: Bool
    let onRegenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("✨ AI Summary")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.accent)

                Spacer()

                Button {
                    onRegenerate()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                    .font(.caption)
                    .foregroundColor(Theme.accentSecondary)
                }
                .opacity(isGenerating ? 0.5 : 1)
            }

            if isGenerating {
                HStack(spacing: 4) {
                    Text("Generating")
                    Text(".")
                    Text(".")
                    Text(".")
                }
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(summary.components(separatedBy: "\n"), id: \.self) { line in
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
                            Text(trimmed)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.textPrimary)
                                .lineSpacing(4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.accent.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusCard)
                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(Theme.cornerRadiusCard)
    }
}

#Preview {
    VStack(spacing: 20) {
        AISummaryCard(
            summary: "• First key insight about the topic\n• Second important point to remember\n• Third takeaway for readers",
            isGenerating: false,
            onRegenerate: {}
        )
        AISummaryCard(
            summary: "",
            isGenerating: true,
            onRegenerate: {}
        )
    }
    .padding()
    .background(Theme.background)
}
