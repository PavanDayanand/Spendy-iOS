//
//  LiquidGlassNavigation.swift
//  Spendy
//
//  iOS 26 Bottom Navigation with Dynamic Matched Gliding and Touch Feedback
//

import SwiftUI

// MARK: - App Tab Model

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case analytics
    case budget
    case quickAdd

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: return "Home"
        case .analytics: return "Stats"
        case .budget: return "Budget"
        case .quickAdd: return "Add"
        }
    }

    var sfSymbol: String {
        switch self {
        case .home: return "house"
        case .analytics: return "chart.bar"
        case .budget: return "dollarsign.circle"
        case .quickAdd: return "plus"
        }
    }

    var activeSfSymbol: String {
        switch self {
        case .home: return "house.fill"
        case .analytics: return "chart.bar.fill"
        case .budget: return "dollarsign.circle.fill"
        case .quickAdd: return "plus"
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

    @GestureState private var isDragging: Bool = false
    @State private var dragX: CGFloat? = nil
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

                    // Quick Add Floating Button
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
        let mainTabs: [AppTab] = [.home, .analytics, .budget]
        return GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let count = CGFloat(mainTabs.count)
            let itemWidth = totalWidth / count
            let activeIndex = CGFloat(mainTabs.firstIndex(of: selectedTab) ?? 0)

            let pillWidth = isDragging ? itemWidth + 4 : itemWidth - 8
            let pillHeight: CGFloat = isDragging ? 52 : 44

            let currentOffset: CGFloat = {
                if let dragX = dragX {
                    let halfWidth = pillWidth / 2
                    let rawX = dragX - halfWidth
                    let minOffset: CGFloat = isDragging ? -2 : 4
                    let maxOffset = totalWidth - pillWidth - (isDragging ? -2 : 4)
                    return min(max(rawX, minOffset), maxOffset)
                } else {
                    return (activeIndex * itemWidth) + (isDragging ? -2 : 4)
                }
            }()

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

                // Dynamic Gliding Pill Indicator (Expanded bubble when dragging/holding)
                Capsule(style: .continuous)
                    .fill(SpendyColors.elevatedControlFill)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(SpendyColors.separator, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(isDragging ? 0.18 : 0.10), radius: 8, y: 2)
                    .frame(width: pillWidth, height: pillHeight)
                    .offset(x: currentOffset)
                    .animation(.spring(response: 0.26, dampingFraction: 0.68), value: selectedTab)
                    .animation(.spring(response: 0.20, dampingFraction: 0.60), value: isDragging)
                    .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.80, blendDuration: 0), value: dragX)

                // Interactive Tab Elements
                HStack(spacing: 0) {
                    ForEach(mainTabs) { tab in
                        let isSelected = selectedTab == tab

                        VStack(spacing: 3) {
                            Image(systemName: isSelected ? tab.activeSfSymbol : tab.sfSymbol)
                                .font(.system(size: 19, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textSecondary)
                                .scaleEffect(isSelected && isDragging ? 1.15 : (isSelected ? 1.05 : 1.0))
                                .contentTransition(.symbolEffect(.replace.downUp))
                                .symbolEffect(.bounce.byLayer, value: isSelected)

                            Text(tab.label)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .default))
                                .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        let x = value.location.x
                        dragX = x
                        
                        let targetIndex = min(max(Int(x / itemWidth), 0), mainTabs.count - 1)
                        let newTab = mainTabs[targetIndex]

                        if newTab != selectedTab {
                            selectWithHaptic(newTab)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            dragX = nil
                        }
                    }
            )
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
