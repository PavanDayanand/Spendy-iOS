import SwiftUI

/// A route's actions, rendered by the persistent stack header.
struct AnalyticsNavigationHeaderMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    var isSelected = false
    var role: ButtonRole? = nil
    let action: () -> Void
}
