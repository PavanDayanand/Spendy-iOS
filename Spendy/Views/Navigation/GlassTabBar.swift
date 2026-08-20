//
//  GlassTabBar.swift
//  Spendy
//
//  Native Apple Liquid Glass Navigation with GlassEffectContainer and Separated Quick Add Button
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
    
    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                // 4 Navigation Tabs Pill (Apple Native Liquid Glass)
                HStack(spacing: 0) {
                    ForEach(AppTab.allCases) { tab in
                        tabButton(for: tab)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .glassEffect(.regular.interactive(), in: .capsule)
                
                // Separated Quick Add (+) Action Button on the Right (Native Liquid Glass Prominent)
                Button(action: {
                    HapticsManager.shared.trigger(.medium)
                    onQuickAdd()
                }) {
                    Image(systemName: SFIcons.quickAdd)
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.glassProminent)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Tab Button Item
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        
        return Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                selectedTab = tab
            }
            HapticsManager.shared.trigger(.selection)
        }) {
            VStack(spacing: 3) {
                Image(systemName: tab.sfSymbol)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? SpendyColors.primaryBlue : Color.white.opacity(0.5))
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : Color.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.12))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
