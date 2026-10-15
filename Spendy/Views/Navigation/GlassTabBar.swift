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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selectedTab: AppTab
    var isExpanded: Bool = true
    var composeNamespace: Namespace.ID? = nil
    let onQuickAdd: () -> Void
    var receiptNeedsIntroduction: Bool = false
    var receiptMenuRequest: Int = 0
    var onReceiptIntroduction: () -> Void = {}
    var onReceiptSource: (ReceiptSourceMenuButton.Source) -> Void = { _ in }
    @Namespace private var dockNamespace

    private var circleButtonSize: CGFloat {
        isExpanded ? 56 : 50
    }
    private var pillHeight: CGFloat {
        isExpanded ? 56 : 50
    }
    var body: some View {
        GeometryReader { geometry in
            dockContent(compact: geometry.size.width < 360)
        }
        .frame(height: pillHeight)
    }

    private func dockContent(compact: Bool) -> some View {
        let spacing: CGFloat = compact ? 8 : (isExpanded ? 12 : 8)
        return SpendyGlassEffectContainer(spacing: spacing) {
            HStack(spacing: spacing) {
                // Navigation Circle Buttons with adaptive responsive spacing
                HStack(spacing: spacing) {
                    // 1. Home Circle Liquid Glass Button
                    navLiquidGlassButton(
                        tab: .home,
                        symbol: selectedTab == .home ? "house.fill" : "house",
                        label: "Home", compact: compact
                    )

                    // 2. Subscriptions Circle Liquid Glass Button (SF Symbol: arrow.triangle.2.circlepath)
                    navLiquidGlassButton(
                        tab: .subscriptions,
                        symbol: SFIcons.subscriptions,
                        label: "Subscriptions", compact: compact
                    )
                }
                .padding(.leading, isExpanded ? 6 : 4)

                if selectedTab != .subscriptions {
                    Spacer(minLength: compact ? 0 : (isExpanded ? 12 : 8))

                    if selectedTab == .home {
                        ReceiptSourceMenuButton(usesDockStyle: true,
                            needsIntroduction: receiptNeedsIntroduction,
                            presentationRequest: receiptMenuRequest,
                            onIntroduction: onReceiptIntroduction,
                            onSelect: onReceiptSource)
                            .frame(width: 44, height: 44)
                            .nativeLiquidGlassCircle(isInteractive: true)
                            .accessibilityHint("Choose a receipt image to review before adding")
                    }

                    // Transaction entry belongs on Home; Subscriptions has its own add button.
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
                        .padding(.horizontal, compact ? 16 : (isExpanded ? 24 : 18))
                        .frame(height: pillHeight)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(LiquidScaleButtonStyle())
                    .modifier(HeroSpendLiquidGlassModifier(tint: SpendyColors.elevatedControlFill))
                    .spendyNavigationSource(AppTransitionIDs.quickAddButton, in: composeNamespace)
                    .accessibilityLabel("Add Transaction")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.horizontal, compact ? 12 : (isExpanded ? 16 : 22))
            .frame(maxWidth: .infinity, alignment: selectedTab == .subscriptions ? .center : .leading)
            .animation(reduceMotion ? nil : AppMotion.fluidSpring, value: isExpanded)
            .animation(reduceMotion ? nil : AppMotion.fluidSpring, value: selectedTab)
        }
    }

    // MARK: - Navigation Circle Glass Button
    private func navLiquidGlassButton(tab: AppTab, symbol: String, label: String, compact: Bool) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectWithHaptic(tab)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                .frame(width: compact ? 44 : circleButtonSize, height: compact ? 44 : circleButtonSize)
                .contentShape(Circle())
                .contentTransition(.symbolEffect(.replace.downUp))
                .symbolEffect(.bounce.byLayer, value: reduceMotion ? false : isSelected)
        }
        .buttonStyle(LiquidScaleButtonStyle())
        .modifier(CircleLiquidGlassModifier(isSelected: isSelected))
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    private func selectWithHaptic(_ tab: AppTab) {
        guard selectedTab != tab else { return }
        HapticsManager.shared.trigger(.selection)
        withAnimation(reduceMotion ? nil : AppMotion.snappySpring) {
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
