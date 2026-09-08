//
//  LiquidGlass.swift
//  Spendy
//
//  Native Apple Liquid Glass Design System Modifiers
//

import SwiftUI

// MARK: - Native Liquid Glass Modifier
struct NativeLiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var isInteractive: Bool = false
    var tintColor: Color? = nil
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if isInteractive {
                if let tint = tintColor {
                    content
                        .glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
                } else {
                    content
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
                }
            } else {
                if let tint = tintColor {
                    content
                        .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
                } else {
                    content
                        .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                }
            }
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .background(SpendyColors.glassFallbackFill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        .overlay {
                            if let tint = tintColor {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(tint.opacity(0.10))
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
        }
    }
}

// MARK: - Native Liquid Glass Pill Modifier
struct NativeLiquidGlassPillModifier: ViewModifier {
    var isSelected: Bool = false
    var tintColor: Color? = nil
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if isSelected {
                content
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassEffect(.regular.tint(tintColor ?? SpendyColors.primaryBlue).interactive(), in: .capsule)
            } else {
                content
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassEffect(.clear.interactive(), in: .capsule)
            }
        } else {
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule(style: .continuous)
                        .fill(isSelected ? (tintColor ?? SpendyColors.elevatedControlFill) : SpendyColors.glassFallbackFill)
                        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    SpendyColors.separator,
                                    lineWidth: 0.8
                                )
                        }
                }
        }
    }
}

// MARK: - Native Liquid Glass Capsule Modifier
struct NativeLiquidGlassCapsuleModifier: ViewModifier {
    var isInteractive: Bool = false
    var tintColor: Color? = nil
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if isInteractive {
                if let tint = tintColor {
                    content
                        .glassEffect(.regular.tint(tint).interactive(), in: .capsule)
                } else {
                    content
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
            } else {
                if let tint = tintColor {
                    content
                        .glassEffect(.regular.tint(tint), in: .capsule)
                } else {
                    content
                        .glassEffect(.regular, in: .capsule)
                }
            }
        } else {
            content
                .background {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .background(SpendyColors.glassFallbackFill, in: Capsule(style: .continuous))
                        .overlay {
                            if let tint = tintColor {
                                Capsule(style: .continuous)
                                    .fill(tint.opacity(0.10))
                            }
                        }
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    SpendyColors.separator,
                                    lineWidth: 0.8
                                )
                        }
                }
        }
    }
}

// MARK: - Native Liquid Glass Circle Modifier
struct NativeLiquidGlassCircleModifier: ViewModifier {
    var isInteractive: Bool = true
    var tintColor: Color? = nil
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if let tint = tintColor {
                content
                    .glassEffect(.regular.tint(tint).interactive(), in: .circle)
            } else {
                content
                    .glassEffect(.regular.interactive(), in: .circle)
            }
        } else {
            content
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(SpendyColors.glassFallbackFill, in: Circle())
                        .overlay {
                            if let tint = tintColor {
                                Circle()
                                    .fill(tint.opacity(0.10))
                            }
                        }
                        .overlay {
                            Circle()
                                .stroke(
                                    SpendyColors.separator,
                                    lineWidth: 0.8
                                )
                        }
                }
        }
    }
}


// MARK: - Native Liquid Glass Morphing Modifiers

struct GlassEffectIDModifier<ID: Hashable & Sendable>: ViewModifier {
    var id: ID
    var namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffectID(id, in: namespace)
                .glassEffectTransition(.matchedGeometry)
        } else {
            content
                .matchedGeometryEffect(id: id, in: namespace)
        }
    }
}

struct GlassEffectTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffectTransition(.matchedGeometry)
        } else {
            content
        }
    }
}

struct GlassEffectUnionModifier<ID: Hashable & Sendable>: ViewModifier {
    var id: ID?
    var namespace: Namespace.ID?
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if let id = id, let namespace = namespace {
                content
                    .glassEffectUnion(id: id, namespace: namespace)
            } else {
                content
            }
        } else {
            content
        }
    }
}

