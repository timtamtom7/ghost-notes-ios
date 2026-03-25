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
        // R5: Fetch article metadata and body content for offline reading
        let domain = url.host?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString
        let savedAt = Date()

        var title = domain.capitalized
        var articleDescription = "Saved from \(domain)"
        var bodyContent = ""

        // Attempt to fetch and extract article content for offline reading
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) {
                // Extract title
                if let titleRange = html.range(of: "<title>"),
                   let titleEndRange = html.range(of: "</title>") {
                    let rawTitle = String(html[titleRange.upperBound..<titleEndRange.lowerBound])
                    let cleanTitle = rawTitle.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanTitle.isEmpty { title = cleanTitle }
                }
                // Extract meta description
                let metaPatterns = [
                    "<meta name=\"description\" content=\"([^\"]+)\"",
                    "<meta property=\"og:description\" content=\"([^\"]+)\""
                ]
                for pattern in metaPatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                       let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                       let range = Range(match.range(at: 1), in: html) {
                        articleDescription = String(html[range])
                        break
                    }
                }
                // Extract body content
                var cleaned = html
                let removePatterns = [
                    "<script[^>]*>[\\s\\S]*?</script>",
                    "<style[^>]*>[\\s\\S]*?</style>",
                    "<nav[^>]*>[\\s\\S]*?</nav>",
                    "<footer[^>]*>[\\s\\S]*?</footer>",
                    "<header[^>]*>[\\s\\S]*?</header>",
                    "<aside[^>]*>[\\s\\S]*?</aside>"
                ]
                for pattern in removePatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                        cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
                    }
                }
                cleaned = cleaned.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
                cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
                cleaned = cleaned.replacingOccurrences(of: "&lt;", with: "<")
                cleaned = cleaned.replacingOccurrences(of: "&gt;", with: ">")
                cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")
                cleaned = cleaned.replacingOccurrences(of: "&#39;", with: "'")
                cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
                bodyContent = cleaned
            }
        } catch {
            // Network fetch failed — save with placeholder; user can read online later
        }

        // R5: Calculate reading time from body content
        let wordCount = bodyContent.split(separator: " ").count
        let readingTime = max(1, wordCount / 238)

        // Save to App Group UserDefaults for main app to pick up
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
                "articleDescription": articleDescription,
                "bodyContent": bodyContent,  // R5: Saved for offline reading
                "readingTimeMinutes": readingTime,
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
