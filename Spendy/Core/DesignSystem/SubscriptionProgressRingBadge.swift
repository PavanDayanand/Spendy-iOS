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
        case small
        case medium
        case large
        case hero
        
        var outerDimension: CGFloat {
            switch self {
            case .small:  return 38
            case .medium: return 48
            case .large:  return 68
            case .hero:   return 96
            }
        }
        
        var strokeWidth: CGFloat {
            switch self {
            case .small:  return 1.6
            case .medium: return 2.0
            case .large:  return 2.4
            case .hero:   return 3.0
            }
        }
        
        /// Tight inset so the icon fill sits just inside the ring, like Fitness.
        var innerDimension: CGFloat {
            outerDimension - (strokeWidth * 2) - 3
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small:  return 16
            case .medium: return 21
            case .large:  return 30
            case .hero:   return 42
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
    var monogramName: String = ""
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isMonoIconMode) private var isMonoMode
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
        showRing: Bool = true,
        monogramName: String = ""
    ) {
        self.sfSymbol = sfSymbol
        self.color = color
        self.progress = progress
        self.isPaused = isPaused
        self.isDueSoon = isDueSoon
        self.isOverdue = isOverdue
        self.size = size
        self.showRing = showRing
        self.monogramName = monogramName
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
        self.monogramName = subscription.name
    }
    
    private var paint: SpendyIconPaint.Resolved {
        SpendyIconPaint.resolve(
            color,
            scheme: colorScheme,
            mono: isMonoMode,
            prominent: size == .hero || size == .large
        )
    }
    
    private var ringColor: Color { paint.fill }
    
    var body: some View {
        ZStack {
            // MARK: - Outer Circular Timing Ring
            if showRing {
                // Background Track (subtle matching color)
                Circle()
                    .stroke(
                        ringColor.opacity(isPaused ? 0.10 : (colorScheme == .dark ? 0.22 : 0.28)),
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
                            ringColor,
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
                            color: ringColor.opacity(isDueSoon || isOverdue ? 0.28 : 0.0),
                            radius: isDueSoon || isOverdue ? 2 : 0,
                            x: 0,
                            y: 0
                        )
                }
            }
            
            // MARK: - Inner Icon Badge
            Circle()
                .fill(paint.fill.opacity(isPaused ? 0.55 : 1.0))
                .frame(width: size.innerDimension, height: size.innerDimension)
            
            if let letter = SpendyMonogram.displayLetter(symbol: sfSymbol, name: monogramName) {
                Text(letter)
                    .font(.system(size: size.iconSize, weight: .bold, design: .rounded))
                    .foregroundStyle(paint.glyph)
                    .opacity(isPaused ? 0.65 : 1.0)
            } else {
                Image(systemName: SFIcons.symbol(named: sfSymbol))
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundStyle(paint.glyph)
                    .symbolRenderingMode(.monochrome)
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
