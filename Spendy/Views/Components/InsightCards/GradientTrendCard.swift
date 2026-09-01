//
//  GradientTrendCard.swift
//  Spendy
//
//  Card Design: Average Spent with Gradient Floor Block (Inspired by Clean Financial Apps)
//  Features:
//  - Clean header label "Avg spent"
//  - Large primary figure (e.g. ₹19.2K)
//  - Subtle dark gradient block with crisp accent top-line
//  - Clean subtitle "Per week"
//

import SwiftUI

struct GradientTrendCard: View {
    let title: String // e.g. "Avg spent"
    let value: String // e.g. "₹19.2K"
    let subtitle: String // e.g. "Per week"
    var lineColor: Color = Color.blue.opacity(0.85)
    var action: (() -> Void)? = nil
    
    var body: some View {
        InsightCardShell(action: action, accessibilityLabel: "\(title), \(value), \(subtitle)") {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Header Label
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer(minLength: 6)
                
                // 2. Primary Value
                Text(value)
                    .spendyNumberFont(size: 30, weight: .bold, tracking: -0.5)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Spacer(minLength: 12)
                
                // 3. Gradient Fill Block with Accent Top-Line
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    SpendyColors.cardBackgroundSecondary,
                                    SpendyColors.cardBackgroundSecondary.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 38)
                    
                    // Accent Top-Line
                    Path { path in
                        path.move(to: CGPoint(x: 4, y: 0))
                        path.addLine(to: CGPoint(x: 200, y: 0))
                    }
                    .stroke(lineColor, lineWidth: 2)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(height: 38)
                
                Spacer(minLength: 10)
                
                // 4. Subtitle
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            GradientTrendCard(
                title: "Avg spent",
                value: "₹19.2K",
                subtitle: "Per week",
                lineColor: .blue
            )
            
            GradientTrendCard(
                title: "Monthly Burn",
                value: "₹42.5K",
                subtitle: "On pace with budget",
                lineColor: .green
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
