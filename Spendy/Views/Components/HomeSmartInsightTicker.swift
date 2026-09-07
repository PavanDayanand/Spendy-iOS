//
//  HomeSmartInsightTicker.swift
//  Spendy
//
//  One insight at a time, scrolling up like a feed entry every 5 seconds.
//  Chevron expands or collapses the ticker. Body sits in a card.
//

import SwiftUI

struct HomeSmartInsightTicker: View {
    let moments: [InsightMoment]
    var onSelectDestination: ((InsightDestination) -> Void)? = nil
    
    @Environment(ExpenseStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index: Int = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isExpanded: Bool = false
    
    private let slotHeight: CGFloat = 76
    private let slideDuration: Double = 0.9
    
    private var current: InsightMoment? {
        guard moments.indices.contains(index) else { return moments.first }
        return moments[index]
    }
    
    private var next: InsightMoment? {
        guard moments.count > 1 else { return nil }
        return moments[(index + 1) % moments.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                SpendyInsightBrandMark(style: .header)
                
                Spacer()
                
                if moments.count > 1 {
                    Button(action: toggleExpanded) {
                        Image(systemName: isExpanded ? SFIcons.chevronUp : SFIcons.chevronDown)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isExpanded ? "Show less insights" : "See all insights")
                }
            }
            
            Group {
                if isExpanded {
                    stackedList
                } else {
                    scrollWindow
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if moments.count > 1 {
                                toggleExpanded()
                            } else if let destination = current?.destination {
                                HapticsManager.shared.trigger(.selection)
                                onSelectDestination?(destination)
                            }
                        }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
        .gesture(expandGesture)
        .task(id: cycleKey) {
            guard !isExpanded else { return }
            await runCycle()
        }
    }
    
    private var cycleKey: String {
        moments.map(\.id).joined(separator: "|") + (isExpanded ? "|open" : "|tick")
    }
    
    private var scrollWindow: some View {
        ZStack(alignment: .topLeading) {
            if let current {
                insightSentence(current, tappable: false, showBadge: false)
                    .frame(maxWidth: .infinity, minHeight: slotHeight, alignment: .topLeading)
                    .offset(y: scrollOffset)
            }
            if let next, moments.count > 1 {
                insightSentence(next, tappable: false, showBadge: false)
                    .frame(maxWidth: .infinity, minHeight: slotHeight, alignment: .topLeading)
                    .offset(y: scrollOffset + slotHeight)
            }
        }
        .frame(height: slotHeight, alignment: .top)
        .clipped()
    }
    
    private var stackedList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                insightSentence(moment, tappable: true, showBadge: true)
                if index < moments.count - 1 {
                    Divider()
                        .overlay(SpendyColors.separator.opacity(0.55))
                }
            }
        }
    }
    
    private func insightSentence(_ moment: InsightMoment, tappable: Bool, showBadge: Bool) -> some View {
        let textBlock = VStack(alignment: .leading, spacing: 4) {
            ShinyHeadlineText(
                headline: moment.headline,
                emphasis: moment.emphasis,
                font: .system(size: 15, weight: .semibold),
                emphasisFont: .system(size: 15, weight: .bold)
            )
            if let supporting = moment.supportingText, !supporting.isEmpty {
                InsightSupportingText(text: supporting, emphasis: moment.emphasis)
            }
        }
        
        let content = HStack(alignment: .top, spacing: 12) {
            if let symbol = relatedSymbol(for: moment), showBadge {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .frame(width: 22, height: 22)
                    .padding(.top, 1)
                    .symbolRenderingMode(.monochrome)
            }
            textBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(moment.headline). \(moment.supportingText ?? "")")
        
        return Group {
            if tappable, let destination = moment.destination {
                Button {
                    HapticsManager.shared.trigger(.selection)
                    onSelectDestination?(destination)
                } label: {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
    }
    
    private func toggleExpanded() {
        HapticsManager.shared.trigger(.selection)
        withAnimation(.easeInOut(duration: 0.35)) {
            isExpanded.toggle()
            if !isExpanded {
                scrollOffset = 0
            }
        }
    }
    
    private var expandGesture: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) else { return }
                guard moments.count > 1 else { return }
                
                if horizontal < -40, !isExpanded {
                    toggleExpanded()
                } else if horizontal > 40, isExpanded {
                    toggleExpanded()
                }
            }
    }
    
    @MainActor
    private func runCycle() async {
        guard moments.count > 1 else { return }
        index = min(index, moments.count - 1)
        scrollOffset = 0
        
        let slide = reduceMotion
            ? Animation.easeInOut(duration: 0.35)
            : Animation.easeInOut(duration: slideDuration)
        
        while !Task.isCancelled && !isExpanded {
            try? await Task.sleep(for: .seconds(5))
            if Task.isCancelled || isExpanded { return }
            
            withAnimation(slide) {
                scrollOffset = -slotHeight
            }
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 360 : 920))
            if Task.isCancelled || isExpanded { return }
            
            index = (index + 1) % moments.count
            scrollOffset = 0
        }
    }
    
    private func relatedSymbol(for moment: InsightMoment) -> String? {
        switch moment.destination {
        case .category(let id):
            return store.categories.first(where: { $0.id == id })?.sfSymbol ?? "square.grid.2x2"
        case .subscriptionDetail(let id):
            return store.subscriptions.first(where: {
                $0.id.uuidString.lowercased() == id.lowercased()
            })?.sfSymbol ?? SFIcons.subscriptions
        case .subscriptions:
            return SFIcons.subscriptions
        case .budget:
            return SFIcons.tabBudget
        case .transaction(_):
            return "receipt"
        case .analytics, nil:
            break
        }
        
        switch moment.family {
        case .income: return "arrow.down.left"
        case .anomaly: return "exclamationmark.triangle"
        case .budget: return SFIcons.tabBudget
        case .spending: return "chart.bar"
        case .behavior: return "calendar"
        case .category: return "square.grid.2x2"
        case .subscription: return SFIcons.subscriptions
        }
    }
}
