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
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
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
                        .fill(isSelected ? (tintColor ?? SpendyColors.primaryBlue) : Color.white.opacity(0.08))
                        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    isSelected ? Color.white.opacity(0.35) : Color.white.opacity(0.1),
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
    
    func nativeLiquidGlassPill(isSelected: Bool = false, tint: Color? = nil) -> some View {
        modifier(NativeLiquidGlassPillModifier(isSelected: isSelected, tintColor: tint))
    }
}
