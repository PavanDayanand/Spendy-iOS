import SwiftUI

/// Header content shares its owner's glass container and namespace.
struct AnalyticsNavigationControls: View {
    let state: AnalyticsNavigationHeaderState
    let namespace: Namespace.ID

    var showsTrailingAction = true

    var body: some View {
        HStack(spacing: 12) {
            GlassCircleButton(icon: "chevron.left", size: 44, iconSize: 15,
                accessibilityLabel: "Back", morphID: "topControl_left",
                namespace: namespace) {
                state.onBack?()
            }
            .accessibilityIdentifier("analytics-stack-back")

            Spacer(minLength: 0)

            VStack(spacing: 1) {
                Text(state.title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("analytics-stack-title")
                if let subtitle = state.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            if showsTrailingAction && state.hasActions {
                AnalyticsNavigationActions(state: state)
                    .nativeLiquidGlassCapsule(isInteractive: true)
                    .glassMorphID("topControl_right", in: namespace)
            } else {
                Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
            }
        }
        .frame(height: 44)
        .foregroundStyle(SpendyColors.textPrimary)
    }
}
