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

struct SpendyIconBadge: View {
    enum Style {
        case circle
        case rounded(cornerRadius: CGFloat)
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
            case .small: return 12
            case .medium: return 14
            case .large: return 18
            case .hero: return 24
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
    var style: Style = .circle
    var isGradient: Bool = false
    var showCutoutBorder: Bool = true
    
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
                        .shadow(color: color.opacity(0.25), radius: 6, y: 2)
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
                                    .stroke(Color.black.opacity(0.65), lineWidth: size.strokeWidth)
                            }
                        }
                        .shadow(color: effectiveShadowColor, radius: size == .hero ? 12 : 5, y: size == .hero ? 4 : 2)
                }
            case .rounded(let radius):
                if isGradient && !isMonoMode {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.35), color.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(color.opacity(0.35), lineWidth: 1))
                        .shadow(color: color.opacity(0.25), radius: 6, y: 2)
                } else if isGradient && isMonoMode {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [monoGradientColor.opacity(0.35), monoGradientColor.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(monoGradientColor.opacity(0.35), lineWidth: 1))
                } else {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(effectiveFillColor)
                        .overlay {
                            if showCutoutBorder {
                                RoundedRectangle(cornerRadius: radius, style: .continuous)
                                    .stroke(Color.black.opacity(0.65), lineWidth: size.strokeWidth)
                            }
                        }
                        .shadow(color: effectiveShadowColor, radius: size == .hero ? 12 : 5, y: size == .hero ? 4 : 2)
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
