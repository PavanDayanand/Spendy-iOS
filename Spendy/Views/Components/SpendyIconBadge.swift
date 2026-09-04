//
//  SpendyIconBadge.swift
//  Spendy
//
//  Shared Unified Icon Badge Component for Categories, Subscriptions, and Accounts
//

import SwiftUI

// MARK: - Mono Icon Mode Environment Key
private struct MonoIconModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isMonoIconMode: Bool {
        get { self[MonoIconModeKey.self] }
        set { self[MonoIconModeKey.self] = newValue }
    }
}

// MARK: - Shared Badge Item Model
struct BadgeItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
}

// MARK: - Overlapping Badge Cluster
struct OverlappingBadgeCluster: View {
    let items: [BadgeItem]
    var badgeSize: CGFloat = 32
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                singleBadge(item)
                    .offset(x: CGFloat(index) * (badgeSize * 0.58), y: 0)
                    .zIndex(Double(items.count - index))
            }
        }
        .frame(
            width: clusterWidth,
            height: badgeSize,
            alignment: .leading
        )
    }
    
    private func singleBadge(_ item: BadgeItem) -> some View {
        SpendyIconBadge(
            sfSymbol: item.icon,
            color: item.color,
            size: .small,
            style: .circle,
            showCutoutBorder: true
        )
    }
    
    private var clusterWidth: CGFloat {
        let count = min(items.count, 5)
        if count <= 1 { return badgeSize }
        return badgeSize + CGFloat(count - 1) * (badgeSize * 0.58)
    }
}

struct SpendyIconBadge: View {
    enum Style: Equatable {
        case circle
        case rounded(cornerRadius: CGFloat? = nil)
    }
    
    enum Size {
        case small    // 36x36
        case medium   // 44x44
        case large    // 56x56
        case hero     // 80x80
        
        var dimension: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            case .hero: return 80
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 26
            case .hero: return 34
            }
        }
        
        var defaultCornerRadius: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 16
            case .hero: return 22
            }
        }
        
        var strokeWidth: CGFloat {
            switch self {
            case .small: return 2.2
            case .medium: return 2.5
            case .large: return 2.8
            case .hero: return 3.2
            }
        }
    }
    
    var sfSymbol: String
    var color: Color
    var size: Size = .medium
    var style: Style = .rounded()
    var isGradient: Bool = false
    var showCutoutBorder: Bool = false
    
    @Environment(\.isMonoIconMode) private var isMonoMode
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    // Mono mode: fill is textPrimary (black in light, white in dark)
    private var effectiveFillColor: Color {
        if isMonoMode {
            return SpendyColors.textPrimary
        }
        return color
    }
    
    // Mono mode: symbol is always the inverse of the fill
    private var symbolForeground: Color {
        if isMonoMode {
            return SpendyColors.inverseText
        }
        if isGradient {
            return color
        }
        return isLightColor ? Color.black : Color.white
    }
    
    // Mono mode: no colored shadow
    private var effectiveShadowColor: Color {
        if isMonoMode {
            return Color.clear
        }
        return color.opacity(0.35)
    }
    
    // Mono mode gradient: use textPrimary instead of entity color
    private var monoGradientColor: Color {
        SpendyColors.textPrimary
    }
    
    private var resolvedCornerRadius: CGFloat {
        switch style {
        case .circle:
            return size.dimension / 2
        case .rounded(let radius):
            return radius ?? size.defaultCornerRadius
        }
    }
    
    var body: some View {
        ZStack {
            switch style {
            case .circle:
                if isGradient && !isMonoMode {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.35), color.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(Circle().stroke(color.opacity(0.35), lineWidth: 1))
                        .shadow(color: color.opacity(0.20), radius: 5, y: 2)
                } else if isGradient && isMonoMode {
                    // Mono gradient mode: subtle monochrome gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [monoGradientColor.opacity(0.35), monoGradientColor.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(Circle().stroke(monoGradientColor.opacity(0.35), lineWidth: 1))
                } else {
                    Circle()
                        .fill(effectiveFillColor)
                        .overlay {
                            if showCutoutBorder {
                                Circle()
                                    .stroke(colorScheme == .dark ? Color.black.opacity(0.85) : Color.white, lineWidth: size.strokeWidth)
                            }
                        }
                        .shadow(color: effectiveShadowColor.opacity(0.7), radius: size == .hero ? 10 : 4, y: size == .hero ? 3 : 1.5)
                }
            case .rounded:
                let cornerRadius = resolvedCornerRadius
                if isGradient && !isMonoMode {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.35), color.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: color.opacity(0.25), radius: size == .hero ? 8 : 4, x: 0, y: 0)
                        .shadow(color: color.opacity(0.20), radius: size == .hero ? 12 : 5, x: 0, y: 2)
                } else if isGradient && isMonoMode {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [monoGradientColor.opacity(0.35), monoGradientColor.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(effectiveFillColor)
                        .overlay {
                            if showCutoutBorder {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .stroke(colorScheme == .dark ? Color.black.opacity(0.85) : Color.white, lineWidth: size.strokeWidth)
                            }
                        }
                        // All-sides shading: ambient 360-degree diffusion + subtle key depth
                        .shadow(color: effectiveShadowColor.opacity(0.45), radius: size == .hero ? 8 : 3.5, x: 0, y: 0)
                        .shadow(color: effectiveShadowColor.opacity(0.30), radius: size == .hero ? 12 : 4.5, x: 0, y: 1.5)
                }
            }
            
            if sfSymbol == "Aa" || sfSymbol.count <= 2 && !sfSymbol.contains(".") {
                Text(sfSymbol)
                    .font(.system(size: size.iconSize, weight: .bold, design: .rounded))
                    .foregroundStyle(symbolForeground)
            } else {
                Image(systemName: SFIcons.symbol(named: sfSymbol))
                    .font(.system(size: size.iconSize, weight: .bold))
                    .foregroundStyle(symbolForeground)
                    .contentTransition(.symbolEffect(.replace.byLayer))
            }
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}
