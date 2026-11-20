//
//  GlassCircleButton.swift
//  Spendy
//
//  Native Apple Liquid Glass Circular Button & Icon Component
//  System glass press behavior with a minimum 44-point touch target and app haptics
//

import SwiftUI

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
            .contentTransition(.symbolEffect(.replace.downUp))
    }
}

// MARK: - Glass Circle Icon (Label / Container)
struct GlassCircleIcon<Content: View>: View {
    var size: CGFloat = 44
    var tintColor: Color? = nil
    var isInteractive: Bool = true
    var morphID: String? = nil
    var namespace: Namespace.ID? = nil
    @ViewBuilder var content: () -> Content
    
    init(
        size: CGFloat = 44,
        tintColor: Color? = nil,
        isInteractive: Bool = true,
        morphID: String? = nil,
        namespace: Namespace.ID? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.size = size
        self.tintColor = tintColor
        self.isInteractive = isInteractive
        self.morphID = morphID
        self.namespace = namespace
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
        }
        .frame(width: size, height: size)
        .nativeLiquidGlassCircle(isInteractive: isInteractive, tint: tintColor)
        .modifier(OptionalGlassMorphModifier(id: morphID, namespace: namespace))
    }
}

struct OptionalGlassMorphModifier: ViewModifier {
    var id: String?
    var namespace: Namespace.ID?
    
    func body(content: Content) -> some View {
        if let id = id, let namespace = namespace {
            content.glassMorphID(id, in: namespace)
        } else {
            content
        }
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
        isInteractive: Bool = true,
        morphID: String? = nil,
        namespace: Namespace.ID? = nil
    ) {
        self.size = size
        self.tintColor = tintColor
        self.isInteractive = isInteractive
        self.morphID = morphID
        self.namespace = namespace
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
    var morphID: String? = nil
    var namespace: Namespace.ID? = nil
    var action: () -> Void
    @ViewBuilder var content: () -> Content
    
    // Initializer for custom content
    init(
        size: CGFloat = 44,
        tintColor: Color? = nil,
        haptic: HapticsManager.FeedbackStyle? = .light,
        accessibilityLabel: String? = nil,
        morphID: String? = nil,
        namespace: Namespace.ID? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.size = size
        self.tintColor = tintColor
        self.haptic = haptic
        self.accessibilityLabel = accessibilityLabel
        self.morphID = morphID
        self.namespace = namespace
        self.action = action
        self.content = content
    }
    
    var body: some View {
        let button = Button {
            if let haptic { HapticsManager.shared.trigger(haptic) }
            action()
        } label: {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glass(.regular.tint(tintColor)))
        .buttonBorderShape(.circle)
        .buttonSizing(.flexible)
        .frame(width: max(44, size), height: max(44, size))
        .modifier(OptionalGlassMorphModifier(id: morphID, namespace: namespace))

        if let accessibilityLabel {
            button.accessibilityLabel(accessibilityLabel)
        } else {
            button
        }
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
        morphID: String? = nil,
        namespace: Namespace.ID? = nil,
        action: @escaping () -> Void
    ) {
        self.size = size
        self.tintColor = tintColor
        self.haptic = haptic
        self.accessibilityLabel = accessibilityLabel
        self.morphID = morphID
        self.namespace = namespace
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
