//
//  SparklineView.swift
//  Spendy
//
//  Shared Catmull-Rom Bezier Sparkline / Mini-Graph Component
//  Consolidates HeroSpendTrendGraph, AccountsMiniSparkline, and
//  HeroTrendGraphView into one configurable reusable view.
//

import SwiftUI

// MARK: - Sparkline Style
enum SparklineStyle {
    /// Stroke line only (no area fill)
    case stroke
    /// Stroke with area gradient fill underneath
    case area
    /// Glowing stroke with area fill and endpoint beacon
    case glow
}

// MARK: - SparklineView
struct SparklineView: View {
    /// Normalized data points (0.0–1.0) to plot
    let points: [CGFloat]
    
    /// Line and fill color
    var color: Color = SpendyColors.primaryBlue
    
    /// Visual style variant
    var style: SparklineStyle = .area
    
    /// Height of the sparkline
    var height: CGFloat = 52
    
    /// Line width
    var lineWidth: CGFloat = 2.4
    
    /// Whether to show a glowing endpoint dot
    var showEndpoint: Bool = true
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            if points.count >= 2 {
                let coords = buildCoordinates(points: points, width: w, height: h)
                
                ZStack {
                    // Area gradient fill (for .area and .glow styles)
                    if style == .area || style == .glow {
                        areaPath(coords: coords, width: w, height: h)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        color.opacity(style == .glow ? 0.25 : 0.20),
                                        color.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    // Stroke curve
                    curvePath(coords: coords)
                        .stroke(
                            style == .glow
                                ? LinearGradient(
                                    colors: [color.opacity(0.50), color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    colors: [color, color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(
                            color: style == .glow ? color.opacity(0.4) : .clear,
                            radius: style == .glow ? 6 : 0,
                            x: 0, y: 2
                        )
                    
                    // Endpoint beacon dot
                    if showEndpoint, let last = coords.last {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle().stroke(color, lineWidth: 2.5)
                            )
                            .shadow(color: color.opacity(0.8), radius: 6, x: 0, y: 0)
                            .position(last)
                    }
                }
            }
        }
        .frame(height: height)
    }
    
    // MARK: - Coordinate Computation
    
    private func buildCoordinates(points: [CGFloat], width: CGFloat, height: CGFloat) -> [CGPoint] {
        let count = points.count
        let maxVal = max(0.001, points.max() ?? 1.0)
        
        return points.enumerated().map { index, value in
            let x = count > 1 ? (CGFloat(index) / CGFloat(count - 1)) * width : width / 2
            let normalized = value / maxVal
            let y = height - (normalized * (height - 14) + 7)
            return CGPoint(x: x, y: y)
        }
    }
    
    // MARK: - Catmull-Rom Bezier Curve Path
    
    private func curvePath(coords: [CGPoint]) -> Path {
        Path { path in
            guard coords.count > 1 else { return }
            path.move(to: coords[0])
            for i in 1..<coords.count {
                let prev = coords[i - 1]
                let cur = coords[i]
                let midX = (prev.x + cur.x) / 2
                path.addCurve(
                    to: cur,
                    control1: CGPoint(x: midX, y: prev.y),
                    control2: CGPoint(x: midX, y: cur.y)
                )
            }
        }
    }
    
    // MARK: - Closed Area Path
    
    private func areaPath(coords: [CGPoint], width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            guard coords.count > 1 else { return }
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(to: coords[0])
            
            for i in 1..<coords.count {
                let prev = coords[i - 1]
                let cur = coords[i]
                let midX = (prev.x + cur.x) / 2
                path.addCurve(
                    to: cur,
                    control1: CGPoint(x: midX, y: prev.y),
                    control2: CGPoint(x: midX, y: cur.y)
                )
            }
            
            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
        }
    }
}

// MARK: - Convenience: Trend Direction Sparkline
/// A simplified sparkline that shows a fixed upward or downward trend curve
/// (used for account cards where you just need a directional indicator).
struct TrendSparkline: View {
    var isPositive: Bool = true
    var color: Color? = nil
    var height: CGFloat = 36
    
