import SwiftUI

/// A deliberately small palette for primary actions, independent of financial status colors.
enum SpendyAccentPreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case blue, green, pink, yellow, white

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var fill: Color {
        switch self {
        case .blue: Color(hex: "#0A84FF")
        case .green: Color(hex: "#30D158")
        case .pink: Color(hex: "#FF6482")
        case .yellow: Color(hex: "#FFD60A")
        case .white: .white
        }
    }

    // All five fills support a dark label, including yellow and white.
    var foreground: Color { .black }
}
