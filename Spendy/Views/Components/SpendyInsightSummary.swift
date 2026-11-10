import SwiftUI
import TipKit

struct SpendyInsightSummary: View {
    let moments: [InsightMoment]
    var compact = false
    var offersCategoryTip = false
    var categoryTipGroup: TipGroup? = nil
    var canSelect: (InsightDestination) -> Bool = { _ in true }
    var onSelect: ((InsightDestination) -> Void)? = nil
    @Environment(\.spendyTipsAllowed) private var tipsAllowed
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var selectedID: String?
    private var page: Int { useful.firstIndex { $0.id == selectedID } ?? 0 }
    private var useful: [InsightMoment] { Array(moments.filter { !$0.isInsufficientData }.prefix(InsightDecisionEngine.maximumMoments)) }

    var body: some View {
        if !useful.isEmpty {
            let moment = useful[min(page, useful.count - 1)]
            Group {
                if compact {
                    HStack(spacing: 8) {
                        SpendyInsightSymbol().accessibilityHidden(true)
                        Button {
                            if let destination = moment.destination, canSelect(destination) { onSelect?(destination) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                if let label = moment.attentionLabel {
                                    Text(label).font(.caption2.weight(.semibold)).foregroundStyle(SpendyColors.textSecondary)
                                }
                                ShinyHeadlineText(headline: moment.headline, emphasis: moment.emphasis,
                                    font: .caption.weight(.semibold), emphasisFont: .caption.bold())
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home-priority-insight")
                        if useful.count > 1 {
                            Button { advance(); HapticsManager.shared.trigger(.selection) } label: {
                                HStack(spacing: 4) {
                                    Text("\(page + 1)/\(useful.count)")
                                    Image(systemName: "arrow.right")
                                }
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(SpendyColors.textSecondary)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Next insight")
                            .accessibilityIdentifier("home-next-insight")
                            .accessibilityValue("Insight \(page + 1) of \(useful.count)")
                        } else {
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(SpendyColors.textSecondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 8) {
                                SpendyInsightBrandMark(style: .kicker)
                                nextInsightButton
                            }
                        } else {
                            HStack {
                                SpendyInsightBrandMark(style: .kicker)
                                Spacer()
                            }
                            .frame(minHeight: 44)
                            .overlay(alignment: .trailing) { nextInsightButton }
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
                }
            }
            .task(id: rotationKey) {
                // Changing pages cancels this task and starts a fresh reading interval.
                guard (useful.first?.attentionPriority ?? 0) == 0, useful.count > 1, scenePhase == .active, !voiceOverEnabled, !reduceMotion else { return }
                #if DEBUG
                guard ProcessInfo.processInfo.environment["SPENDY_DISABLE_INSIGHT_ROTATION"] != "1" else { return }
                #endif
                do { try await Task.sleep(for: .seconds(8)) }
                catch { return }
                guard !Task.isCancelled else { return }
                advance()
            }
            .onChange(of: useful.map(\.id)) { old, ids in
                if let selectedID, !ids.contains(selectedID) { self.selectedID = nil }
                if old.first != ids.first && (useful.first?.attentionPriority ?? 0) > 0 { selectedID = nil }
            }
        }
    }

    @ViewBuilder
    private var nextInsightButton: some View {
        if useful.count > 1 {
            Button {
                if offersCategoryTip { CategoryNextInsightTip().invalidate(reason: .actionPerformed) }
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
            .popoverTip(tipsAllowed && offersCategoryTip ? categoryTipGroup?.currentTip as? CategoryNextInsightTip : nil)
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
