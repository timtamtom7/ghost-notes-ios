import SwiftUI

enum Theme {
    static let background = Color(hex: "0D0D0D")
    static let surface = Color(hex: "1A1A1A")
    static let surfaceSecondary = Color(hex: "262626")
    static let accent = Color(hex: "8B5CF6")
    static let accentSecondary = Color(hex: "A78BFA")
    static let textPrimary = Color(hex: "F5F5F5")
    static let textSecondary = Color(hex: "A3A3A3")
    static let textTertiary = Color(hex: "525252")
    static let destructive = Color(hex: "EF4444")
    static let success = Color(hex: "22C55E")

    static let cornerRadiusCard: CGFloat = 12
    static let cornerRadiusButton: CGFloat = 8
    static let screenMargin: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
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
