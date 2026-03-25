import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostingController = UIHostingController(rootView: ShareView(controller: self))
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
    
    func done() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

struct ShareView: View {
    let controller: ShareViewController
    @State private var isSaving = false
    @State private var saved = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    controller.done()
                }
            
            VStack(spacing: 20) {
                if saved {
                    savedView
                } else if isSaving {
                    savingView
                } else {
                    promptView
                }
            }
            .padding(24)
            .background(Color(hex: "16161F"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 32)
        }
        .onAppear {
            saveArticle()
        }
    }
    
    private var savedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "34C759"))
            
            Text("Saved to Ghost Notes")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private var savingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
            
            Text("Saving...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private var promptView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "7B6CF6"))
            
            Text("Save to Ghost Notes")
                .font(.headline)
                .foregroundColor(.white)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button("Cancel") {
                controller.done()
            }
            .foregroundColor(.gray)
        }
    }
    
    private func saveArticle() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            errorMessage = "No content found"
            return
        }
        
        isSaving = true
        
        Task {
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    do {
                        let item = try await attachment.loadItem(forTypeIdentifier: UTType.url.identifier)
                        if let url = item as? URL {
                            await saveURL(url)
                            return
                        }
                    } catch {
                        // Try next attachment
                    }
                }
                
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    do {
                        let item = try await attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier)
                        if let text = item as? String, let url = URL(string: text), url.scheme != nil {
                            await saveURL(url)
                            return
                        }
                    } catch {
                        // Try next
                    }
                }
            }
            
            await MainActor.run {
                isSaving = false
                errorMessage = "No URL found to save"
            }
        }
    }
    
    private func saveURL(_ url: URL) async {
        // Extract domain from URL
        let domain = url.host?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString
        let title = domain.capitalized
        let savedAt = Date()
        
        // Save to shared UserDefaults (App Group)
        if let userDefaults = UserDefaults(suiteName: "group.com.tomalabs.ghostnotes") {
            var articles: [[String: Any]] = []
            if let data = userDefaults.data(forKey: "shared_articles"),
               let existing = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                articles = existing
            }
            
            let articleDict: [String: Any] = [
                "id": UUID().uuidString,
                "url": url.absoluteString,
                "title": title,
                "domain": domain,
                "articleDescription": "Saved from \(domain)",
                "readingTimeMinutes": 5,
                "savedAt": savedAt.timeIntervalSince1970
            ]
            articles.insert(articleDict, at: 0)
            
            if let data = try? JSONSerialization.data(withJSONObject: articles) {
                userDefaults.set(data, forKey: "shared_articles")
            }
        }
        
        await MainActor.run {
            isSaving = false
            saved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                controller.done()
            }
        }
    }
}

// Simple Color extension for the share extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
}
