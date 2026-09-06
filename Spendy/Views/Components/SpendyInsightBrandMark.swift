//
//  SpendyInsightBrandMark.swift
//  Spendy
//
//  Signature lockup for Spendy Insights: sparkle + shiny lowercase wordmark.
//  Use .header on Home, .kicker above insight copy everywhere else.
//

import SwiftUI

struct SpendyInsightBrandMark: View {
    enum Style {
        case header
        case kicker
    }
    
    var style: Style = .header
    
    private var word: String {
        style == .header ? "spendy insights" : "spendy"
    }
    
    private var wordFont: Font {
        switch style {
        case .header: return .system(size: 20, weight: .bold)
        case .kicker: return .system(size: 11, weight: .semibold)
        }
    }
    
    private var sparkleSize: CGFloat {
        style == .header ? 14 : 9
    }
    
    var body: some View {
        HStack(spacing: style == .header ? 7 : 5) {
            Image(systemName: "sparkle")
                .font(.system(size: sparkleSize, weight: .semibold))
                .foregroundStyle(Color(hex: "#b5b5b5"))
                .overlay {
                    LinearGradient(
                        colors: [
                            Color(hex: "#b5b5b5"),
                            Color.white,
                            Color(hex: "#b5b5b5")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(
                        Image(systemName: "sparkle")
                            .font(.system(size: sparkleSize, weight: .semibold))
                    )
                }
            
            ShinyText(
                text: word,
                font: wordFont,
                color: Color(hex: "#b5b5b5"),
                shineColor: Color.white,
                speed: 2,
                delay: 0,
                spread: 120,
                direction: .left
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spendy Insights")
    }
}
