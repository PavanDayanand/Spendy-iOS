import Foundation

enum HomeGradientStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case blueAura
    case indigo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blueAura: "Blue Aura"
        case .indigo: "Indigo"
        }
    }
}
