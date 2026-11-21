import SwiftUI

/// Keeps per-frame gesture updates out of Home's chart and transaction queries.
struct HomeActivityDrawer<Content: View>: View {
    let totalHeight: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat
    var isInline = false
    @Binding var isExpanded: Bool
    @ViewBuilder let content: (CGFloat, AnyGesture<DragGesture.Value>) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var translation: CGFloat = 0

    private var restingOffset: CGFloat {
        let compactHeight: CGFloat = 72 + 3 * 60 + 42 + 56 + bottomInset
        return max(totalHeight * 0.55, totalHeight - compactHeight)
    }

    // The host keeps the drawer below the native toolbar; retain a small gap there.
    private var expandedOffset: CGFloat { topInset + 10 }

    private var currentOffset: CGFloat {
        let raw = (isExpanded ? expandedOffset : restingOffset) + translation
        if raw < expandedOffset { return expandedOffset - resistance(expandedOffset - raw) }
        if raw > restingOffset { return restingOffset + resistance(raw - restingOffset) }
        return raw
    }

    var body: some View {
        let expansion = isInline ? 1 : min(1, max(0, (restingOffset - currentOffset) / max(1, restingOffset - expandedOffset)))
        content(expansion, AnyGesture(drag))
            .frame(maxWidth: .infinity)
            .frame(height: isInline ? totalHeight : max(100, totalHeight - currentOffset))
            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(SpendyColors.recentActivityBackground)

                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(SpendyColors.separator.opacity(0.8), lineWidth: 0.8)
                    }
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 20, x: 0, y: -4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(.horizontal, 8 * (1 - expansion))
            .offset(y: isInline ? 0 : currentOffset)
            .onChange(of: totalHeight) { _, _ in translation = 0 }
    }

    private var drag: some Gesture<DragGesture.Value> {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                guard !isInline else { return }
                guard abs(value.translation.height) >= 8 || abs(value.translation.width) <= abs(value.translation.height) else { return }
                withAnimation(reduceMotion ? nil : .interactiveSpring()) {
                    translation = value.translation.height
                }
            }
            .onEnded { value in
                guard !isInline else { return }
                let base = isExpanded ? expandedOffset : restingOffset
                let target: Bool
                if value.velocity.height < -350 { target = true }
                else if value.velocity.height > 350 { target = false }
                else { target = base + value.translation.height < (restingOffset + expandedOffset) / 2 }
                HapticsManager.shared.trigger(.selection)
                withAnimation(reduceMotion ? nil : .spring()) {
                    isExpanded = target
                    translation = 0
                }
            }
    }

    private func resistance(_ distance: CGFloat) -> CGFloat {
        distance * 96 / (distance + 96)
    }
}
