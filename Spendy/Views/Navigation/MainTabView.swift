//
//  MainTabView.swift
//  Spendy
//
//  Root Navigation Shell hosting 4 Tabs and Floating Liquid Glass Navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddTransaction: Bool = false
    @Namespace private var composeNamespace
    
    var body: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
                Tab(AppTab.home.label, systemImage: AppTab.home.sfSymbol, value: AppTab.home) {
                    DashboardView(showAddTransaction: $showAddTransaction, selectedTab: $selectedTab)
                }
                
                Tab(AppTab.analytics.label, systemImage: AppTab.analytics.sfSymbol, value: AppTab.analytics) {
                    AnalyticsView(selectedTab: $selectedTab)
                }
                
                Tab(AppTab.subscriptions.label, systemImage: AppTab.subscriptions.sfSymbol, value: AppTab.subscriptions) {
                    NavigationStack {
                        SubscriptionsView()
                    }
                }
                
                Tab(value: AppTab.quickAdd, role: .search) {
                    Color.clear
                } label: {
                    Label("Add", systemImage: "plus")
                        .matchedTransitionSource(id: "compose-tab", in: composeNamespace)
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tabBarMinimizeBehavior(.onScrollDown)
            .tint(SpendyColors.tabSelectedBlue)
            .onChange(of: selectedTab) { oldTab, newTab in
                if newTab == .quickAdd {
                    withAnimation {
                        showAddTransaction = true
                    }
                    selectedTab = oldTab
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .fullScreenCover(isPresented: $showAddTransaction) {
                AddTransactionView()
                    .matchedTransitionSource(id: "compose-tab", in: composeNamespace)
            }
        } else {
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
        }
    }
}
