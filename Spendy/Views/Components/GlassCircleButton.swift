//
//  GlassCircleButton.swift
//  Spendy
//
//  Native Apple Liquid Glass Circular Button & Icon Component
//  Standard 44x44 pt Apple HIG Touch Target with Spring Micro-Interactions & Haptics
//

import SwiftUI

// MARK: - Glass Circle Press Style
struct GlassCirclePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Glass Circle Default Icon View
struct GlassCircleDefaultIconView: View {
    let icon: String
    let iconSize: CGFloat
    let iconWeight: Font.Weight
    let foregroundColor: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: iconSize, weight: iconWeight))
            .foregroundStyle(foregroundColor)
    }
}

// MARK: - Glass Circle Icon (Label / Container)
struct GlassCircleIcon<Content: View>: View {
    var size: CGFloat = 44
    var tintColor: Color? = nil
    var isInteractive: Bool = true
    @ViewBuilder var content: () -> Content
    
    init(
        size: CGFloat = 44,
        tintColor: Color? = nil,
        isInteractive: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.size = size
        self.tintColor = tintColor
        self.isInteractive = isInteractive
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
        }
        .frame(width: size, height: size)
        .nativeLiquidGlassCircle(isInteractive: isInteractive, tint: tintColor)
    }
}

extension GlassCircleIcon where Content == GlassCircleDefaultIconView {
    init(
        icon: String,
        size: CGFloat = 44,
        iconSize: CGFloat = 16,
        iconWeight: Font.Weight = .bold,
        tintColor: Color? = nil,
        foregroundColor: Color = SpendyColors.textPrimary,
        isInteractive: Bool = true
    ) {
        self.size = size
        self.tintColor = tintColor
        self.isInteractive = isInteractive
        self.content = {
            GlassCircleDefaultIconView(
                icon: icon,
                iconSize: iconSize,
                iconWeight: iconWeight,
                foregroundColor: foregroundColor
            )
        }
    }
}

// MARK: - Glass Circle Button
struct GlassCircleButton<Content: View>: View {
    var size: CGFloat = 44
    var tintColor: Color? = nil
    var haptic: HapticsManager.FeedbackStyle? = .light
    var accessibilityLabel: String? = nil
    var action: () -> Void
    @ViewBuilder var content: () -> Content
    
    // Initializer for custom content
    init(
        size: CGFloat = 44,
        tintColor: Color? = nil,
        haptic: HapticsManager.FeedbackStyle? = .light,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.size = size
        self.tintColor = tintColor
        self.haptic = haptic
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: {
            if let haptic = haptic {
                HapticsManager.shared.trigger(haptic)
            }
            action()
        }) {
            GlassCircleIcon(size: size, tintColor: tintColor, isInteractive: true) {
                content()
            }
        }
        .buttonStyle(GlassCirclePressStyle())
        .accessibilityLabel(accessibilityLabel ?? "")
    }
}

extension GlassCircleButton where Content == GlassCircleDefaultIconView {
    // Initializer for SF Symbol icon
    init(
        icon: String,
        size: CGFloat = 44,
        iconSize: CGFloat = 16,
        iconWeight: Font.Weight = .bold,
        tintColor: Color? = nil,
        foregroundColor: Color = SpendyColors.textPrimary,
        haptic: HapticsManager.FeedbackStyle? = .light,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.size = size
        self.tintColor = tintColor
        self.haptic = haptic
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.content = {
            GlassCircleDefaultIconView(
                icon: icon,
                iconSize: iconSize,
                iconWeight: iconWeight,
                foregroundColor: foregroundColor
            )
        }
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground
            .ignoresSafeArea()
        
        HStack(spacing: 16) {
            GlassCircleButton(icon: "calendar") {
                print("Calendar tapped")
            }
            
            GlassCircleButton(icon: SFIcons.edit) {
                print("Edit tapped")
            }
            
            GlassCircleButton(
                icon: SFIcons.trash,
                tintColor: SpendyColors.expenseRed,
                foregroundColor: SpendyColors.expenseRed,
                haptic: .warning
            ) {
                print("Delete tapped")
            }
        }
    }
}
