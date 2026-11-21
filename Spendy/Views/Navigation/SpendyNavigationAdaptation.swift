import SwiftUI

extension EnvironmentValues {
    @Entry var spendyUsesSystemNavigation = false
}

struct SpendySystemNavigationPreference: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// Read inside each navigation destination, where the system supplies bar geometry.
struct SpendyNavigationAdaptation: ViewModifier {
    @Environment(\.spendyUsesSystemNavigation) private var usesSystemNavigation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 27.1, *) {
                content.modifier(SpendyVerticalNavigationAdaptation())
            } else {
                content.preference(key: SpendySystemNavigationPreference.self,
                                   value: horizontalSizeClass == .regular)
            }
        }
        // Bar preferences must originate inside the tab's navigation content.
        // Applying this to TabView itself leaves its native bar visible on iPhone.
        .toolbarVisibility(usesSystemNavigation ? .automatic : .hidden, for: .tabBar)
    }
}

@available(iOS 27.1, *)
private struct SpendyVerticalNavigationAdaptation: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.toolbarVerticalEdge) private var verticalEdge

    func body(content: Content) -> some View {
        content.preference(key: SpendySystemNavigationPreference.self,
                           value: horizontalSizeClass == .regular || verticalEdge != nil)
    }
}
