import SwiftUI

/// A quiet, monochrome empty state with one clear next step.
struct SpendyPlainEmptyState: View {
    let title: String
    let message: String
    var icon: String = "tray"
    var actionTitle: String? = nil
    var compact = false
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            if !compact {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .regular))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .frame(width: 48, height: 48)
                    .background(SpendyColors.textPrimary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(compact ? .subheadline.weight(.semibold) : .title3.weight(.semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                Text(message)
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle) {
                    HapticsManager.shared.trigger(.selection)
                    action()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SpendyColors.textPrimary)
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, compact ? 8 : 12)
    }
}
