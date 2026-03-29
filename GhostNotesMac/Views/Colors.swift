import SwiftUI

// MARK: - App Colors (shared with iOS app)

extension Color {
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "16161F")
    static let surfaceElevated = Color(hex: "1E1E2A")
    static let primary = Color(hex: "7B6CF6")
    static let accent = Color(hex: "F0E6FF")
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary = Color(hex: "48484A")
    static let separator = Color(hex: "2C2C34")
    static let ghost = Color(hex: "3D3D50")
    static let success = Color(hex: "34C759")
    static let error = Color(hex: "FF453A")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
