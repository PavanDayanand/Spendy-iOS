//
//  BudgetGaugeView.swift
//  Spendy
//
//  180° Semi-circular Arc Gauge matching Apple Standard UI
//

import SwiftUI

struct BudgetGaugeArcShape: Shape {
    var progress: Double // 0.0 to 1.0+
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height * 2) / 2 - 18
        let center = CGPoint(x: rect.midX, y: rect.maxY - 4)
        
        let startAngle = Angle(degrees: 180)
        let endAngle = Angle(degrees: 0)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

struct BudgetGaugeView: View {
    let spent: Double
    let target: Double
    let currencySymbol: String
    
    private var percentage: Double {
        guard target > 0 else { return 0 }
        return (spent / target) * 100.0
    }
    
    private var clampedProgress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, max(0.0, spent / target))
    }
    
    private var isExceeded: Bool {
        spent > target && target > 0
    }
    
    private var excessAmount: Double {
        max(0, spent - target)
    }
    
    private var remainingAmount: Double {
        max(0, target - spent)
    }
    
    private var strokeColor: Color {
        if percentage > 100 {
            return Color(hex: "#FF453A") // Red
        } else if percentage > 80 {
            return Color(hex: "#FF9500") // Orange
        } else if percentage > 50 {
            return Color(hex: "#FFD60A") // Yellow
        } else {
            return Color(hex: "#30D158") // Green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Background Arc Track
                BudgetGaugeArcShape(progress: 1.0)
                    .stroke(
                        Color(hex: "#2C2C2E"),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(height: 175)
                
                // Foreground Progress Arc Fill
                BudgetGaugeArcShape(progress: clampedProgress)
                    .trim(from: 0, to: CGFloat(clampedProgress))
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(height: 175)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: clampedProgress)
                
                // Center Labels & Numbers
                VStack(spacing: 4) {
                    if isExceeded {
                        Text("Over Budget")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.55))
                        
                        Text(excessAmount.formattedCurrency(symbol: currencySymbol, decimals: 0))
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: "#FF453A"))
                        
                        Text("+\(Int(round(percentage - 100)))% over limit")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#FF453A"))
                            .padding(.top, 2)
                    } else {
                        Text("Remaining")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.55))
                        
                        Text(remainingAmount.formattedCurrency(symbol: currencySymbol, decimals: 0))
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("\(Int(round(percentage)))% of budget used")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(strokeColor)
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
