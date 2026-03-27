import SwiftUI
import UIKit

// MARK: - App Colors

extension Color {
    static let background = Color(hex: "0A0A0F")
    static let surface = Color(hex: "16161F")
    static let surfaceElevated = Color(hex: "1E1E2A")
    static let surfaceTertiary = Color(hex: "26263A")
    static let primary = Color(hex: "7B6CF6")
    static let accent = Color(hex: "F0E6FF")
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "8E8E93")
    static let textTertiary = Color(hex: "48484A")
    static let textQuaternary = Color(hex: "3A3A3C")
    static let separator = Color(hex: "2C2C34")
    static let ghost = Color(hex: "3D3D50")
    static let success = Color(hex: "34C759")
    static let error = Color(hex: "FF453A")
}

extension ShapeStyle where Self == Color {
    static var background: Color { Color.background }
    static var surface: Color { Color.surface }
    static var surfaceElevated: Color { Color.surfaceElevated }
    static var surfaceTertiary: Color { Color.surfaceTertiary }
    static var primary: Color { Color.primary }
    static var accent: Color { Color.accent }
    static var textPrimary: Color { Color.textPrimary }
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary: Color { Color.textTertiary }
    static var textQuaternary: Color { Color.textQuaternary }
    static var separator: Color { Color.separator }
    static var ghost: Color { Color.ghost }
    static var success: Color { Color.success }
    static var error: Color { Color.error }
}

// MARK: - Theme Tokens

enum Theme {
    // Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusPill: CGFloat = 20

    // Spacing
    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32

    // Haptic Feedback
    @MainActor static func haptic(_ style: HapticStyle = .light) {
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        case .soft:
            generator = UIImpactFeedbackGenerator(style: .soft)
        case .rigid:
            generator = UIImpactFeedbackGenerator(style: .rigid)
        case .success:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            return
        case .warning:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.warning)
            return
        case .error:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
            return
        }
        generator.impactOccurred()
    }

    enum HapticStyle {
        case light, medium, heavy, soft, rigid, success, warning, error
    }
}

// MARK: - Button Styles

struct AxiomPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.background)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AxiomSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AxiomDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(.error)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.error.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
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

@main
struct GhostNotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
