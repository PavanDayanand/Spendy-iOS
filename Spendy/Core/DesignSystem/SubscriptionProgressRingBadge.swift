//
//  SubscriptionProgressRingBadge.swift
//  Spendy
//
//  Circular Subscription Icon Badge with an Outer Billing Cycle Timing Progress Ring.
//  The ring uses the EXACT SAME COLOR as the subscription's icon, smoothly filling
//  clockwise as the renewal date approaches.
//

import SwiftUI

struct SubscriptionProgressRingBadge: View {
    enum Size {
        case small    // 38x38 outer, 26x26 inner, 2.4pt stroke
        case medium   // 48x48 outer, 34x34 inner, 3.0pt stroke
        case large    // 68x68 outer, 48x48 inner, 3.8pt stroke
        case hero     // 96x96 outer, 68x68 inner, 4.8pt stroke
        
        var outerDimension: CGFloat {
            switch self {
            case .small:  return 38
            case .medium: return 48
            case .large:  return 68
            case .hero:   return 96
            }
        }
        
        var innerDimension: CGFloat {
            switch self {
            case .small:  return 26
            case .medium: return 34
            case .large:  return 48
            case .hero:   return 68
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small:  return 13
            case .medium: return 17
            case .large:  return 24
            case .hero:   return 34
            }
        }
        
        var strokeWidth: CGFloat {
            switch self {
            case .small:  return 2.4
            case .medium: return 3.0
            case .large:  return 3.8
            case .hero:   return 4.8
            }
        }
    }
    
    var sfSymbol: String
    var color: Color
    var progress: Double // 0.0 to 1.0
    var isPaused: Bool
    var isDueSoon: Bool
    var isOverdue: Bool
    var size: Size
    var showRing: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var animatedProgress: Double = 0.0
    
    init(
        sfSymbol: String,
        color: Color,
        progress: Double = 0.0,
        isPaused: Bool = false,
        isDueSoon: Bool = false,
        isOverdue: Bool = false,
        size: Size = .medium,
        showRing: Bool = true
    ) {
        self.sfSymbol = sfSymbol
        self.color = color
        self.progress = progress
        self.isPaused = isPaused
        self.isDueSoon = isDueSoon
        self.isOverdue = isOverdue
        self.size = size
        self.showRing = showRing
    }
    
    init(
        subscription: Subscription,
        size: Size = .medium,
        showRing: Bool = true
    ) {
        self.sfSymbol = subscription.sfSymbol
        self.color = subscription.color
        self.progress = subscription.cycleProgress
        self.isPaused = subscription.isPaused
        self.isDueSoon = subscription.isDueSoon
        self.isOverdue = subscription.isOverdue
        self.size = size
        self.showRing = showRing
    }
    
    private var isLightColor: Bool {
        let uiColor = UIColor(color)
        var white: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getWhite(&white, alpha: &alpha) {
            return white > 0.85
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &alpha) {
            let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
            return luminance > 0.82
        }
        return false
    }
    
    private var symbolForeground: Color {
        isLightColor ? Color.black : Color.white
    }
    
    var body: some View {
        ZStack {
            // MARK: - Outer Circular Timing Ring
            if showRing {
                // Background Track (subtle matching color)
                Circle()
                    .stroke(
                        color.opacity(isPaused ? 0.08 : (colorScheme == .dark ? 0.20 : 0.24)),
                        lineWidth: size.strokeWidth
                    )
                    .frame(
                        width: size.outerDimension - size.strokeWidth,
                        height: size.outerDimension - size.strokeWidth
                    )
                
                // Active Progress Arc (exact same color as the icon)
                if !isPaused && animatedProgress > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(animatedProgress, 0.0), 1.0)))
                        .stroke(
                            color,
                            style: StrokeStyle(
                                lineWidth: size.strokeWidth,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(
                            width: size.outerDimension - size.strokeWidth,
                            height: size.outerDimension - size.strokeWidth
                        )
                        .shadow(
                            color: color.opacity(isDueSoon || isOverdue ? 0.40 : 0.20),
                            radius: isDueSoon || isOverdue ? 3 : 1.5,
                            x: 0,
                            y: 0
                        )
                }
            }
            
            // MARK: - Inner Icon Badge
            Circle()
                .fill(color.opacity(isPaused ? 0.45 : 1.0))
                .frame(width: size.innerDimension, height: size.innerDimension)
                .shadow(
                    color: isPaused ? Color.clear : color.opacity(0.30),
                    radius: size == .hero ? 8 : 2.5,
                    y: size == .hero ? 3 : 1
                )
            
            // Centered Symbol or Monogram
            if sfSymbol == "Aa" || sfSymbol.count <= 2 && !sfSymbol.contains(".") {
                Text(sfSymbol)
                    .font(.system(size: size.iconSize, weight: .bold, design: .rounded))
                    .foregroundStyle(symbolForeground)
                    .opacity(isPaused ? 0.65 : 1.0)
            } else {
                Image(systemName: SFIcons.symbol(named: sfSymbol))
                    .font(.system(size: size.iconSize, weight: .bold))
                    .foregroundStyle(symbolForeground)
                    .contentTransition(.symbolEffect(.replace.byLayer))
                    .opacity(isPaused ? 0.65 : 1.0)
            }
        }
        .frame(width: size.outerDimension, height: size.outerDimension)
        .onAppear {
            if reduceMotion {
                animatedProgress = progress
            } else {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if reduceMotion {
                animatedProgress = newValue
            } else {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}
