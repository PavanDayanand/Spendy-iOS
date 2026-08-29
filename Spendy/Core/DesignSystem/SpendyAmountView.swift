//
//  SpendyAmountView.swift
//  Spendy
//
//  Tall Condensed Currency and Balance Typography Component (iOS 16+)
//  Implements:
//  - .fontWidth(.condensed) for a tall, compact vertical stance
//  - Weight: .heavy for punchy contrast
//  - Aggressive negative tracking (-1.5) on main amount
//  - Proportional baseline-aligned decimals with subtle opacity
//

import SwiftUI

struct SpendyAmountView: View {
    let amount: Double
    var currencySymbol: String = "₹"
    var mainSize: CGFloat = 44
    var weight: Font.Weight = .heavy
    var tracking: CGFloat = -1.5
    var isHidden: Bool = false
    var showDecimals: Bool = true
    var color: Color = .white
    var secondaryColor: Color? = nil
    
    private var parts: (sign: String, integer: String, decimal: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = showDecimals ? 2 : 0
        formatter.maximumFractionDigits = showDecimals ? 2 : 0
        
        let absAmount = abs(amount)
        let formattedString = formatter.string(from: NSNumber(value: absAmount)) ?? String(format: "%.2f", absAmount)
        let signStr = amount < 0 ? "-" : ""
        
        if showDecimals && formattedString.contains(".") {
            let comp = formattedString.components(separatedBy: ".")
            return (signStr, comp[0], ".\(comp[1])")
        } else {
            return (signStr, formattedString, "")
        }
    }
    
    var body: some View {
        if isHidden {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(currencySymbol)
                    .font(.system(size: mainSize * 0.82, weight: .bold, design: .rounded))
                    .fontWidth(.condensed)
                    .foregroundStyle(color)
                
                Text("••••••")
                    .font(.system(size: mainSize, weight: weight, design: .rounded))
                    .fontWidth(.condensed)
                    .tracking(tracking)
                    .foregroundStyle(color)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                // Currency Symbol (with optional minus sign)
                Text("\(parts.sign)\(currencySymbol)")
                    .font(.system(size: mainSize * 0.82, weight: .bold, design: .rounded))
                    .fontWidth(.condensed)
                    .foregroundStyle(color)
                
                // Main Integer Amount
                Text(parts.integer)
                    .font(.system(size: mainSize, weight: weight, design: .rounded))
                    .fontWidth(.condensed)
                    .tracking(tracking)
                    .monospacedDigit()
                    .foregroundStyle(color)
                
                // Baseline-aligned Decimal Value
                if showDecimals && !parts.decimal.isEmpty {
                    Text(parts.decimal)
                        .font(.system(size: max(16, mainSize * 0.55), weight: .bold, design: .rounded))
                        .fontWidth(.condensed)
                        .tracking(-0.5)
                        .monospacedDigit()
                        .foregroundStyle(secondaryColor ?? color.opacity(0.85))
                }
            }
        }
    }
}
