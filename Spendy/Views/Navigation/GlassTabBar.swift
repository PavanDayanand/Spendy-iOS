//
//  GlassTabBar.swift
//  Spendy
//
//  Bottom Floating Liquid Glass Dock Navigation:
//  - Left: Home circle button with native Apple Liquid Glass (.glassEffect in .circle)
//  - Next: Subscriptions circle button with native Apple Liquid Glass (.glassEffect in .circle)
//  - Right: adaptive monochrome "+ Add" capsule button with native Apple Liquid Glass
//

import SwiftUI

// MARK: - App Tab Model

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case analytics
    case subscriptions
    case quickAdd

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: return "Home"
        case .analytics: return "Stats"
        case .subscriptions: return "Subscriptions"
        case .quickAdd: return "Add"
        }
    }

    var sfSymbol: String {
        switch self {
        case .home: return "house"
        case .analytics: return SFIcons.tabAnalyticsOutline
        case .subscriptions: return SFIcons.subscriptions
        case .quickAdd: return "plus"
        }
    }

    var activeSfSymbol: String {
        switch self {
        case .home: return "house.fill"
        case .analytics: return SFIcons.tabAnalytics
        case .subscriptions: return SFIcons.subscriptions
        case .quickAdd: return "plus"
        }
    }
}

// MARK: - Liquid Glass Dock Navigation Bar

struct GlassTabBar: View {
    @Binding var selectedTab: AppTab
    var isExpanded: Bool = true
    let onQuickAdd: () -> Void
    @Namespace private var dockNamespace

    private var circleButtonSize: CGFloat {
        isExpanded ? 56 : 50
    }
    private var pillHeight: CGFloat {
        isExpanded ? 56 : 50
    }
    var body: some View {
        SpendyGlassEffectContainer(spacing: isExpanded ? 12 : 8) {
            HStack(spacing: isExpanded ? 12 : 8) {
                // Navigation Circle Buttons with adaptive responsive spacing
                HStack(spacing: isExpanded ? 12 : 8) {
                    // 1. Home Circle Liquid Glass Button
                    navLiquidGlassButton(
                        tab: .home,
                        symbol: selectedTab == .home ? "house.fill" : "house",
                        label: "Home"
                    )

                    // 2. Subscriptions Circle Liquid Glass Button (SF Symbol: arrow.triangle.2.circlepath)
                    navLiquidGlassButton(
                        tab: .subscriptions,
                        symbol: SFIcons.subscriptions,
                        label: "Subscriptions"
                    )
                }
                .padding(.leading, isExpanded ? 6 : 4)

                Spacer(minLength: isExpanded ? 12 : 8)

                // 3. Primary "+ Add" Capsule Pill
                Button {
                    HapticsManager.shared.trigger(.cardSnap)
                    onQuickAdd()
                } label: {
                    HStack(spacing: isExpanded ? 7 : 5) {
                        Image(systemName: "plus")
                            .font(.system(size: isExpanded ? 17 : 15, weight: .bold))
                        Text("Add")
                            .font(.system(size: isExpanded ? 16 : 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(SpendyColors.elevatedControlForeground)
                    .padding(.horizontal, isExpanded ? 24 : 18)
                    .frame(height: pillHeight)
                    .contentShape(Capsule())
                }
                .buttonStyle(LiquidScaleButtonStyle())
                .modifier(HeroSpendLiquidGlassModifier(tint: SpendyColors.elevatedControlFill))
                .accessibilityLabel("Add Transaction")
                .accessibilityAddTraits(.isButton)
            }
            .padding(.horizontal, isExpanded ? 16 : 22)
            .animation(AppMotion.fluidSpring, value: isExpanded)
        }
    }

    // MARK: - Navigation Circle Glass Button
    private func navLiquidGlassButton(tab: AppTab, symbol: String, label: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectWithHaptic(tab)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                .frame(width: circleButtonSize, height: circleButtonSize)
                .contentShape(Circle())
                .contentTransition(.symbolEffect(.replace.downUp))
                .symbolEffect(.bounce.byLayer, value: isSelected)
        }
        .buttonStyle(LiquidScaleButtonStyle())
        .modifier(CircleLiquidGlassModifier(isSelected: isSelected))
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    private func selectWithHaptic(_ tab: AppTab) {
        guard selectedTab != tab else { return }
        HapticsManager.shared.trigger(.selection)
        withAnimation(AppMotion.snappySpring) {
            selectedTab = tab
        }
    }
}

// MARK: - Circle Liquid Glass Modifier

private struct CircleLiquidGlassModifier: ViewModifier {
    var isSelected: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(
                    .regular.interactive(),
                    in: .circle
                )
                .overlay {
                    if isSelected {
                        Circle()
                            .fill(Color(uiColor: .dynamic(
                                light: UIColor(white: 0.0, alpha: 0.08),
                                dark: UIColor(white: 1.0, alpha: 0.16)
                            )))
                            .allowsHitTesting(false)
                    }
                }
                .shadow(color: Color.black.opacity(isSelected ? 0.16 : 0.08), radius: 8, x: 0, y: 3)
        } else {
            content
                .background {
                    Circle()
                        .fill(isSelected
                            ? Color(uiColor: .dynamic(
                                light: UIColor(white: 0.0, alpha: 0.10),
                                dark: UIColor(white: 1.0, alpha: 0.20)
                            ))
                            : SpendyColors.glassFallbackFill
                        )
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
                .shadow(color: Color.black.opacity(isSelected ? 0.14 : 0.06), radius: 8, x: 0, y: 3)
        }
    }
}

// MARK: - Hero Spend Liquid Glass Modifier

private struct HeroSpendLiquidGlassModifier: ViewModifier {
    var tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(
                    .regular.interactive().tint(tint),
                    in: .capsule
                )
                .shadow(color: tint.opacity(0.35), radius: 12, x: 0, y: 5)
        } else {
            content
                .background(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .shadow(color: tint.opacity(0.35), radius: 12, x: 0, y: 5)
        }
    }
}

// MARK: - Button Style

private struct LiquidScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(AppMotion.snappySpring, value: configuration.isPressed)
    }
}
