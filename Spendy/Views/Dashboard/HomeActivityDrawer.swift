import SwiftUI

/// Keeps per-frame gesture updates out of Home's chart and transaction queries.
struct HomeActivityDrawer<Content: View>: View {
    let totalHeight: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat
    @Binding var isExpanded: Bool
    @ViewBuilder let content: (CGFloat, AnyGesture<DragGesture.Value>) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var translation: CGFloat = 0

    private var restingOffset: CGFloat {
        let compactHeight: CGFloat = 72 + 3 * 60 + 42 + 56 + bottomInset
        return max(totalHeight * 0.55, totalHeight - compactHeight)
    }

    private var expandedOffset: CGFloat { max(topInset + 10, 56) }

    private var currentOffset: CGFloat {
        let raw = (isExpanded ? expandedOffset : restingOffset) + translation
        if raw < expandedOffset { return expandedOffset - resistance(expandedOffset - raw) }
        if raw > restingOffset { return restingOffset + resistance(raw - restingOffset) }
        return raw
    }

    var body: some View {
        let expansion = min(1, max(0, (restingOffset - currentOffset) / max(1, restingOffset - expandedOffset)))
        content(expansion, AnyGesture(drag))
            .frame(maxWidth: .infinity)
            .frame(height: max(100, totalHeight - currentOffset))
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
            .offset(y: currentOffset)
    }

    private var drag: some Gesture<DragGesture.Value> {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                guard abs(value.translation.height) >= 8 || abs(value.translation.width) <= abs(value.translation.height) else { return }
                withAnimation(reduceMotion ? nil : .interactiveSpring()) {
                    translation = value.translation.height
                }
            }
            .onEnded { value in
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