// MARK: - Native Apple Liquid Glass Toggle Style
struct GlassToggleStyle: ToggleStyle {
    var tintColor: Color = SpendyColors.primaryBlue
    
    init(tintColor: Color = SpendyColors.primaryBlue) {
        self.tintColor = tintColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                    configuration.isOn.toggle()
                }
                HapticsManager.shared.trigger(.selection)
            }) {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    // Liquid Glass Track with Specular Reflection
                    Capsule(style: .continuous)
                        .fill(configuration.isOn ? tintColor : SpendyColors.cardBackgroundSecondary)
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    configuration.isOn
                                        ? LinearGradient(colors: [Color.white.opacity(0.35), tintColor.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [Color.white.opacity(0.12), SpendyColors.separator], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 0.8
                                )
                        }
                        .frame(width: 48, height: 28)
                        .shadow(color: configuration.isOn ? tintColor.opacity(0.30) : Color.black.opacity(0.12), radius: 5, y: 1.5)
                    
                    // Glossy Smooth Thumb Disc
                    Circle()
                        .fill(Color.white)
                        .overlay {
                            Circle()
                                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                        }
                        .frame(width: 24, height: 24)
                        .padding(.horizontal, 2)
                        .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 1.5)
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(configuration.isOn ? "On" : "Off")
        }
    }
}

extension ToggleStyle where Self == GlassToggleStyle {
    static var liquidGlass: GlassToggleStyle { GlassToggleStyle() }
    static func liquidGlass(tint: Color) -> GlassToggleStyle { GlassToggleStyle(tintColor: tint) }
}

// MARK: - Native Apple Liquid Glass Segmented Picker
struct GlassSegmentedPicker<T: Hashable & Identifiable>: View {
    @Binding var selection: T
    let items: [T]
    var titleFor: (T) -> String
    var iconFor: ((T) -> String?)? = nil
    var activeTint: Color? = nil
    var selectedForegroundColor: Color? = nil
    var expandsToFillWidth: Bool = true
    var useLiquidGlass: Bool = true
    
    @Namespace private var segmentNamespace
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                let isSelected = selection == item
                
                Button(action: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = item
                    }
                    HapticsManager.shared.trigger(.selection)
                }) {
                    HStack(spacing: 6) {
                        if let icon = iconFor?(item) {
                            Image(systemName: icon)
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text(titleFor(item))
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, expandsToFillWidth ? 6 : 12)
                    .frame(maxWidth: expandsToFillWidth ? .infinity : nil)
                    .frame(height: 36)
                    .foregroundStyle(
                        isSelected
                            ? (selectedForegroundColor ?? SpendyColors.elevatedControlForeground)
                            : SpendyColors.textSecondary
                    )
                    .background {
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(activeSegmentFill)
                                .overlay {
                                    Capsule(style: .continuous)
                                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                                }
                                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 1)
                                .matchedGeometryEffect(id: "activeSegmentHighlight", in: segmentNamespace)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(height: 44)
        .background {
            if !useLiquidGlass {
                Capsule(style: .continuous)
                    .fill(Color(hex: "#1C1C1E"))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.04), lineWidth: 0.8)
                    }
            }
        }
        .modifier(ConditionalLiquidGlassCapsule(enabled: useLiquidGlass))
    }
    
    private var activeSegmentFill: Color {
        if let tint = activeTint, tint != .white {
            return tint
        }
        return SpendyColors.elevatedControlFill
    }
}

private struct ConditionalLiquidGlassCapsule: ViewModifier {
    var enabled: Bool
    
    func body(content: Content) -> some View {
        if enabled {
            content.nativeLiquidGlassCapsule(isInteractive: true)
        } else {
            content
        }
    }
}


