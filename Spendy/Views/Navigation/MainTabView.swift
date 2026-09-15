//
//  MainTabView.swift
//  Spendy
//
//  Root Navigation Shell hosting 4 Tabs and Floating Liquid Glass Navigation
//

import SwiftUI

struct MainTabView: View {
    @Environment(QuickActionManager.self) private var quickActionManager
    @State private var selectedTab: AppTab = .home
    @State private var showAddTransaction: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Screen Content (Preserve View Hierarchies & Scroll States)
            ZStack {
                DashboardView(showAddTransaction: $showAddTransaction, selectedTab: $selectedTab)
                    .opacity(selectedTab == .home || selectedTab == .quickAdd ? 1 : 0)
                    .allowsHitTesting(selectedTab == .home || selectedTab == .quickAdd)
                
                AnalyticsView(selectedTab: $selectedTab)
                    .opacity(selectedTab == .analytics ? 1 : 0)
                    .allowsHitTesting(selectedTab == .analytics)
                
                NavigationStack {
                    SubscriptionsView()
                }
                .opacity(selectedTab == .subscriptions ? 1 : 0)
                .allowsHitTesting(selectedTab == .subscriptions)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Liquid Glass Navigation Bar (3 Tabs + Quick Add Button)
            GlassTabBar(
                selectedTab: $selectedTab,
                onQuickAdd: {
                    showAddTransaction = true
                }
            )
            .padding(.bottom, 4)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .onAppear {
            presentQuickAddIfNeeded()
        }
        .onChange(of: quickActionManager.shouldPresentQuickAdd) { _, shouldShow in
            if shouldShow {
                presentQuickAddIfNeeded()
            }
        }
        .onChange(of: quickActionManager.targetTab) { _, newTab in
            if let tab = newTab {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedTab = tab
                }
                quickActionManager.targetTab = nil
            }
        }
    }

    private func presentQuickAddIfNeeded() {
        guard quickActionManager.shouldPresentQuickAdd else { return }
        showAddTransaction = true
        quickActionManager.shouldPresentQuickAdd = false
    }
}
