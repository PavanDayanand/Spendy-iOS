import Foundation

nonisolated struct WidgetSubscriptionItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let amount: Double
    let renewalDate: Date
    let sfSymbol: String
    let colorHex: String
    let isTrial: Bool
    var cycleStart: Date? = nil
}
