//
//  MainTabView.swift
//  Spendy
//
//  Root Navigation Shell hosting Home, Subscriptions, and Floating Bottom Dock
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddTransaction: Bool = false
    @State private var quickActionManager = QuickActionManager.shared
    @Namespace private var composeNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Screen Content
            ZStack {
                DashboardView(showAddTransaction: $showAddTransaction, selectedTab: $selectedTab)
                    .opacity(selectedTab == .home ? 1 : 0)
                    .allowsHitTesting(selectedTab == .home)

                NavigationStack {
                    SubscriptionsView()
                }
                .opacity(selectedTab == .subscriptions ? 1 : 0)
                .allowsHitTesting(selectedTab == .subscriptions)

                NavigationStack {
                    AnalyticsView(selectedTab: $selectedTab)
                }
                .opacity(selectedTab == .analytics ? 1 : 0)
                .allowsHitTesting(selectedTab == .analytics)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Bottom Dock (Home + Subscriptions + Hero Blue Spend Pill)
            GlassTabBar(
                selectedTab: $selectedTab,
                onQuickAdd: {
                    showAddTransaction = true
                }
            )
            .padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .onChange(of: quickActionManager.shouldPresentQuickAdd) { _, shouldPresent in
            if shouldPresent {
                showAddTransaction = true
                quickActionManager.shouldPresentQuickAdd = false
            }
        }
        .onChange(of: quickActionManager.targetTab) { _, target in
            if let target {
                withAnimation(AppMotion.snappySpring) {
                    selectedTab = target
                }
                quickActionManager.targetTab = nil
            }
        }
    }
}
