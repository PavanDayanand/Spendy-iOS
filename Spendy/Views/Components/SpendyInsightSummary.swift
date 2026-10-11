import SwiftUI

struct SpendyInsightSummary: View {
    let moments: [InsightMoment]
    var canSelect: (InsightDestination) -> Bool = { _ in true }
    var onSelect: ((InsightDestination) -> Void)? = nil
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var selectedID: String?
    private var page: Int { useful.firstIndex { $0.id == selectedID } ?? 0 }
    private var useful: [InsightMoment] { Array(moments.filter { !$0.isInsufficientData }.prefix(InsightDecisionEngine.maximumMoments)) }

    var body: some View {
        if !useful.isEmpty {
            let moment = useful[min(page, useful.count - 1)]
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SpendyInsightBrandMark(style: .kicker)
                    Spacer()
                }
                .frame(minHeight: 44)
                .overlay(alignment: .trailing) {
                    if useful.count > 1 {
                        Button {
                            advance()
                            HapticsManager.shared.trigger(.selection)
                        } label: {
                            HStack(spacing: 8) {
                                Text("\(page + 1) / \(useful.count)")
                                Image(systemName: "arrow.right")
                            }
                            .font(.caption2.weight(.medium).monospacedDigit())
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(minWidth: 60, minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Next insight")
                        .accessibilityValue("Insight \(page + 1) of \(useful.count)")
                        .accessibilityIdentifier("next-insight")
                    }
                }
                Group {
                    if let destination = moment.destination, let onSelect, canSelect(destination) {
                        Button { onSelect(destination) } label: {
                            HStack(alignment: .center, spacing: 8) {
                                text(moment)
                                Image(systemName: "chevron.right")
                                    .font(.caption).foregroundStyle(SpendyColors.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    } else {
                        text(moment)
                    }
                }
                .id(moment.id)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 6)),
                    removal: .opacity
                ))
            }
            .task(id: rotationKey) {
                // Changing pages cancels this task and starts a fresh reading interval.
                guard useful.count > 1, scenePhase == .active, !voiceOverEnabled, !reduceMotion else { return }
                #if DEBUG
                guard ProcessInfo.processInfo.environment["SPENDY_DISABLE_INSIGHT_ROTATION"] != "1" else { return }
                #endif
                do { try await Task.sleep(for: .seconds(8)) }
                catch { return }
                guard !Task.isCancelled else { return }
                advance()
            }
            .onChange(of: useful.map(\.id)) { _, ids in
                if let selectedID, !ids.contains(selectedID) { self.selectedID = nil }
            }
        }
    }

    private var rotationKey: [String] {
        useful.map(\.id) + [selectedID ?? "", scenePhase == .active ? "active" : "paused", voiceOverEnabled ? "voiceover" : "visual", reduceMotion ? "still" : "animated"]
    }

    private func advance() {
        guard useful.count > 1 else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            selectedID = useful[(page + 1) % useful.count].id
        }
    }

    private func text(_ moment: InsightMoment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ShinyHeadlineText(headline: moment.headline, emphasis: moment.emphasis,
                              font: .subheadline.weight(.semibold), emphasisFont: .subheadline.bold())
            if let supporting = moment.supportingText {
                InsightSupportingText(text: supporting, emphasis: moment.emphasis, font: .footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
