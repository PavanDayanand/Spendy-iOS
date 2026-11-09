import SwiftUI

/// Shared label for filter buttons and menus, with the same selection treatment at every size.
struct SpendyFilterControl: View {
    enum Size {
        case small
        case regular

        var height: CGFloat { self == .small ? 38 : 44 }
    }

    var title: String? = nil
    let systemImage: String
    let isSelected: Bool
    var selectedSymbol: String? = nil
    var selectionCount: Int = 1
    var size: Size = .regular
    var onOpen: (() -> Void)? = nil
    var onClear: (() -> Void)? = nil
    var controlIdentifier: String = ""

    private var displayedSymbol: String {
        guard isSelected else { return systemImage }
        return selectionCount == 1 ? (selectedSymbol ?? systemImage) : "line.3.horizontal.decrease"
    }

    private var label: some View {
        HStack(spacing: 6) {
            Image(systemName: displayedSymbol)
                .font(.subheadline.weight(.semibold))
                .accessibilityHidden(true)
            if let title {
                Text(title)
                    .font(size == .small ? .footnote.weight(.semibold) : .subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            if title != nil && onClear == nil {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(SpendyColors.textPrimary)
        .padding(.horizontal, title == nil ? 8 : 14)
        .frame(width: title == nil ? 44 : nil)
        .frame(minWidth: 44, minHeight: size.height)
        .frame(minHeight: 44)
        .contentShape(Capsule())
        .transaction { $0.animation = nil }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title ?? "Filters")
        .accessibilityValue(isSelected ? "Selected" : "Any")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    var body: some View {
        HStack(spacing: 0) {
            if let onOpen {
                Button(action: onOpen) { label }
                    .buttonStyle(.plain)
                    .accessibilityLabel(title ?? "Filters")
                    .accessibilityValue(isSelected ? "Selected" : "Any")
                    .accessibilityIdentifier(controlIdentifier)
            } else {
                label
            }
            if isSelected, let onClear {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear \(title ?? "filter")")
            }
        }
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
