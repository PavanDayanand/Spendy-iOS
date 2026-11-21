//
//  SpendyIconBadge.swift
//  Spendy
//
//  Shared Unified Icon Badge Component for Categories, Subscriptions, and Accounts
//

import SwiftUI

// MARK: - Mono Icon Mode Environment Key
private struct MonoIconModeKey: EnvironmentKey {
    static let defaultValue: Bool = true
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

/// Shared entity badge paint. The app uses adaptive monochrome fill and glyph
/// colors, while legacy color values remain available for saved data.
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
        // Legacy item colors and mode arguments never affect presentation.
        Resolved(
            fill: SpendyColors.textPrimary,
            glyph: SpendyColors.inverseText,
            glow: .clear
        )
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
                    .font(.system(size: size.iconSize, weight: .bold, design: .default))
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