    private var effectiveColor: Color {
        if let color = color { return color }
        return isPositive ? Color(hex: "#30D158") : Color(hex: "#FF3B30")
    }
    
    private var mockPoints: [CGFloat] {
        if isPositive {
            return [0.2, 0.22, 0.25, 0.24, 0.28, 0.35, 0.5, 0.72, 0.95]
        } else {
            return [0.9, 0.88, 0.85, 0.82, 0.75, 0.6, 0.45, 0.3, 0.15]
        }
    }
    
    var body: some View {
        SparklineView(
            points: mockPoints,
            color: effectiveColor,
            style: .area,
            height: height,
            lineWidth: 1.5,
            showEndpoint: false
        )
    }
}

// MARK: - Interactive Touch-Scrubbing Sparkline (Pure White Monochrome)
struct InteractiveSparklineView: View {
    let dataPoints: [SpendTrendPoint]
    var currencySymbol: String = "$"
    var height: CGFloat = 80
    
    @State private var dragX: CGFloat? = nil
    @State private var selectedIndex: Int? = nil
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let amounts = dataPoints.map { $0.amount }
            let maxAmount = max(1.0, amounts.max() ?? 1.0)
            let count = max(1, dataPoints.count)
            
            let coords: [CGPoint] = dataPoints.enumerated().map { index, point in
                let x = count > 1 ? (CGFloat(index) / CGFloat(count - 1)) * w : w / 2
                let normalized = CGFloat(point.amount / maxAmount)
                let y = h - (normalized * (h - 18) + 9)
                return CGPoint(x: x, y: y)
            }
            
            ZStack(alignment: .topLeading) {
                // 1. Soft Pure White Gradient Area Fill
                Path { path in
                    guard coords.count > 1 else { return }
                    path.move(to: CGPoint(x: 0, y: h))
                    path.addLine(to: coords[0])
                    for i in 1..<coords.count {
                        let prev = coords[i - 1]
                        let cur = coords[i]
                        let midX = (prev.x + cur.x) / 2
                        path.addCurve(to: cur, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: cur.y))
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // 2. Crisp White Curve Stroke
                Path { path in
                    guard coords.count > 1 else { return }
                    path.move(to: coords[0])
                    for i in 1..<coords.count {
                        let prev = coords[i - 1]
                        let cur = coords[i]
                        let midX = (prev.x + cur.x) / 2
                        path.addCurve(to: cur, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: cur.y))
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.50), Color.white],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: Color.white.opacity(0.35), radius: 4, x: 0, y: 1)
                
                // 3. Active Scrubbing Indicator & Specular Floating Tooltip
                if let idx = selectedIndex, idx < coords.count, idx < dataPoints.count {
                    let point = coords[idx]
                    let item = dataPoints[idx]
                    
                    // Vertical Guideline
                    Path { p in
                        p.move(to: CGPoint(x: point.x, y: 0))
                        p.addLine(to: CGPoint(x: point.x, y: h))
                    }
                    .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    
                    // Glowing White Scrubbing Circle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .shadow(color: Color.white, radius: 6)
                        .position(point)
                    
                    // Floating Glass Tooltip Readout
                    HStack(spacing: 4) {
                        Text(item.label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.6))
                        Text("•")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.4))
                        Text(item.amount.formattedCurrency(symbol: currencySymbol, decimals: 0))
                            .spendyNumberFont(size: 11, weight: .heavy, tracking: -0.3)
                            .foregroundStyle(Color.black)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white).shadow(color: Color.black.opacity(0.3), radius: 6, y: 2))
                    .position(x: min(max(70, point.x), w - 70), y: max(16, point.y - 24))
                } else if let last = coords.last {
                    // Default End Point Specular Beacon
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
                        .shadow(color: Color.white.opacity(0.8), radius: 4)
                        .position(last)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let locationX = val.location.x
                        dragX = locationX
                        let newIdx = max(0, min(count - 1, Int(round((locationX / w) * CGFloat(count - 1)))))
                        if selectedIndex != newIdx {
                            selectedIndex = newIdx
                            HapticsManager.shared.trigger(.selection)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedIndex = nil
                            dragX = nil
                        }
                    }
            )
        }
        .frame(height: height)
    }
}

