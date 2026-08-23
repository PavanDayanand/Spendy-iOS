//
//  FloatingSubscriptionsView.swift
//  Spendy
//
//  Real-time Subscriptions Floating Card with Liquid Glass Design.
//  Matches screenshot design with scrollable active subscriptions, next billing dates, and monthly total pill.
//

import SwiftUI

struct FloatingSubscriptionsView: View {
    @Binding var isPresented: Bool
    @Environment(ExpenseStore.self) private var store
    
    @State private var showAddSubscription: Bool = false
    @State private var dragOffset: CGFloat = 0.0
    
    private var activeSubs: [Subscription] {
        store.subscriptions.filter { !$0.isPaused }
    }
    
    private var totalMonthly: Double {
        activeSubs.reduce(0.0) { acc, sub in
            switch sub.cycle {
            case .monthly: return acc + sub.amount
            case .yearly: return acc + (sub.amount / 12.0)
            case .weekly: return acc + (sub.amount * 4.33)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header Row: Close button on Left, Centered Title
            // Drag gesture is attached here so dragging the header dismisses the card,
            // without intercepting scrolls on the subscription list.
            ZStack {
                HStack {
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: SFIcons.close)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(SpendyColors.textPrimary)
                            .frame(width: 40, height: 40)
                            .nativeLiquidGlassCircle(isInteractive: true)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
                Text("Subscriptions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(SpendyColors.textPrimary)
            }
            .padding(.bottom, 4)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height < 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height < -60 {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                isPresented = false
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                dragOffset = 0.0
                            }
                        }
                    }
            )
            
            // Inner Card Container (Darker background card)
            VStack(spacing: 12) {
                // Header row of the inner container: Active count and total monthly committed
                HStack {
                    Text("Active Subs (\(activeSubs.count))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    // Total monthly cost pill with clock icon
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(SpendyColors.textSecondary)
                        
                        Text("\(store.currencySymbol)\(String(format: "%.2f", totalMonthly))/mo")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(SpendyColors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06), in: Capsule())
                }
                // Subscription Insights Carousel (if any insights available)
                let subInsights = InsightsEngine.getSubscriptionInsights(
                    transactions: store.transactions,
                    subscriptions: store.subscriptions,
                    currencySymbol: store.currencySymbol
                )
                if !subInsights.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(subInsights) { insight in
                                SharedInsightCard(
                                    title: insight.title,
                                    value: insight.value,
                                    subtitle: insight.desc,
                                    icon: insight.icon,
                                    color: insight.color
                                )
                                .frame(width: 170)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Scrollable List of Subscriptions
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        if activeSubs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(SpendyColors.textTertiary)
                                    .padding(.top, 16)
                                Text("No active subscriptions")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(SpendyColors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(activeSubs) { sub in
                                SubscriptionRowView(sub: sub, currencySymbol: store.currencySymbol)
                            }
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
            .padding(16)
            .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
            
            // Bottom "Manage Subscriptions" Button
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                showAddSubscription = true
            }) {
                Text("Manage Subscriptions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(SpendyColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .nativeLiquidGlassCapsule(isInteractive: true)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .nativeLiquidGlass(cornerRadius: 32, isInteractive: true)
        .offset(y: dragOffset)
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionSheet()
        }
    }
}

// Inner row view matching screenshot
struct SubscriptionRowView: View {
    let sub: Subscription
    let currencySymbol: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon: Solid White Circle with a black system icon
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                
                Image(systemName: sub.sfSymbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(SpendyColors.textPrimary)
                
                Text("\(currencySymbol)\(Int(sub.amount)) • \(sub.cycle.label)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SpendyColors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Next bill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SpendyColors.textTertiary)
                
                Text(formatDate(sub.nextBillingDate))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(SpendyColors.textPrimary)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SpendyColors.separator, lineWidth: 0.8)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
