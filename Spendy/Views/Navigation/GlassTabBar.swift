//
//  GlassTabBar.swift
//  Spendy
//
//  Native iOS 26 Liquid Glass Bottom Navigation
//  Floating capsule pill with 4 tabs (tap + long-press drag) and detached Quick-Add button
//  Wrapped in GlassEffectContainer for unified glass rendering and morphing
//

import SwiftUI

// MARK: - Tab Model

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case analytics
    case budget
    case manage
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .home: return "Home"
        case .analytics: return "Stats"
        case .budget: return "Budget"
        case .manage: return "Manage"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .home: return SFIcons.tabDashboard
        case .analytics: return SFIcons.tabAnalytics
        case .budget: return SFIcons.tabBudget
        case .manage: return SFIcons.tabManage
        }
    }
}

// MARK: - Draggable Glass Tab Bar

struct GlassTabBar: View {
    @Binding var selectedTab: AppTab
    var onQuickAdd: () -> Void
    
    @Namespace private var tabHighlightNamespace
    @State private var isDragging: Bool = false
    
    /// Per-tab frames captured via GeometryReader preferences
    @State private var tabFrames: [AppTab: CGRect] = [:]
    
    var body: some View {
        HStack(spacing: 12) {
            tabPill
            quickAddButton
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Tab Pill
    
    private var tabPill: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabItem(for: tab)
            }
        }
        .padding(4)
        .frame(height: 64)
        .glassEffect(.regular.interactive(), in: .capsule)
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
        .coordinateSpace(name: "tabPill")
        .onPreferenceChange(TabFramePreferenceKey.self) { frames in
            tabFrames = frames
        }
        .gesture(dragGesture)
    }
    
    // MARK: - Individual Tab Item
    
    private func tabItem(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        
        return Button(action: {
            guard !isDragging else { return }
            HapticsManager.shared.trigger(.selection)
            withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.sfSymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 24)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            .animation(.spring(response: 0.30, dampingFraction: 0.76), value: isSelected)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .glassEffect(
                            .regular.tint(SpendyColors.primaryBlue).interactive(),
                            in: .capsule
                        )
                        .glassEffectID("selectedTabHighlight", in: tabHighlightNamespace)
                        .shadow(
                            color: SpendyColors.primaryBlue.opacity(isDragging ? 0.45 : 0.30),
                            radius: isDragging ? 14 : 10,
                            x: 0,
                            y: isDragging ? 6 : 4
                        )
                        .scaleEffect(isDragging ? 1.08 : 1.0)
                        .matchedGeometryEffect(id: "selectedTab", in: tabHighlightNamespace)
                }
            }
            .contentShape(Capsule())
            // Capture each tab's frame for drag hit-testing
            .background {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: TabFramePreferenceKey.self,
                            value: [tab: geo.frame(in: .named("tabPill"))]
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Drag Gesture
    
    /// Long-press (0.2s) sequenced with drag to enable hold-and-slide tab switching
    private var dragGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("tabPill")))
            .onChanged { value in
                switch value {
                case .second(true, let drag):
                    if !isDragging {
                        isDragging = true
                        HapticsManager.shared.trigger(.selection)
                    }
                    
                    guard let drag = drag else { return }
                    
                    // Find which tab the finger is over
                    if let hoveredTab = tabAtLocation(drag.location) {
                        if hoveredTab != selectedTab {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
                                selectedTab = hoveredTab
                            }
                        }
                    }
                default:
                    break
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
                    isDragging = false
                }
            }
    }
    
    /// Determines which tab the given point falls within, using captured GeometryReader frames
    private func tabAtLocation(_ point: CGPoint) -> AppTab? {
        for tab in AppTab.allCases {
            if let frame = tabFrames[tab], frame.contains(point) {
                return tab
            }
        }
        // Fallback: find the nearest tab by horizontal distance
        var closest: AppTab?
        var closestDistance: CGFloat = .infinity
        for tab in AppTab.allCases {
            if let frame = tabFrames[tab] {
                let distance = abs(frame.midX - point.x)
                if distance < closestDistance {
                    closestDistance = distance
                    closest = tab
                }
            }
        }
        return closest
    }
    
    // MARK: - Quick Add Button
    
    private var quickAddButton: some View {
        Button(action: {
            HapticsManager.shared.trigger(.medium)
            onQuickAdd()
        }) {
            Image(systemName: SFIcons.quickAdd)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(SpendyColors.appBackground)
                .frame(width: 58, height: 58)
                .background {
                    Circle()
                        .fill(SpendyColors.textPrimary)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add transaction")
    }
}

// MARK: - Preference Key for Tab Frames

struct TabFramePreferenceKey: PreferenceKey {
    static var defaultValue: [AppTab: CGRect] = [:]
    
    static func reduce(value: inout [AppTab: CGRect], nextValue: () -> [AppTab: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - Extension to collect tab frames

extension View {
    func onTabFramesChange(_ action: @escaping ([AppTab: CGRect]) -> Void) -> some View {
        self.onPreferenceChange(TabFramePreferenceKey.self, perform: action)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        SpendyColors.appBackground
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            GlassTabBar(
                selectedTab: .constant(.home),
                onQuickAdd: {}
            )
            .padding(.bottom, 8)
        }
    }
    .preferredColorScheme(.dark)
}
