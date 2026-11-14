import SwiftUI

/// A 280-degree budget arc, starting at the lower left and filling clockwise.
struct BudgetProgressArc: View {
    @Environment(ExpenseStore.self) private var store
    let progress: Double?
    var lineWidth: CGFloat = 24
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double { min(max(progress ?? 0, 0), 1) }
    private var tint: Color {
        (progress ?? 0) > 1 ? SpendyColors.warningOrange : store.accentPreset.contentTint
    }

    var body: some View {
        SpendyBudgetArcDrawing(progress: progress, lineWidth: lineWidth, tint: tint,
            track: SpendyColors.textPrimary.opacity(0.09))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: fraction)
        .accessibilityHidden(true)
    }
}
