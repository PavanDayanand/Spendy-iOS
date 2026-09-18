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
    @State private var isHomeDrawerExpanded: Bool = false
    @State private var isHomeSubpageActive: Bool = false
    @State private var isAnalyticsSubpageActive: Bool = false
    @State private var quickActionManager = QuickActionManager.shared
    @Namespace private var composeNamespace

    private var isDockVisible: Bool {
        switch selectedTab {
        case .home:
            return !isHomeSubpageActive
        case .analytics:
            return !isAnalyticsSubpageActive
        case .subscriptions, .quickAdd:
            return true
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Screen Content
            ZStack {
                DashboardView(
                    showAddTransaction: $showAddTransaction,
                    selectedTab: $selectedTab,
                    isSheetExpandedBinding: $isHomeDrawerExpanded,
                    isSubpageActiveBinding: $isHomeSubpageActive
                )
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)

                NavigationStack {
                    SubscriptionsView()
                }
                .opacity(selectedTab == .subscriptions ? 1 : 0)
                .allowsHitTesting(selectedTab == .subscriptions)

                NavigationStack {
                    AnalyticsView(
                        selectedTab: $selectedTab,
                        isSubpageActiveBinding: $isAnalyticsSubpageActive
                    )
                }
                .opacity(selectedTab == .analytics ? 1 : 0)
                .allowsHitTesting(selectedTab == .analytics)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Adaptive Bottom Dock (Home + Subscriptions + Hero Blue Spend Pill)
            GlassTabBar(
                selectedTab: $selectedTab,
                isExpanded: selectedTab == .home ? isHomeDrawerExpanded : true,
                onQuickAdd: {
                    showAddTransaction = true
                }
            )
            .padding(.bottom, 6)
            .offset(y: isDockVisible ? 0 : 120)
            .opacity(isDockVisible ? 1 : 0)
            .allowsHitTesting(isDockVisible)
            .animation(AppMotion.fluidSpring, value: isDockVisible)
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
