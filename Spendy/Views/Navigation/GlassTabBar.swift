//
//  GlassTabBar.swift
//  Spendy
//
//  Ultra-Refined Liquid Glass Bottom Navigation matching Apple Design System
//  Featuring 4 navigation tabs in one floating capsule with a detached Quick-Add button
//

import SwiftUI

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

struct GlassTabBar: View {
    @Binding var selectedTab: AppTab
    var onQuickAdd: () -> Void
    
    @Namespace private var tabNamespace
    
    var body: some View {
        HStack(spacing: 12) {
            tabPill
            
            quickAddButton
        }
        .padding(.horizontal, 16)
    }
    
    private var tabPill: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                TabButton(
                    title: tab.label,
                    systemImage: tab.sfSymbol,
                    isSelected: selectedTab == tab,
                    namespace: tabNamespace
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(6)
        .frame(height: 64)
        .nativeLiquidGlassCapsule(isInteractive: true)
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
    }
    
    private var quickAddButton: some View {
        Button(action: {
            HapticsManager.shared.trigger(.medium)
            onQuickAdd()
        }) {
            Image(systemName: SFIcons.quickAdd)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background {
                    Circle()
                        .fill(SpendyColors.primaryBlue)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.55),
                                            Color.white.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.8
                                )
                        }
                }
                .nativeLiquidGlassCircle(isInteractive: true, tint: SpendyColors.primaryBlue)
                .shadow(color: SpendyColors.primaryBlue.opacity(0.34), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add transaction")
    }
}

// MARK: - Subcomponent for Individual Tab Buttons
struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 24)
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.68))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(SpendyColors.primaryBlue.opacity(0.92))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.50),
                                            Color.white.opacity(0.10)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.8
                                )
                        }
                        .matchedGeometryEffect(id: "selectedTab", in: namespace)
                        .shadow(color: SpendyColors.primaryBlue.opacity(0.30), radius: 10, x: 0, y: 4)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

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
