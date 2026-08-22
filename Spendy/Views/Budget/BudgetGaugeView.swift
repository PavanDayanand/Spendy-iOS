//
//  BudgetGaugeView.swift
//  Spendy
//
//  Analytics-Style Circular Ring Budget Card with Vibrant Status Colors & Precise Text Hierarchy
//

import SwiftUI

struct BudgetGaugeView: View {
    let spent: Double
    let target: Double
    let currencySymbol: String
    var daysLeft: Int = 0
    var periodTitle: String = "Monthly"
    var dateRangeString: String = ""
    var pacingInsightMessage: String? = nil
    
    private var percentage: Double {
        guard target > 0 else { return 0 }
        return (spent / target) * 100.0
    }
    
    private var isExceeded: Bool {
        spent > target && target > 0
    }
    
    private var excessAmount: Double {
        max(0, spent - target)
    }
    
    private var ringProgress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, spent / target)
    }
    
    private var ringColor: Color {
        if isExceeded {
            return Color(hex: "#FF453A") // Red
        } else if percentage > 80 {
            return Color(hex: "#FF9500") // Orange
        } else if percentage > 50 {
            return Color(hex: "#FFD60A") // Yellow
        } else {
            return Color(hex: "#30D158") // Green
        }
    }
    
    private var ringGradient: LinearGradient {
        if isExceeded {
            return LinearGradient(
                colors: [Color(hex: "#FF453A"), Color(hex: "#FF2D55")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if percentage > 80 {
            return LinearGradient(
                colors: [Color(hex: "#FF9500"), Color(hex: "#FFB340")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if percentage > 50 {
            return LinearGradient(
                colors: [Color(hex: "#FFD60A"), Color(hex: "#FFE14D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "#30D158"), Color(hex: "#34C759")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main Ring & Stats Row
            HStack(spacing: 20) {
                // Colored Circular Progress Gauge Ring
                ZStack {
                    // Background Track Ring
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 9)
                        .frame(width: 88, height: 88)
                    
                    // Foreground Colored Progress Ring Fill
                    Circle()
                        .trim(from: 0.0, to: CGFloat(ringProgress))
                        .stroke(
                            ringGradient,
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 88, height: 88)
                        .shadow(color: ringColor.opacity(0.35), radius: 8, x: 0, y: 3)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: ringProgress)
                    
                    // Center Percentage Text
                    Text(String(format: "%.0f%%", percentage))
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(isExceeded ? Color(hex: "#FF453A") : SpendyColors.textPrimary)
                }
                
                // Right Stats Stack
                VStack(alignment: .leading, spacing: 3) {
                    Text(isExceeded ? String(format: "Budget exceeded by %.0f%%", percentage - 100) : String(format: "%.0f%% of budget spent", percentage))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isExceeded ? Color(hex: "#FF453A") : SpendyColors.textSecondary)
                    
                    Text(spent.formattedCurrency(symbol: currencySymbol, decimals: 0))
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(isExceeded ? Color(hex: "#FF453A") : SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("of \(target.formattedCurrency(symbol: currencySymbol, decimals: 0)) limit")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
            }
            .padding(.vertical, 2)
            
            // Smart Pacing Note Line
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isExceeded ? SpendyColors.expenseRed : Color(hex: "#30D158"))
                
                if let msg = pacingInsightMessage {
                    Text(msg)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                } else {
                    Text(isExceeded ? String(format: "At this pace, the budget will be exceeded by ↑ %@", excessAmount.formattedCurrency(symbol: currencySymbol, decimals: 0)) : "You are pacing within safe daily limits.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Divider().overlay(SpendyColors.separator)
            
            // Footer Sub-metrics Row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(periodTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(dateRangeString)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Days left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text("\(daysLeft) days left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                )
        }
    }
}
