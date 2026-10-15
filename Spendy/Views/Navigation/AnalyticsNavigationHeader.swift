import SwiftUI

/// One fixed Back control while Analytics pushes and pops entity details.
struct AnalyticsNavigationHeader: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let state: AnalyticsNavigationHeaderState
    @Namespace private var controlsNamespace

    var body: some View {
        SpendyGlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                GlassCircleButton(icon: "chevron.left", size: 44, iconSize: 15,
                    accessibilityLabel: "Back", morphID: "analyticsStackBack",
                    namespace: controlsNamespace) {
                    state.onBack?()
                }
                .accessibilityIdentifier("analytics-stack-back")

                Spacer(minLength: 0)

                VStack(spacing: 1) {
                    Text(state.title)
                        .font(.headline)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("analytics-stack-title")
                    if let subtitle = state.subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(SpendyColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

                Spacer(minLength: 0)

                if let edit = state.onEdit {
                    GlassCircleButton(icon: "pencil", size: 44, iconSize: 15,
                        accessibilityLabel: "Edit \(state.title)",
                        morphID: "analyticsStackEdit", namespace: controlsNamespace,
                        action: edit)
                        .accessibilityIdentifier("analytics-stack-edit")
                } else {
                    Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
                }
            }
            .frame(height: 44)
            .foregroundStyle(SpendyColors.textPrimary)
            .animation(reduceMotion ? nil : AppMotion.fluidSpring, value: state.title)
        }
    }
}
