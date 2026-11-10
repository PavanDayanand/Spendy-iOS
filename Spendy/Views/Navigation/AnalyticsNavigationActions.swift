import SwiftUI

/// Action content lets the stack owner keep one continuous glass surface.
struct AnalyticsNavigationActions: View {
    @Environment(ExpenseStore.self) private var store
    let state: AnalyticsNavigationHeaderState

    private var trailingAction: StackHeaderAction? {
        if let action = state.primaryAction { return action }
        guard let edit = state.onEdit else { return nil }
        return StackHeaderAction(id: "analytics-stack-edit", title: "Edit \(state.title)",
            symbol: "pencil", perform: edit)
    }

    var body: some View {
        Group {
            if !state.menuItems.isEmpty {
                Menu {
                    ForEach(state.menuItems) { item in
                        Button(role: item.role, action: item.action) {
                            Label(item.title, systemImage: item.isSelected ? "checkmark" : item.systemImage)
                        }
                        .accessibilityIdentifier(item.id)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(state.menuLabel)
                .accessibilityIdentifier(state.menuIdentifier)
                .accessibilityValue(state.menuValue)
            } else if let action = trailingAction {
                Button {
                    HapticsManager.shared.trigger(.selection)
                    action.perform()
                } label: {
                    Image(systemName: action.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(store.accentPreset.contentTint)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(GlassCirclePressStyle())
                .accessibilityLabel(action.title)
                .accessibilityIdentifier(action.id)
            } else {
                Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
            }
        }
        .foregroundStyle(SpendyColors.textPrimary)
    }
}
