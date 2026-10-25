import Foundation

/// A route's actions, rendered by the persistent stack header.
struct AnalyticsNavigationHeaderMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    var isSelected = false
    let action: () -> Void
}
