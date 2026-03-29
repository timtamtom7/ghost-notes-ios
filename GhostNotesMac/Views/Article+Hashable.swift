import Foundation

// MARK: - macOS requires Hashable for List selection bindings
extension Article: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
