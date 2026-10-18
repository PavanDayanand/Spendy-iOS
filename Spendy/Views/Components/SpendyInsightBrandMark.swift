import SwiftUI

/// Shared identity for insights derived from the user's recorded activity.
struct SpendyInsightSymbol: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var resetsDrawing = false

    private var shouldAnimate: Bool { !reduceMotion && scenePhase == .active }

    var body: some View {
        Group {
            if shouldAnimate {
                Image(systemName: SpendyInsightBrandMark.symbol)
                    .symbolEffect(.drawOn.byLayer, options: .speed(0.8), isActive: resetsDrawing)
            } else {
                Image(systemName: SpendyInsightBrandMark.symbol)
            }
        }
        .task(id: shouldAnimate) {
            guard shouldAnimate else { return }
            defer { resetsDrawing = false }
            do {
                while !Task.isCancelled {
                    // DrawOn hides while active; deactivating it draws the symbol back on.
                    resetsDrawing = true
                    try await Task.sleep(for: .milliseconds(120))
                    resetsDrawing = false
                    try await Task.sleep(for: .seconds(3))
                }
            } catch is CancellationError {
                // Leaving the screen or backgrounding the app stops the loop.
            } catch {
                resetsDrawing = false
            }
        }
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
