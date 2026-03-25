import Foundation
import SwiftUI

// MARK: - Share Extension

struct ShareService {
    static func handleSharedURL(_ url: URL) async -> Article? {
        guard url.scheme == "ghostnotes" || url.absoluteString.hasPrefix("http") else {
            return nil
        }
        
        let service = ArticleService.shared
        return await service.processURL(url.absoluteString)
    }
}

// MARK: - URL Scheme Helper

enum GhostNotesURLScheme {
    static let scheme = "ghostnotes"
    
    static func articleURL(id: UUID) -> URL? {
        URL(string: "\(scheme)://article/\(id.uuidString)")
    }
    
    static func parseURL(_ url: URL) -> (type: String, id: String)? {
        guard url.scheme == scheme else { return nil }
        let path = url.host ?? ""
        let id = url.pathComponents.dropFirst().first ?? ""
        return (path, id)
    }
}
