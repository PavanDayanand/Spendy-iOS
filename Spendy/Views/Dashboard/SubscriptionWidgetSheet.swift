//
//  SubscriptionWidgetSheet.swift
//  Spendy
//
//  Recurring Subscriptions Summary Widget Modal with Liquid Glass Controls
//

import SwiftUI

struct SubscriptionWidgetSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddSubscription: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Top Header Bar
                        HStack {
                            GlassCircleButton(
                                icon: "xmark",
                                size: 44,
                                iconSize: 14,
                                foregroundColor: SpendyColors.textPrimary,
                                haptic: .selection,
                                accessibilityLabel: "Close"
                            ) {
                                dismiss()
                            }
                            
                            Spacer()
                            
                            Text("Subscriptions")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                            
                            Spacer()
                            
                            GlassCircleButton(
                                icon: "plus",
                                size: 44,
                                iconSize: 15,
                                tintColor: SpendyColors.primaryBlue,
                                foregroundColor: SpendyColors.textPrimary,
                                haptic: .medium,
                                accessibilityLabel: "Add Subscription"
                            ) {
                                showAddSubscription = true
                            }
                        }
                        .padding(.top, 10)
                        
                        // Monthly Total Committed Summary Card
                        monthlySummaryCard
                        
                        // Subscriptions Smart Insights Section
                        subscriptionInsightsSection
                        
                        // Subscriptions List or Empty State
                        if store.subscriptions.isEmpty {
                            emptyStateView
                        } else {
                            subscriptionsListSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddSubscription) {
                AddSubscriptionSheet()
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var subscriptionInsightsSection: some View {
        let insights = InsightsEngine.getSubscriptionInsights(
            transactions: store.transactions,
            subscriptions: store.subscriptions,
            currencySymbol: store.currencySymbol
        )
        
        guard !insights.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("Subscription Insights")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(insights) { insight in
                            SharedInsightCard(
                                title: insight.title,
                                value: insight.value,
                                subtitle: insight.desc,
                                icon: insight.icon,
                                color: insight.color
                            )
                            .frame(width: 180)
                        }
                    }
                }
            }
        )
    }
    
    private var monthlySummaryCard: some View {
        let totalMonthly = store.subscriptions.filter { !$0.isPaused }.reduce(0.0) { acc, sub in
            switch sub.cycle {
            case .monthly: return acc + sub.amount
            case .yearly: return acc + (sub.amount / 12.0)
            case .weekly: return acc + (sub.amount * 4.33)
            }
        }
        let activeCount = store.subscriptions.filter { !$0.isPaused }.count
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Total Monthly Committed")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            HStack(alignment: .bottom) {
                Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Spacer()
                
                Text("\(activeCount) active")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpendyColors.incomeGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(SpendyColors.incomeGreen.opacity(0.15), in: Capsule())
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    private var subscriptionsListSection: some View {
        VStack(spacing: 12) {
            ForEach(store.subscriptions) { sub in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        sub.color.opacity(0.35),
                                        sub.color.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay {
                                Circle()
                                    .stroke(sub.color.opacity(0.35), lineWidth: 1)
                            }
                            .shadow(color: sub.color.opacity(0.25), radius: 6, y: 2)
                        
                        Image(systemName: sub.sfSymbol)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(sub.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sub.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(sub.isPaused ? SpendyColors.textTertiary : SpendyColors.textPrimary)
                        
                        Text("\(sub.cycle.label) • \(sub.amount.formattedCurrency(symbol: store.currencySymbol))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { !sub.isPaused },
                        set: { _ in store.toggleSubscriptionPause(id: sub.id) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.liquidGlass(tint: SpendyColors.incomeGreen))
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.top, 20)
            
            Text("No active subscriptions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Text("Add your recurring bills and streaming services to track them here.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: {
                HapticsManager.shared.trigger(.medium)
                showAddSubscription = true
            }) {
                Text("+ Add Subscription")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(uiColor: .dynamic(light: .white, dark: .black)))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(SpendyColors.primaryBlue, in: Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}
