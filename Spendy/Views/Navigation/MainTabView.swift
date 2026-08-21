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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Screen Content
            Group {
                switch selectedTab {
                case .home:
                    DashboardView(showAddTransaction: $showAddTransaction)
                case .analytics:
                    AnalyticsView()
                case .budget:
                    BudgetView()
                case .manage:
                    ManageView()
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
