import SwiftUI

/// Persistent header owned by the independent Analytics tab's stack.
struct AnalyticsNavigationHeader: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let state: AnalyticsNavigationHeaderState
    @Namespace private var controlsNamespace

    var body: some View {
        SpendyGlassEffectContainer(spacing: 12) {
            AnalyticsNavigationControls(state: state, namespace: controlsNamespace)
                .animation(reduceMotion ? nil : AppMotion.fluidSpring, value: state.title)
        }
    }
}
