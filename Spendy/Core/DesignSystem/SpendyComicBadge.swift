//
//  SpendyComicBadge.swift
//  Spendy
//
//  Playful die-cut cartoon vinyl sticker badge with dynamic numeric animations,
//  bold comic ink outlines, crisp white cutout border (no shadow), and vibrant multi-stop gradients.
//

import SwiftUI

// MARK: - Comic Badge Palette
public enum SpendyComicPalette: Sendable, Equatable {
    case fire          // Punchy Red/Crimson (Alerts, Hot, 0)
    case cyberGold     // Radiant Gold/Amber (Active, Milestones)
    case custom(gradient: [Color], stroke: Color)
    
    public var gradientColors: [Color] {
        switch self {
        case .fire:
            return [
                Color(hex: "#FF3B30"),
                Color(hex: "#FF2A6D"),
                Color(hex: "#D00036")
            ]
        case .cyberGold:
            return [
                Color(hex: "#FFE600"),
                Color(hex: "#FF9500"),
                Color(hex: "#EA580C")
            ]
        case .custom(let colors, _):
            return colors
        }
    }
    
    public var inkStrokeColor: Color {
        switch self {
        case .custom(_, let stroke):
            return stroke
        default:
            return Color(hex: "#06060A")
        }
    }
}

// MARK: - Spendy Comic Badge Component
public struct SpendyComicBadge: View {
    public enum Size {
        case small   // 26pt font
        case medium  // 38pt font
        case large   // 52pt font
        case custom(fontSize: CGFloat, borderWidth: CGFloat)
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 26
            case .medium: return 38
            case .large: return 52
            case .custom(let fs, _): return fs
            }
        }
        
        var whiteBorderWidth: CGFloat {
            switch self {
            case .small: return 4.0
            case .medium: return 5.8
            case .large: return 7.5
            case .custom(_, let bw): return bw
            }
        }
        
        var inkBorderWidth: CGFloat {
            switch self {
            case .small: return 1.8
            case .medium: return 2.6
            case .large: return 3.4
            case .custom(_, let bw): return bw * 0.45
            }
        }
    }
    
    let text: String
    var palette: SpendyComicPalette = .fire
    var size: Size = .medium
    var rotationAngle: Double = -7
    var isInteractive: Bool = true
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed: Bool = false
    @State private var bounceTrigger: Int = 0
    
    public init(
        _ text: String,
        palette: SpendyComicPalette = .fire,
        size: Size = .medium,
        rotationAngle: Double = -7,
        isInteractive: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.text = text
        self.palette = palette
        self.size = size
        self.rotationAngle = rotationAngle
        self.isInteractive = isInteractive
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: {
            if isInteractive {
                HapticsManager.shared.trigger(.selection)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
                    bounceTrigger += 1
                }
                onTap?()
            }
        }) {
            ZStack {
                // 1. Layer 1: Smooth 32-Point Die-Cut White Cutout (Pure clean white cutout - NO shadow)
                whiteCutoutContour
                
                // 2. Layer 2: Smooth 16-Point Deep Black Comic Ink Stroke
                blackInkContour
                
                // 3. Layer 3: Vibrant Cartoon Gradient Fill on top
                renderedGradientText
            }
            .padding(size.whiteBorderWidth + 2)
            .scaleEffect(isPressed ? 0.90 : 1.0)
            .scaleEffect(1.0 + (bounceTrigger % 2 == 1 ? 0.08 : 0.0))
            .rotationEffect(.degrees(rotationAngle))
            .animation(.spring(response: 0.32, dampingFraction: 0.52), value: text)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(ComicBadgeButtonStyle(isPressed: $isPressed, isInteractive: isInteractive))
        .accessibilityLabel("Badge: \(text)")
    }
    
    // MARK: - Smooth 32-Point Radial White Cutout (No Shadow)
    private var whiteCutoutContour: some View {
        let r = size.whiteBorderWidth
        return ZStack {
            ForEach(0..<32, id: \.self) { i in
                let angle = Double(i) * (.pi / 16.0)
                let x = CGFloat(cos(angle)) * r
                let y = CGFloat(sin(angle)) * r
                renderedBaseText(color: .white)
                    .offset(x: x, y: y)
            }
            renderedBaseText(color: .white)
        }
    }
    
    // MARK: - Smooth 16-Point Radial Black Ink Contour
    private var blackInkContour: some View {
        let r = size.inkBorderWidth
        return ZStack {
            ForEach(0..<16, id: \.self) { i in
                let angle = Double(i) * (.pi / 8.0)
                let x = CGFloat(cos(angle)) * r
                let y = CGFloat(sin(angle)) * r
                renderedBaseText(color: palette.inkStrokeColor)
                    .offset(x: x, y: y + 0.6)
            }
            renderedBaseText(color: palette.inkStrokeColor)
                .offset(y: 0.6)
        }
    }
    
    // MARK: - Core Typography Renderers
    private func renderedBaseText(color: Color) -> some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: .black, design: .rounded))
            .italic()
            .foregroundStyle(color)
            .contentTransition(.numericText())
    }
    
    private var renderedGradientText: some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: .black, design: .rounded))
            .italic()
            .foregroundStyle(
                LinearGradient(
                    colors: palette.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .contentTransition(.numericText())
    }
}

// MARK: - Interactive Button Style for Comic Badge
private struct ComicBadgeButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let isInteractive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                if isInteractive {
                    isPressed = newValue
                }
            }
    }
}
