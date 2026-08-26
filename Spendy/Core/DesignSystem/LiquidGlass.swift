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
                        .overlay {
                            if let tint = tintColor {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(tint.opacity(0.12))
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
                        .fill(isSelected ? (tintColor ?? SpendyColors.primaryBlue) : SpendyColors.cardBackgroundSecondary)
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
                        .overlay {
                            if let tint = tintColor {
                                Capsule(style: .continuous)
                                    .fill(tint.opacity(0.14))
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
                        .overlay {
                            if let tint = tintColor {
                                Circle()
                                    .fill(tint.opacity(0.18))
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

struct GlassEffectIDModifier<ID: Hashable>: ViewModifier {
    var id: ID
    var namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffectID(id, in: namespace)
        } else {
            content
                .matchedGeometryEffect(id: id, in: namespace)
        }
    }
}

struct GlassEffectUnionModifier<ID: Hashable>: ViewModifier {
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
    @Namespace private var toggleNamespace
    
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
                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: 0) {
                        ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                            // Glass Pill Track
                            Capsule(style: .continuous)
                                .fill(configuration.isOn ? tintColor.opacity(0.85) : SpendyColors.cardBackgroundSecondary.opacity(0.6))
                                .glassEffect(.regular.tint(configuration.isOn ? tintColor : nil).interactive(), in: .capsule)
                                .frame(width: 50, height: 30)
                                .shadow(color: configuration.isOn ? tintColor.opacity(0.35) : Color.black.opacity(0.10), radius: 6, y: 2)
                                .glassEffectID("track", in: toggleNamespace)
                            
                            // Specular Liquid Thumb Knob
                            Circle()
                                .fill(Color(uiColor: .dynamic(light: .white, dark: .white)))
                                .overlay {
                                    Circle()
                                        .stroke(SpendyColors.separator.opacity(0.6), lineWidth: 0.5)
                                }
                                .glassEffect(.regular.interactive(), in: .circle)
                                .frame(width: 26, height: 26)
                                .padding(.horizontal, 2)
                                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1.5)
                                .glassEffectID("knob", in: toggleNamespace)
                        }
                        .frame(width: 50, height: 30)
                    }
                } else {
                    ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                        // Glass Pill Track
                        Capsule(style: .continuous)
                            .fill(configuration.isOn ? tintColor : SpendyColors.cardBackgroundSecondary)
                            .overlay {
                                if !configuration.isOn {
                                    Capsule(style: .continuous)
                                        .fill(.ultraThinMaterial)
                                }
                            }
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(
                                        SpendyColors.separator,
                                        lineWidth: 0.8
                                    )
                            }
                            .frame(width: 50, height: 30)
                            .shadow(color: configuration.isOn ? tintColor.opacity(0.35) : Color.black.opacity(0.10), radius: 6, y: 2)
                        
                        // Specular Thumb Knob
                        Circle()
                            .fill(Color(uiColor: .dynamic(light: .white, dark: .white)))
                            .overlay {
                                Circle()
                                    .stroke(SpendyColors.separator, lineWidth: 0.5)
                            }
                            .frame(width: 26, height: 26)
                            .padding(.horizontal, 2)
                            .shadow(color: Color.black.opacity(0.20), radius: 3, x: 0, y: 1.5)
                    }
                }
            }
            .buttonStyle(.plain)
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
    var activeTint: Color = SpendyColors.primaryBlue
    
    @Namespace private var segmentNamespace
    
    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 4) {
                pickerContent
            }
        } else {
            pickerContent
        }
    }
    
    private var pickerContent: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                let isSelected = selection == item
                
                Button(action: {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
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
                    }
                    .foregroundStyle(
                        isSelected
                            ? (activeTint == SpendyColors.primaryBlue ? Color(uiColor: .dynamic(light: .white, dark: .black)) : Color.white)
                            : SpendyColors.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background {
                        if isSelected {
                            if #available(iOS 26, *) {
                                Capsule(style: .continuous)
                                    .fill(activeTint)
                                    .glassEffect(.regular.tint(activeTint).interactive(), in: .capsule)
                                    .shadow(color: activeTint.opacity(0.30), radius: 6, y: 1.5)
                                    .glassEffectID("activeSegmentHighlight", in: segmentNamespace)
                            } else {
                                Capsule(style: .continuous)
                                    .fill(activeTint)
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .stroke(
                                                SpendyColors.separator.opacity(0.4),
                                                lineWidth: 0.8
                                            )
                                    }
                                    .shadow(color: activeTint.opacity(0.25), radius: 6, y: 1.5)
                                    .matchedGeometryEffect(id: "activeSegmentHighlight", in: segmentNamespace)
                            }
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            if #available(iOS 26, *) {
                Capsule(style: .continuous)
                    .fill(SpendyColors.cardBackgroundSecondary.opacity(0.4))
                    .glassEffect(.clear.interactive(), in: .capsule)
            } else {
                Capsule(style: .continuous)
                    .fill(SpendyColors.cardBackgroundSecondary)
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
    
    func glassMorphID<ID: Hashable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        modifier(GlassEffectIDModifier(id: id, namespace: namespace))
    }
    
    func glassMorphUnion<ID: Hashable>(id: ID? = nil, namespace: Namespace.ID? = nil) -> some View {
        modifier(GlassEffectUnionModifier(id: id, namespace: namespace))
    }
}

// MARK: - Spendy Glass Effect Container
struct SpendyGlassEffectContainer<Content: View>: View {
    var spacing: CGFloat = 10
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
    var spacing: CGFloat = 8
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

