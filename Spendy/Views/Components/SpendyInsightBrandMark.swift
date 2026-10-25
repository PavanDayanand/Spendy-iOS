import SwiftUI

/// Shared identity for insights derived from the user's recorded activity.
struct SpendyInsightSymbol: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var appearance = 0
    var body: some View {
        Image(systemName: SpendyInsightBrandMark.symbol)
            .symbolEffect(.pulse, value: appearance)
            .onAppear { if !reduceMotion && scenePhase == .active { appearance += 1 } }
            .accessibilityHidden(true)
    }
}

struct SpendyInsightBrandMark: View {
    static let symbol = "laser.burst"
    enum Style { case header, kicker }
    var style: Style = .header
    var showsPersonalization = true
    @Environment(\.colorSchemeContrast) private var contrast

    private var wordFont: Font {
        style == .header ? .title3.bold() : .caption.weight(.semibold)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 7) {
                SpendyInsightSymbol()
                    .font(style == .header ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .accessibilityHidden(true)
                ShinyText(text: "spendy insights", font: wordFont,
                    color: SpendyColors.textPrimary.opacity(0.85),
                    shineColor: SpendyColors.textPrimary,
                    speed: 1.8, delay: 7, disabled: contrast == .increased)
            }
            if showsPersonalization {
                Text("Based on your activity")
                    .font(.caption2)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spendy Insights, based on your activity")
    }
}
