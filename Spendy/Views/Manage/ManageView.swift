//
//  ManageView.swift
//  Spendy
//
//  Dedicated Subscriptions Management Hub with Liquid Glass Aesthetics and Clean iOS System Typography
//

import SwiftUI

enum SubscriptionFilter: String, CaseIterable, Identifiable {
    case all
    case paid
    case trial
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .all: return "All Bills"
        case .paid: return "Paid"
        case .trial: return "Free Trials"
        }
    }
}

struct ManageView: View {
    @Environment(ExpenseStore.self) private var store
    
    @State private var subFilter: SubscriptionFilter = .all
    @State private var showAddSubscription: Bool = false
    @State private var subscriptionToEdit: Subscription? = nil
    @State private var showCancelledSubs: Bool = false
    
    // MARK: - Computed Properties
    private var activeAndTrialSubs: [Subscription] {
        store.subscriptions.filter { !$0.isCancelled }
    }
    
    private var cancelledSubs: [Subscription] {
        store.subscriptions.filter { $0.isCancelled }
    }
    
    private var activeCount: Int {
        activeAndTrialSubs.filter { !$0.isTrial && !$0.isPaused }.count
    }
    
    private var trialCount: Int {
        activeAndTrialSubs.filter { $0.isTrial }.count
    }
    
    private var totalMonthly: Double {
        activeAndTrialSubs.filter { !$0.isPaused && !$0.isTrial }.reduce(0.0) { sum, sub in
            switch sub.cycle {
            case .monthly: return sum + sub.amount
            case .yearly: return sum + (sub.amount / 12.0)
            case .weekly: return sum + (sub.amount * 4.33)
            }
        }
    }
    
    private var totalAnnual: Double {
        totalMonthly * 12.0
    }
    
    private var upcomingSubscriptions: [Subscription] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        
        return activeAndTrialSubs.filter { sub in
            guard !sub.isPaused else { return false }
            let target = calendar.startOfDay(for: sub.nextBillingDate)
            let days = calendar.dateComponents([.day], from: now, to: target).day ?? 999
            return days >= 0 && days <= 10
        }.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    private var filteredSubscriptions: [Subscription] {
        activeAndTrialSubs.filter { sub in
            switch subFilter {
            case .all: return true
            case .paid: return !sub.isTrial
            case .trial: return sub.isTrial
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // MARK: - Top Header
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Subscriptions")
                                    .font(.system(size: 28, weight: .heavy, design: .default))
                                    .foregroundStyle(.white)
                                Text("Manage recurring bills & free trials")
                                    .font(.system(size: 13, weight: .medium, design: .default))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                HapticsManager.shared.trigger(.light)
                                showAddSubscription = true
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: SFIcons.plus)
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Add")
                                        .font(.system(size: 13, weight: .bold, design: .default))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(SpendyColors.primaryBlue, in: Capsule())
                            }
                        }
                        .padding(.top, 10)
                        
