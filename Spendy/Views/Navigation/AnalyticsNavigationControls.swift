import SwiftUI

/// Header content shares its owner's glass container and namespace.
struct AnalyticsNavigationControls: View {
    let state: AnalyticsNavigationHeaderState
    let namespace: Namespace.ID

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

            if !state.menuItems.isEmpty {
                Menu {
                    ForEach(state.menuItems) { item in
                        Button(action: item.action) {
                            Label(item.title, systemImage: item.isSelected ? "checkmark" : item.systemImage)
                        }
                        .accessibilityIdentifier(item.id)
                    }
                } label: {
                    GlassCircleIcon(icon: "ellipsis", size: 44, iconSize: 15,
                        morphID: "topControl_right", namespace: namespace)
                }
                .accessibilityLabel(state.menuLabel)
                .accessibilityIdentifier(state.menuIdentifier)
                .accessibilityValue(state.menuValue)
            } else if let edit = state.onEdit {
                GlassCircleButton(icon: "pencil", size: 44, iconSize: 15,
                    accessibilityLabel: "Edit \(state.title)",
                    morphID: "topControl_right", namespace: namespace, action: edit)
                    .accessibilityIdentifier("analytics-stack-edit")
            } else {
                Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
            }
        }
        .frame(height: 44)
        .foregroundStyle(SpendyColors.textPrimary)
    }
}
