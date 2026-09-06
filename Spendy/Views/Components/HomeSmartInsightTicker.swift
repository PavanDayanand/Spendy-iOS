//
//  HomeSmartInsightTicker.swift
//  Spendy
//
//  One insight at a time, scrolling up like a feed entry every 5 seconds.
//  See all / Show less pins or restores the ticker. Body sits in a card.
//

import SwiftUI

struct HomeSmartInsightTicker: View {
    let moments: [InsightMoment]
    var onSelectDestination: ((InsightDestination) -> Void)? = nil
    
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
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Show less" : "See all")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(SpendyColors.textSecondary)
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
                insightSentence(current, tappable: false)
                    .frame(maxWidth: .infinity, minHeight: slotHeight, alignment: .topLeading)
                    .offset(y: scrollOffset)
            }
            if let next, moments.count > 1 {
                insightSentence(next, tappable: false)
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
                insightSentence(moment, tappable: true)
                if index < moments.count - 1 {
                    Divider()
                        .overlay(SpendyColors.separator.opacity(0.55))
                }
            }
        }
    }
    
    private func insightSentence(_ moment: InsightMoment, tappable: Bool) -> some View {
        let content = VStack(alignment: .leading, spacing: 4) {
            ShinyText(
                text: moment.headline,
                font: .system(size: 15, weight: .semibold),
                color: Color(hex: "#b5b5b5"),
                shineColor: Color.white,
                speed: 2,
                delay: 0,
                spread: 120,
                direction: .left
            )
            if let supporting = moment.supportingText, !supporting.isEmpty {
                Text(supporting)
                    .font(AppTypography.footnoteMedium)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
}
