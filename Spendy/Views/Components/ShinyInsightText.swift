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
                            SpendyColors.accentCyan,
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

/// Renders a primary headline where only the emphasized tokens receive the subtle shiny gradient
struct ShinyHeadlineText: View {
    let headline: String
    let emphasis: [InsightEmphasis]
    var font: Font = .system(size: 15.5, weight: .bold)
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        let highlightTokens: [String] = emphasis.compactMap {
            if case .highlight(let text) = $0 { return text }
            return nil
        }
        
        if highlightTokens.isEmpty || reduceMotion {
            Text(headline)
                .font(font)
                .foregroundStyle(SpendyColors.textPrimary)
                .multilineTextAlignment(.leading)
        } else {
            if let targetToken = highlightTokens.first(where: { headline.contains($0) }),
               let range = headline.range(of: targetToken) {
                let prefix = String(headline[..<range.lowerBound])
                let match = String(headline[range])
                let suffix = String(headline[range.upperBound...])
                
                (Text(prefix)
                    .font(font)
                    .foregroundStyle(SpendyColors.textPrimary)
                + Text(match)
                    .font(font)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#00E5FF"),
                                Color(hex: "#70D6FF"),
                                Color(hex: "#00E5FF")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                + Text(suffix)
                    .font(font)
                    .foregroundStyle(SpendyColors.textPrimary))
                .multilineTextAlignment(.leading)
            } else {
                Text(headline)
                    .font(font)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}
