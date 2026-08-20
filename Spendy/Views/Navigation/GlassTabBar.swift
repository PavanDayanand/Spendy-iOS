//
//  GlassTabBar.swift
//  Spendy
//
//  Ultra-Refined Liquid Glass Bottom Navigation matching Apple Design System
//  Featuring a 4-Tab Frosted Glass Pill with Matched Geometry Toggle & Separated Circular Quick-Add Button
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
        HStack(spacing: 10) {
            // MARK: - 4 Navigation Tabs Liquid Glass Pill Container
            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(height: 62)
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    }
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.55),
                                        Color.white.opacity(0.18),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.0
                            )
                    }
                    .shadow(color: Color.black.opacity(0.28), radius: 16, x: 0, y: 8)
            }
            
            // MARK: - Separated Quick Add (+) Liquid Glass Circular Button
            Button(action: {
                HapticsManager.shared.trigger(.medium)
                onQuickAdd()
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                        }
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.55),
                                            Color.white.opacity(0.18),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1.0
                                )
                        }
                        .shadow(color: Color.black.opacity(0.28), radius: 16, x: 0, y: 8)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 62, height: 62)
            }
            .buttonStyle(ScaleTouchButtonStyle())
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Individual Tab Button Item
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        
        return Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                selectedTab = tab
            }
            HapticsManager.shared.trigger(.selection)
        }) {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        // Liquid Glass Blue Circle Badge for active icon (matches reference screenshot)
                        Circle()
                            .fill(SpendyColors.primaryBlue)
                            .frame(width: 28, height: 28)
                            .shadow(color: SpendyColors.primaryBlue.opacity(0.45), radius: 6, y: 2)
                            .transition(.scale.combined(with: .opacity))
                        
                        Image(systemName: tab.sfSymbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: tab.sfSymbol)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.50))
                            .frame(width: 28, height: 28)
                    }
                }
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? SpendyColors.primaryBlue : Color.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isSelected {
                    // Floating Liquid Glass Selection Capsule
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.14))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.40),
                                            Color.white.opacity(0.08)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.8
                                )
                        }
                        .matchedGeometryEffect(id: "activeTabGlassHighlight", in: tabNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Smooth Scale Touch Button Style
struct ScaleTouchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
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
