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
                
                Tab(AppTab.budget.label, systemImage: AppTab.budget.sfSymbol, value: AppTab.budget) {
                    BudgetView()
                }
                
                Tab(AppTab.manage.label, systemImage: AppTab.manage.sfSymbol, value: AppTab.manage) {
                    ManageView()
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
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
                    .matchedTransitionSource(id: "compose-tab", in: composeNamespace)
            }
        } else {
            ZStack(alignment: .bottom) {
                // Main Screen Content
                Group {
                    switch selectedTab {
                    case .home:
                        DashboardView(showAddTransaction: $showAddTransaction, selectedTab: $selectedTab)
                    case .analytics:
                        AnalyticsView(selectedTab: $selectedTab)
                    case .budget:
                        BudgetView()
                    case .manage:
                        ManageView()
                    case .quickAdd:
                        DashboardView(showAddTransaction: $showAddTransaction, selectedTab: $selectedTab)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Floating Liquid Glass Navigation Bar (4 Tabs + Quick Add Button)
                GlassTabBar(
                    selectedTab: $selectedTab,
                    onQuickAdd: {
                        showAddTransaction = true
                    }
                )
                .padding(.bottom, 4)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }
}