// MARK: - View Extension Conveniences
extension View {
    func nativeLiquidGlass(
        cornerRadius: CGFloat = 20,
        isInteractive: Bool = false,
        tint: Color? = nil
    ) -> some View {
        modifier(NativeLiquidGlassModifier(
            cornerRadius: cornerRadius,
            isInteractive: isInteractive,
            tintColor: tint
        ))
    }
    
    func nativeLiquidGlassCapsule(
        isInteractive: Bool = false,
        tint: Color? = nil
    ) -> some View {
        modifier(NativeLiquidGlassCapsuleModifier(
            isInteractive: isInteractive,
            tintColor: tint
        ))
    }
    
    func nativeLiquidGlassCircle(
        isInteractive: Bool = true,
        tint: Color? = nil
    ) -> some View {
        modifier(NativeLiquidGlassCircleModifier(
            isInteractive: isInteractive,
            tintColor: tint
        ))
    }
    
    func nativeLiquidGlassPill(isSelected: Bool = false, tint: Color? = nil) -> some View {
        modifier(NativeLiquidGlassPillModifier(isSelected: isSelected, tintColor: tint))
    }
    
    func glassMorphID<ID: Hashable & Sendable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        modifier(GlassEffectIDModifier(id: id, namespace: namespace))
    }
    
    func glassMorphTransition() -> some View {
        modifier(GlassEffectTransitionModifier())
    }
    
    func glassMorphUnion<ID: Hashable & Sendable>(id: ID? = nil, namespace: Namespace.ID? = nil) -> some View {
        modifier(GlassEffectUnionModifier(id: id, namespace: namespace))
    }
}

// MARK: - Spendy Glass Button Styles (Blueprint §12 & §72)
public struct SpendyGlassButtonStyle: ButtonStyle {
    public var isProminent: Bool = false
    public var tintColor: Color? = nil
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background {
                if isProminent {
                    Capsule(style: .continuous)
                        .fill(tintColor ?? SpendyColors.primaryBlue)
                        .shadow(color: (tintColor ?? SpendyColors.primaryBlue).opacity(0.35), radius: 8, y: 2)
                } else {
                    Capsule(style: .continuous)
                        .fill(SpendyColors.cardBackgroundSecondary)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: AppGlass.strokeWidth)
                        )
                }
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppMotion.snappySpring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SpendyGlassButtonStyle {
    public static var spendyGlass: SpendyGlassButtonStyle { SpendyGlassButtonStyle(isProminent: false) }
    public static var spendyGlassProminent: SpendyGlassButtonStyle { SpendyGlassButtonStyle(isProminent: true) }
    public static func spendyGlassProminent(tint: Color) -> SpendyGlassButtonStyle {
        SpendyGlassButtonStyle(isProminent: true, tintColor: tint)
    }
}

// MARK: - Spendy Glass Effect Container
struct SpendyGlassEffectContainer<Content: View>: View {
    var spacing: CGFloat = AppSpacing.md10
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

// MARK: - Glass Button Group (Fluid Liquid Cluster)
struct GlassButtonGroup<Content: View>: View {
    var spacing: CGFloat = AppSpacing.sm
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                HStack(spacing: spacing) {
                    content()
                }
            }
        } else {
            HStack(spacing: spacing) {
                content()
            }
        }
    }
}

// MARK: - Optional Matched Geometry Extension
extension View {
    @ViewBuilder
    func optionalMatchedGeometry(id: String, in namespace: Namespace.ID?) -> some View {
        if let namespace = namespace {
            self.matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}

// MARK: - Spendy Sheet Liquid Glass Presentation Background
struct SpendySheetLiquidGlassBackground: View {
    var cornerRadius: CGFloat = 32
    
    var body: some View {
        if #available(iOS 26, *) {
            Color.clear
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(SpendyColors.glassFallbackFill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
}

extension View {
    func presentationLiquidGlass(cornerRadius: CGFloat = 32) -> some View {
        self.presentationBackground {
            SpendySheetLiquidGlassBackground(cornerRadius: cornerRadius)
        }
    }
}
