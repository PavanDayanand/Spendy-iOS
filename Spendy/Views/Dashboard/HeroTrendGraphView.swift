//
//  HeroTrendGraphView.swift
//  Spendy
//
//  Borderless line graph drawn directly on the screen background
//

import SwiftUI

struct HeroTrendGraphView: View {
    let transactions: [Transaction]
    let currentBalance: Double
    
    // Compute recent daily balance points for the sparkline path
    private var dataPoints: [CGFloat] {
        if transactions.isEmpty {
            return [0.4, 0.45, 0.4, 0.5, 0.55, 0.5, 0.6, 0.58, 0.65, 0.7]
        }
        
        let sorted = transactions.sorted(by: { $0.date < $1.date })
        var running = currentBalance
        var points: [Double] = [running]
        
        for tx in sorted.reversed().prefix(15) {
            if tx.type == .expense {
                running += tx.amount
            } else if tx.type == .income {
                running -= tx.amount
            }
            points.append(running)
        }
        
        points.reverse()
        let minVal = points.min() ?? 0
        let maxVal = points.max() ?? 1
        let range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal)
        
        return points.map { CGFloat(($0 - minVal) / range) }
    }
    
    var body: some View {
        GeometryReader { proxy in
            let points = dataPoints
            let w = proxy.size.width
            let h = proxy.size.height
            
            if points.count >= 2 {
                Path { path in
                    let step = w / CGFloat(points.count - 1)
                    let startY = h * (1.0 - points[0] * 0.75 - 0.1)
                    path.move(to: CGPoint(x: 0, y: startY))
                    
                    for i in 1..<points.count {
                        let x = CGFloat(i) * step
                        let y = h * (1.0 - points[i] * 0.75 - 0.1)
                        let prevX = CGFloat(i - 1) * step
                        let prevY = h * (1.0 - points[i - 1] * 0.75 - 0.1)
                        
                        // Stepped-curve interpolation matching screenshot line chart style
                        let midX = (prevX + x) / 2
                        path.addCurve(
                            to: CGPoint(x: x, y: y),
                            control1: CGPoint(x: midX, y: prevY),
                            control2: CGPoint(x: midX, y: y)
                        )
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            SpendyColors.textPrimary.opacity(0.40),
                            SpendyColors.textPrimary.opacity(0.95),
                            SpendyColors.textPrimary.opacity(0.60)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: SpendyColors.textPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .frame(height: 55)
    }
}
