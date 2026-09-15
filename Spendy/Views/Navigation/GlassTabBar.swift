//
//  LiquidGlassNavigation.swift
//  Spendy
//
//  iOS 26 & iOS 27 Bottom Navigation with Dynamic Matched Gliding and Touch Feedback
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
        case .home: return SFIcons.tabDashboardOutline
        case .analytics: return SFIcons.tabAnalyticsOutline
        case .subscriptions: return SFIcons.subscriptions
        case .quickAdd: return SFIcons.quickAdd
        }
    }

    var activeSfSymbol: String {
        switch self {
        case .home: return SFIcons.tabDashboard
        case .analytics: return SFIcons.tabAnalytics
        case .subscriptions: return SFIcons.subscriptions
        case .quickAdd: return SFIcons.quickAdd
        }
    }
}

// MARK: - Main Adaptive Container

struct LiquidGlassRootView: View {
    @State private var selectedTab: AppTab = .home
    @State private var sidebarSelection: AppTab? = .home
    @State private var showQuickAdd: Bool = false

    var body: some View {
        NavigationSplitView {
            List(AppTab.allCases, selection: $sidebarSelection) { tab in
                Label(tab.label, systemImage: tab.sfSymbol)
                    .tag(tab as AppTab?)
            }
            .navigationTitle("Spendy")
        } detail: {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(0..<20) { _ in
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primary.opacity(0.05))
                                .frame(height: 100)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 100)
                }
                .ignoresSafeArea(edges: .bottom)

                GlassTabBar(selectedTab: Binding(
                    get: { sidebarSelection ?? selectedTab },
                    set: { newValue in
                        selectedTab = newValue
                        sidebarSelection = newValue
                    }
                )) {
                    showQuickAdd = true
                }
                .padding(.bottom, 8)
            }
        }
        .onChange(of: sidebarSelection) { oldValue, newValue in
            if let newValue {
                selectedTab = newValue
            }
        }
    }
}

// MARK: - Liquid Glass Tab Bar

struct GlassTabBar: View {
    @Binding var selectedTab: AppTab
    let onQuickAdd: () -> Void

    @Namespace private var tabBarNamespace

    private let barHeight: CGFloat = 64
    private let quickAddSize: CGFloat = 60

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    tabBarContent(isGlass: true)
                        .frame(height: barHeight)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .glassEffectID("tabBarPill", in: tabBarNamespace)
                        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)

                    // Quick Add Floating Button (1 Separated Plus on Right)
                    Button {
                        HapticsManager.shared.trigger(.cardSnap)
                        onQuickAdd()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: quickAddSize, height: quickAddSize)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .glassEffectID("quickAddButton", in: tabBarNamespace)
                            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
                    }
                    .buttonStyle(LiquidScaleButtonStyle())
                }
                .padding(.horizontal, 20)
            }
        } else {
            fallbackContent
        }
    }

    @ViewBuilder
    var fallbackContent: some View {
        HStack(spacing: 12) {
            tabBarContent(isGlass: false)
                .frame(height: barHeight)
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)

            // Quick Add Floating Button (Fallback)
            Button {
                HapticsManager.shared.trigger(.cardSnap)
                onQuickAdd()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.primary)
                    .frame(width: quickAddSize, height: quickAddSize)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle().strokeBorder(SpendyColors.separator, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(LiquidScaleButtonStyle())
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Interactive Tab Bar Layout Content

private extension GlassTabBar {

    func tabBarContent(isGlass: Bool) -> some View {
        let mainTabs: [AppTab] = [.home, .analytics, .subscriptions]
        return GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let count = CGFloat(mainTabs.count)
            let itemWidth = count > 0 ? totalWidth / count : 0
            let activeIndex = CGFloat(mainTabs.firstIndex(of: selectedTab) ?? 0)

            let pillWidth = max(24, itemWidth - 8)
            let pillHeight: CGFloat = 44
            let currentOffset: CGFloat = (activeIndex * itemWidth) + 4

            ZStack(alignment: .leading) {
                // Background Shell for Non-Glass Fallback
                if !isGlass {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(SpendyColors.separator, lineWidth: 1)
                        )
                }

                // Dynamic Gliding Pill Indicator (Sticky & Anchored to Selected Tab)
                Capsule(style: .continuous)
                    .fill(SpendyColors.elevatedControlFill)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(SpendyColors.separator, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 8, y: 2)
                    .frame(width: pillWidth, height: pillHeight)
                    .offset(x: currentOffset)
                    .animation(.spring(response: 0.26, dampingFraction: 0.68), value: selectedTab)

                // Interactive Tab Elements (3 Tabs on the left)
                HStack(spacing: 0) {
                    ForEach(mainTabs) { tab in
                        let isSelected = selectedTab == tab

                        VStack(spacing: 3) {
                            Image(systemName: isSelected ? tab.activeSfSymbol : tab.sfSymbol)
                                .font(.system(size: 19, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textSecondary)
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                                .contentTransition(.symbolEffect(.replace.downUp))
                                .symbolEffect(.bounce.byLayer, value: isSelected)

                            Text(tab.label)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .default))
                                .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectWithHaptic(tab)
                        }
                    }
                }
            }
        }
    }

    private func selectWithHaptic(_ tab: AppTab) {
        guard selectedTab != tab else { return }
        HapticsManager.shared.trigger(.selection)
        withAnimation(AppMotion.snappySpring) {
            selectedTab = tab
        }
    }
}

// MARK: - Scale Animation Style

struct LiquidScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
