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
    let id: String
    let icon: String
    let color: Color
    var name: String = ""
    
    init(id: String? = nil, icon: String, color: Color, name: String = "") {
        self.id = id ?? "\(icon)-\(name)"
        self.icon = icon
        self.color = color
        self.name = name
    }
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
            showCutoutBorder: true,
            monogramName: item.name
        )
    }
    
    private var clusterWidth: CGFloat {
        let count = min(items.count, 5)
        if count <= 1 { return badgeSize }
        return badgeSize + CGFloat(count - 1) * (badgeSize * 0.58)
    }
}

/// How Spendy paints entity icons: chrome stays mono, color is identity.
/// Every named thing (category, account, subscription) is a solid badge
/// with a contrast glyph — the same language at 14pt and 80pt.
enum SpendyIconPaint {
    struct Resolved {
        let fill: Color
        let glyph: Color
        let glow: Color
    }
    
    static func resolve(
        _ color: Color,
        scheme: ColorScheme,
        mono: Bool,
        prominent: Bool
    ) -> Resolved {
        if mono || SpendyColors.isMonoMode {
            return Resolved(
                fill: SpendyColors.textPrimary,
                glyph: SpendyColors.inverseText,
                glow: .clear
            )
        }
        
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Near-white / washed greys can't carry a glyph. Fall back to paper.
        let nearWhite = brightness > 0.90 && saturation < 0.14
        if nearWhite {
            return Resolved(
                fill: SpendyColors.cardBackgroundSecondary,
                glyph: SpendyColors.textPrimary,
                glow: .clear
            )
        }
        
        // Keep the hue the user picked. Lift crushed darks, pull neon down
        // just enough that yellows stay yellow and blues stay blue.
        let fillSaturation = min(1.0, max(0.42, saturation * (scheme == .dark ? 1.06 : 1.0)))
        let fillBrightness: CGFloat = scheme == .light
            ? min(0.90, max(0.38, brightness))
            : min(0.82, max(0.46, brightness))
        let fill = Color(
            hue: Double(hue),
            saturation: Double(fillSaturation),
            brightness: Double(fillBrightness)
        )
        
        let glyph: Color = relativeLuminance(
            hue: hue,
            saturation: fillSaturation,
            brightness: fillBrightness
        ) > 0.55 ? Color.black.opacity(0.88) : Color.white
        
        let glow: Color = prominent
            ? fill.opacity(scheme == .light ? 0.22 : 0.34)
            : .clear
        
        return Resolved(fill: fill, glyph: glyph, glow: glow)
    }
    
    private static func relativeLuminance(
        hue: CGFloat,
        saturation: CGFloat,
        brightness: CGFloat
    ) -> CGFloat {
        let ui = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        func linear(_ channel: CGFloat) -> CGFloat {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }
}

enum SpendyMonogram {
    static let token = "Aa"
    
    static func isMonogram(_ symbol: String) -> Bool {
        symbol == token
    }
    
    static func letter(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "A" }
        return String(first).uppercased()
    }
    
    static func displayLetter(symbol: String, name: String) -> String? {
        if isMonogram(symbol) {
            return letter(from: name)
        }
        if symbol.count <= 2 && !symbol.contains(".") {
            return symbol.uppercased()
        }
        return nil
    }
}

struct SpendyGlyph: View {
    let symbol: String
    var name: String = ""
    var font: Font = .body
    
    var body: some View {
        if let letter = SpendyMonogram.displayLetter(symbol: symbol, name: name) {
            Text(letter)
                .font(font)
        } else {
            Image(systemName: SFIcons.symbol(named: symbol))
                .font(font)
        }
    }
}

/// 14pt account/category chip used under row titles. Same paint as the badges.
struct SpendyMiniColorChip: View {
    var sfSymbol: String
    var color: Color
    var size: CGFloat = 14
    var isCircle: Bool = false
    var monogramName: String = ""
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isMonoIconMode) private var isMonoMode
    
    private var isEffectivelyMono: Bool {
        isMonoMode || SpendyColors.isMonoMode
    }
    
    var body: some View {
        let paint = SpendyIconPaint.resolve(
            color,
            scheme: colorScheme,
            mono: isEffectivelyMono,
            prominent: false
        )
        
        let radius = isCircle ? size / 2 : size * 0.25
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(paint.fill)
            SpendyGlyph(
                symbol: sfSymbol,
                name: monogramName,
                font: .system(size: size * 0.57, weight: .bold)
            )
            .foregroundStyle(paint.glyph)
        }
        .frame(width: size, height: size)
        .shadow(color: paint.fill.opacity(isEffectivelyMono ? 0 : 0.32), radius: 1, y: 0)
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
    var style: Style = .circle
    var isGradient: Bool = false
    var showCutoutBorder: Bool = false
    var monogramName: String = ""
    
    @Environment(\.isMonoIconMode) private var isMonoMode
    @Environment(\.colorScheme) private var colorScheme
    
    private var isEffectivelyMono: Bool {
        isMonoMode || SpendyColors.isMonoMode
    }
    
    private var paint: SpendyIconPaint.Resolved {
        SpendyIconPaint.resolve(
            color,
            scheme: colorScheme,
            mono: isEffectivelyMono,
            prominent: size == .hero || size == .large
        )
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
        let shape = RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
        
        ZStack {
            shape
                .fill(paint.fill)
                .overlay {
                    if showCutoutBorder {
                        shape.stroke(
                            colorScheme == .dark ? Color.black.opacity(0.85) : Color.white,
                            lineWidth: size.strokeWidth
                        )
                    }
                }
                .shadow(
                    color: paint.glow,
                    radius: size == .hero ? 10 : (size == .large ? 6 : 0),
                    y: size == .hero ? 3 : 2
                )
            
            if let letter = SpendyMonogram.displayLetter(symbol: sfSymbol, name: monogramName) {
                Text(letter)
                    .font(.system(size: size.iconSize, weight: .bold, design: .rounded))
                    .foregroundStyle(paint.glyph)
                    .contentTransition(.opacity)
            } else {
                Image(systemName: SFIcons.symbol(named: sfSymbol))
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundStyle(paint.glyph)
                    .symbolRenderingMode(.monochrome)
                    .contentTransition(.symbolEffect(.replace.byLayer))
            }
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}
