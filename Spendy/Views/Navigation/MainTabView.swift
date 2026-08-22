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
                Tab(AppTab.home.label, systemImage: AppTab.home.sfSymbol, value: .home) {
                    DashboardView(showAddTransaction: $showAddTransaction)
                }
                
                Tab(AppTab.analytics.label, systemImage: AppTab.analytics.sfSymbol, value: .analytics) {
                    AnalyticsView()
                }
                
                Tab(AppTab.budget.label, systemImage: AppTab.budget.sfSymbol, value: .budget) {
                    BudgetView()
                }
                
                Tab(AppTab.manage.label, systemImage: AppTab.manage.sfSymbol, value: .manage) {
                    ManageView()
                }
            }
            .tint(SpendyColors.primaryBlue)
            .tabBarMinimizeBehavior(.onScrollDown)
            .overlay(alignment: .bottomTrailing) {
                // Standalone Floating Quick Add Liquid Glass Button
                Button {
                    HapticsManager.shared.trigger(.medium)
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 56, height: 56)
                        .glassEffect(.regular.interactive(), in: .circle)
                        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(LiquidScaleButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 72)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
                    .matchedTransitionSource(id: "compose-tab", in: composeNamespace)
            }
        } else {
            ZStack(alignment: .bottomTrailing) {
                TabView(selection: $selectedTab) {
                    DashboardView(showAddTransaction: $showAddTransaction)
                        .tabItem {
                            Label(AppTab.home.label, systemImage: AppTab.home.sfSymbol)
                        }
                        .tag(AppTab.home)
                    
                    AnalyticsView()
                        .tabItem {
                            Label(AppTab.analytics.label, systemImage: AppTab.analytics.sfSymbol)
                        }
                        .tag(AppTab.analytics)
                    
                    BudgetView()
                        .tabItem {
                            Label(AppTab.budget.label, systemImage: AppTab.budget.sfSymbol)
                        }
                        .tag(AppTab.budget)
                    
                    ManageView()
                        .tabItem {
                            Label(AppTab.manage.label, systemImage: AppTab.manage.sfSymbol)
                        }
                        .tag(AppTab.manage)
                }
                .tint(SpendyColors.primaryBlue)
                
                // Standalone Floating Quick Add Button
                Button {
                    HapticsManager.shared.trigger(.medium)
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 56, height: 56)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(LiquidScaleButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 64)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }
}
