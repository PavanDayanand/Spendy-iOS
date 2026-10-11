//
//  ShinyInsightText.swift
//  Spendy
//
//  Restrained, premium Apple-like emphasized text treatment with accessibility and Reduce Motion support.
//

import SwiftUI

struct ShinyInsightText: View {
    let text: String
    var font: Font = .system(size: 15.5, weight: .bold)
    var isEmphasized: Bool = true
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        if isEmphasized && !reduceMotion {
            Text(text)
                .font(font)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            SpendyColors.textPrimary,
                            SpendyColors.textSecondary,
                            SpendyColors.textPrimary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        } else {
            Text(text)
                .font(font)
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }
}

/// Headline with the important token in bold, plus the moving shine across the line.
struct ShinyHeadlineText: View {
    let headline: String
    let emphasis: [InsightEmphasis]
    var font: Font = .system(size: 15, weight: .semibold)
    var emphasisFont: Font = .system(size: 15, weight: .bold)
    var color: Color = SpendyColors.textPrimary
    var shineColor: Color = SpendyColors.textPrimary.opacity(0.75)
    var phaseOffset: Double = 0.55
    @Environment(\.colorSchemeContrast) private var contrast
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        let label = emphasizedLine(headline)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        
        if reduceMotion || contrast == .increased || scenePhase != .active {
            label
        } else {
            label
                .overlay {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        InsightShineBand(
                            color: color,
                            shineColor: shineColor,
                            progress: ShinyText.progress(at: context.date, speed: 1.8, delay: 7, direction: .right, phaseOffset: phaseOffset) / 100.0
                        )
                    }
                    .mask(label)
                }
                .mask(label)
        }
    }
    
    private func emphasizedLine(_ text: String) -> Text {
        let tokens: [String] = emphasis.compactMap {
            if case .highlight(let value) = $0 { return value }
            return nil
        }
        
        guard let token = tokens.first(where: { text.contains($0) }),
              let range = text.range(of: token) else {
            return Text(text).font(font).foregroundStyle(color)
        }
        
        let prefix = String(text[..<range.lowerBound])
        let match = String(text[range])
        let suffix = String(text[range.upperBound...])
        
        return Text("\(Text(prefix).font(font))\(Text(match).font(emphasisFont))\(Text(suffix).font(font))").foregroundStyle(color)
    }
}

struct InsightSupportingText: View {
    let text: String
    let emphasis: [InsightEmphasis]
    var font: Font = AppTypography.footnoteMedium
    var color: Color = SpendyColors.textSecondary
    
    var body: some View {
        emphasized
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var emphasized: Text {
        let tokens: [String] = emphasis.compactMap {
            if case .highlight(let value) = $0 { return value }
            return nil
        }
        guard let token = tokens.first(where: { text.contains($0) }),
              let range = text.range(of: token) else {
            return Text(text).font(font).foregroundStyle(color)
        }
        let prefix = String(text[..<range.lowerBound])
        let match = String(text[range])
        let suffix = String(text[range.upperBound...])
        return Text("\(Text(prefix).font(font))\(Text(match).font(font).bold())\(Text(suffix).font(font))").foregroundStyle(color)
    }
}
