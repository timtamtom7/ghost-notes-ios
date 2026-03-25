import SwiftUI

struct AddArticleSheet: View {
    @EnvironmentObject var articleStore: ArticleStore
    @Environment(\.dismiss) var dismiss
    @State private var urlText = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    private var isValidURL: Bool {
        guard !urlText.isEmpty else { return false }
        if let url = URL(string: urlText) {
            return url.scheme == "http" || url.scheme == "https"
        }
        return false
    }

    private var urlValidationMessage: String? {
        if urlText.isEmpty { return nil }
        return isValidURL ? nil : "Please enter a valid URL (e.g., https://example.com)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.sectionSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Article URL")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Theme.textSecondary)

                        HStack(spacing: 12) {
                            TextField("https://example.com/article", text: $urlText)
                                .keyboardType(.URL)
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Theme.surfaceSecondary)
                                .cornerRadius(Theme.cornerRadiusButton)

                            Button {
                                if let pasteboardString = UIPasteboard.general.string {
                                    urlText = pasteboardString
                                }
                            } label: {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.title3)
                                    .foregroundColor(Theme.accent)
                            }
                        }

                        if let message = urlValidationMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(Theme.destructive)
                        }
                    }

                    Button {
                        saveArticle()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save Article")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValidURL ? Theme.accent : Theme.accent.opacity(0.4))
                        .cornerRadius(Theme.cornerRadiusButton)
                    }
                    .disabled(!isValidURL || isSaving)

                    Spacer()
                }
                .padding(.horizontal, Theme.screenMargin)
                .padding(.top, 24)
            }
            .navigationTitle("Add Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accent)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Article Saved", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("The article has been added to your library.")
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func saveArticle() {
        isSaving = true
        Task {
            do {
                _ = try await articleStore.addArticle(url: urlText)
                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    AddArticleSheet()
        .environmentObject(ArticleStore())
}