                        // MARK: - Stats Center Card
                        GlassCard(cornerRadius: 22) {
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("MONTHLY BILLS")
                                            .font(.system(size: 11, weight: .bold, design: .default))
                                            .tracking(1.0)
                                            .foregroundStyle(.white.opacity(0.45))
                                        
                                        Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol))
                                            .font(.system(size: 26, weight: .heavy, design: .default))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("ANNUAL PROJECTION")
                                            .font(.system(size: 11, weight: .bold, design: .default))
                                            .tracking(1.0)
                                            .foregroundStyle(.white.opacity(0.45))
                                        
                                        Text(totalAnnual.formattedCurrency(symbol: store.currencySymbol) + "/yr")
                                            .font(.system(size: 18, weight: .bold, design: .default))
                                            .foregroundStyle(SpendyColors.primaryBlue)
                                    }
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                
                                HStack {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(SpendyColors.incomeGreen)
                                            .frame(width: 8, height: 8)
                                        Text("Active: **\(activeCount)**")
                                            .font(.system(size: 12, weight: .medium, design: .default))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(SpendyColors.warningOrange)
                                            .frame(width: 8, height: 8)
                                        Text("Free Trials: **\(trialCount)**")
                                            .font(.system(size: 12, weight: .medium, design: .default))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Due Soon Alert Slider
                        if !upcomingSubscriptions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(SpendyColors.primaryBlue)
                                    Text("Due Soon (Next 10 Days)")
                                        .font(.system(size: 13, weight: .bold, design: .default))
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(upcomingSubscriptions) { sub in
                                            VStack(alignment: .leading, spacing: 10) {
                                                HStack(spacing: 10) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(sub.isDarkBadge ? Color(hex: "#18181B") : Color.white)
                                                            .frame(width: 36, height: 36)
                                                            .overlay {
                                                                Circle()
                                                                    .stroke(sub.isDarkBadge ? Color.white.opacity(0.2) : Color.black.opacity(0.12), lineWidth: 0.8)
                                                            }
                                                        
                                                        Image(systemName: sub.sfSymbol)
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundStyle(sub.isDarkBadge ? .white : .black)
                                                    }
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(sub.name)
                                                            .font(.system(size: 14, weight: .bold, design: .default))
                                                            .foregroundStyle(.white)
                                                            .lineLimit(1)
                                                        
                                                        Text(dueText(for: sub.nextBillingDate, isTrial: sub.isTrial))
                                                            .font(.system(size: 11, weight: .semibold, design: .default))
                                                            .foregroundStyle(sub.isTrial ? SpendyColors.warningOrange : SpendyColors.primaryBlue)
                                                    }
                                                    
                                                    Spacer(minLength: 8)
                                                    
                                                    Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                                                        .font(.system(size: 14, weight: .bold, design: .default))
                                                        .foregroundStyle(.white)
                                                }
                                                
                                                // Quick Action Buttons
                                                if sub.isTrial {
                                                    HStack(spacing: 8) {
                                                        Button(action: {
                                                            store.keepSubscription(id: sub.id)
                                                        }) {
                                                            Text("Keep Sub")
                                                                .font(.system(size: 11, weight: .bold, design: .default))
                                                                .foregroundStyle(SpendyColors.incomeGreen)
                                                                .padding(.horizontal, 10)
                                                                .padding(.vertical, 6)
                                                                .background(SpendyColors.incomeGreen.opacity(0.15), in: Capsule())
                                                        }
                                                        .buttonStyle(.plain)
                                                        
                                                        Button(action: {
                                                            store.cancelSubscription(id: sub.id)
                                                        }) {
                                                            Text("Cancel Trial")
                                                                .font(.system(size: 11, weight: .bold, design: .default))
                                                                .foregroundStyle(SpendyColors.expenseRed)
                                                                .padding(.horizontal, 10)
                                                                .padding(.vertical, 6)
                                                                .background(SpendyColors.expenseRed.opacity(0.15), in: Capsule())
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                } else {
                                                    Button(action: {
                                                        store.markSubscriptionAsPaid(id: sub.id)
                                                    }) {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: SFIcons.checkmark)
                                                                .font(.system(size: 10, weight: .bold))
                                                            Text("Mark as Paid")
                                                                .font(.system(size: 11, weight: .bold, design: .default))
                                                        }
                                                        .foregroundStyle(.white)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(SpendyColors.primaryBlue, in: Capsule())
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .padding(14)
                                            .frame(width: 260)
                                            .background {
                                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                    .fill(SpendyColors.cardBackground)
                                                    .overlay {
                                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                            .stroke(SpendyColors.primaryBlue.opacity(0.3), lineWidth: 1)
                                                    }
                                            }
                                            .onTapGesture {
                                                subscriptionToEdit = sub
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Filters Segmented Picker
                        GlassSegmentedPicker(
                            selection: $subFilter,
                            items: SubscriptionFilter.allCases,
                            titleFor: { $0.label }
                        )
                        
                        // MARK: - Main Subscriptions List
                        VStack(spacing: 10) {
                            if filteredSubscriptions.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: SFIcons.subscriptions)
                                        .font(.system(size: 28))
                                        .foregroundStyle(.white.opacity(0.3))
                                    Text("No subscriptions found")
                                        .font(.system(size: 14, weight: .medium, design: .default))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                .padding(.vertical, 30)
                            } else {
                                ForEach(filteredSubscriptions) { sub in
                                    Button(action: {
                                        HapticsManager.shared.trigger(.light)
                                        subscriptionToEdit = sub
                                    }) {
                                        HStack(spacing: 14) {
                                            // Icon Badge
                                            ZStack {
                                                Circle()
                                                    .fill(sub.isDarkBadge ? Color(hex: "#18181B") : Color.white)
                                                    .frame(width: 44, height: 44)
                                                    .overlay {
                                                        Circle()
                                                            .stroke(sub.isDarkBadge ? Color.white.opacity(0.2) : Color.black.opacity(0.12), lineWidth: 0.8)
                                                    }
                                                
                                                Image(systemName: sub.sfSymbol)
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundStyle(sub.isDarkBadge ? .white : .black)
                                            }
                                            
                                            // Name & Meta Info
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(sub.name)
                                                    .font(.system(.body, design: .default, weight: .semibold))
                                                    .foregroundStyle(sub.isPaused ? .white.opacity(0.4) : .white)
                                                
                                                HStack(spacing: 6) {
                                                    if sub.isTrial {
                                                        Text("Free Trial")
                                                            .font(.system(size: 10, weight: .bold, design: .default))
                                                            .foregroundStyle(SpendyColors.incomeGreen)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(SpendyColors.incomeGreen.opacity(0.15), in: Capsule())
                                                    } else {
                                                        Text(sub.cycle.label)
                                                            .font(.system(size: 10, weight: .bold, design: .default))
                                                            .foregroundStyle(.white.opacity(0.6))
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.white.opacity(0.08), in: Capsule())
                                                    }
                                                    
                                                    Text("• \(dueText(for: sub.nextBillingDate, isTrial: sub.isTrial))")
                                                        .font(.system(size: 11, weight: .medium, design: .default))
                                                        .foregroundStyle(.white.opacity(0.45))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Amount & Status Toggle Button
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                                                    .font(.system(.body, design: .default, weight: .bold))
                                                    .foregroundStyle(sub.isPaused ? .white.opacity(0.4) : .white)
                                                
                                                Button(action: {
                                                    store.toggleSubscriptionPause(id: sub.id)
                                                }) {
                                                    Text(sub.isPaused ? "Paused" : "Active")
                                                        .font(.system(size: 10, weight: .bold, design: .default))
                                                        .foregroundStyle(sub.isPaused ? .white.opacity(0.4) : SpendyColors.incomeGreen)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 3)
                                                        .background {
                                                            Capsule()
                                                                .fill(sub.isPaused ? Color.white.opacity(0.06) : SpendyColors.incomeGreen.opacity(0.12))
                                                        }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(14)
                                        .background {
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(SpendyColors.cardBackground)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                                }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            subscriptionToEdit = sub
                                        } label: {
                                            Label("Edit Subscription", systemImage: SFIcons.edit)
                                        }
                                        
                                        Button {
                                            store.toggleSubscriptionPause(id: sub.id)
                                        } label: {
                                            Label(sub.isPaused ? "Resume Subscription" : "Pause Subscription", systemImage: sub.isPaused ? "play.fill" : "pause.fill")
                                        }
                                        
                                        Button {
                                            store.cancelSubscription(id: sub.id)
                                        } label: {
                                            Label("Cancel Subscription", systemImage: SFIcons.close)
                                        }
                                        
                                        Button(role: .destructive) {
                                            store.deleteSubscription(id: sub.id)
                                        } label: {
                                            Label("Delete", systemImage: SFIcons.delete)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Past & Cancelled Section
                        if !cancelledSubs.isEmpty {
                            VStack(spacing: 10) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        showCancelledSubs.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text("Past & Cancelled (\(cancelledSubs.count))")
                                            .font(.system(size: 13, weight: .semibold, design: .default))
                                            .foregroundStyle(.white.opacity(0.6))
                                        
                                        Spacer()
                                        
                                        Image(systemName: SFIcons.chevronDown)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white.opacity(0.4))
                                            .rotationEffect(.degrees(showCancelledSubs ? 180 : 0))
                                    }
                                    .padding(14)
                                    .background {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.04))
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                if showCancelledSubs {
                                    VStack(spacing: 10) {
                                        ForEach(cancelledSubs) { sub in
                                            HStack(spacing: 14) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.white.opacity(0.08))
                                                        .frame(width: 40, height: 40)
                                                    Image(systemName: sub.sfSymbol)
                                                        .font(.system(size: 18, weight: .bold))
                                                        .foregroundStyle(.white.opacity(0.4))
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(sub.name)
                                                        .font(.system(.body, design: .default, weight: .semibold))
                                                        .foregroundStyle(.white.opacity(0.5))
                                                    Text("Cancelled")
                                                        .font(.system(size: 11, weight: .medium, design: .default))
                                                        .foregroundStyle(SpendyColors.expenseRed.opacity(0.7))
                                                }
                                                
                                                Spacer()
                                                
                                                Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                                                    .font(.system(.body, design: .default, weight: .bold))
                                                    .foregroundStyle(.white.opacity(0.4))
                                            }
                                            .padding(14)
                                            .background {
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(SpendyColors.cardBackground.opacity(0.5))
                                            }
                                            .contextMenu {
                                                Button {
                                                    var updated = sub
                                                    updated.status = "active"
                                                    store.updateSubscription(updated)
                                                } label: {
                                                    Label("Reactivate", systemImage: "arrow.clockwise")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    store.deleteSubscription(id: sub.id)
                                                } label: {
                                                    Label("Delete", systemImage: SFIcons.delete)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddSubscription) {
                AddSubscriptionSheet()
            }
            .sheet(item: $subscriptionToEdit) { sub in
                AddSubscriptionSheet(subscriptionToEdit: sub)
            }
        }
    }
    
    // MARK: - Relative Due Date Helper
    private func dueText(for date: Date, isTrial: Bool) -> String {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: now, to: target).day ?? 0
        
        let prefix = isTrial ? "Trial ends" : "Due"
        if days < 0 {
            return "\(prefix) \(abs(days))d ago"
        } else if days == 0 {
            return "\(prefix) Today"
        } else if days == 1 {
            return "\(prefix) Tomorrow"
        } else if days <= 10 {
            return "\(prefix) in \(days)d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(prefix) \(formatter.string(from: date))"
        }
    }
}
