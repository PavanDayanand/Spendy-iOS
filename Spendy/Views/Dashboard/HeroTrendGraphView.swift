//
//  HeroTrendGraphView.swift
//  Spendy
//
//  Original Apple-Native Borderless Trend Visualizer
//  Rendered directly on canvas with smooth cubic bezier curve, subtle aura fill, and endpoint dot.
//

import SwiftUI

struct HeroTrendGraphView: View {
    let transactions: [Transaction]
    let currentBalance: Double
    var tintColor: Color = SpendyColors.textPrimary
    
    // Compute recent daily balance points for the sparkline path
    private var dataPoints: [CGFloat] {
        if transactions.isEmpty {
            return [0.35, 0.42, 0.38, 0.50, 0.58, 0.52, 0.65, 0.60, 0.72, 0.78]
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
                let step = w / CGFloat(points.count - 1)
                let endX = CGFloat(points.count - 1) * step
                let endY = h * (1.0 - points[points.count - 1] * 0.75 - 0.12)
                
                ZStack {
                    // 1. Ambient Gradient Underfill
                    Path { path in
                        let startY = h * (1.0 - points[0] * 0.75 - 0.12)
                        path.move(to: CGPoint(x: 0, y: startY))
                        
                        for i in 1..<points.count {
                            let x = CGFloat(i) * step
                            let y = h * (1.0 - points[i] * 0.75 - 0.12)
                            let prevX = CGFloat(i - 1) * step
                            let prevY = h * (1.0 - points[i - 1] * 0.75 - 0.12)
                            
                            let midX = (prevX + x) / 2
                            path.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: midX, y: prevY),
                                control2: CGPoint(x: midX, y: y)
                            )
                        }
                        
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: tintColor.opacity(0.18), location: 0.0),
                                .init(color: tintColor.opacity(0.06), location: 0.50),
                                .init(color: Color.clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // 2. Smooth Stroke Curve
                    Path { path in
                        let startY = h * (1.0 - points[0] * 0.75 - 0.12)
                        path.move(to: CGPoint(x: 0, y: startY))
                        
                        for i in 1..<points.count {
                            let x = CGFloat(i) * step
                            let y = h * (1.0 - points[i] * 0.75 - 0.12)
                            let prevX = CGFloat(i - 1) * step
                            let prevY = h * (1.0 - points[i - 1] * 0.75 - 0.12)
                            
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
                                tintColor.opacity(0.30),
                                tintColor.opacity(0.95),
                                tintColor.opacity(0.70)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: tintColor.opacity(0.35), radius: 6, x: 0, y: 3)
                    
                    // 3. Glowing Endpoint Marker (Live Today Indicator)
                    Circle()
                        .fill(tintColor)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .shadow(color: tintColor.opacity(0.8), radius: 4)
                        .position(x: endX - 1, y: endY)
                }
            }
        }
        .frame(height: 60)
    }
}
