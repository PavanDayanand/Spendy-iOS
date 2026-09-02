//
//  AccountsDashboardCard.swift
//  Spendy
//
//  Minimal, Compact Master Accounts Card for the Spendy Dashboard.
//  Clean Apple Wallet / HIG aesthetic with zero clutter, refined typography,
//  wide horizontal divider line, and seamless stroke sparkline.
//

import SwiftUI

struct AccountsDashboardCard: View {
    @Environment(ExpenseStore.self) private var store
    
    var hideBalance: Bool = false
    var onOpenAccounts: () -> Void
    var onSelectAccount: (Account) -> Void
    
    // MARK: - Computed Properties
    
    private var totalBalance: Double {
        store.totalBalance
    }
    
    private var isPositiveTrend: Bool {
        store.netWorthChangePercentage >= 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: - 1. Card Section Header (Accounts • 3 >)
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                onOpenAccounts()
            }) {
                HStack(alignment: .center) {
                    Text("Accounts")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(store.accounts.count)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Image(systemName: SFIcons.chevronRight)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background {
                        Capsule(style: .continuous)
                            .fill(SpendyColors.cardBackgroundSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Accounts section, \(store.accounts.count) accounts. Double tap to manage.")
            
            // MARK: - 2. Grouped Container Surface (Compact & Grounded)
            VStack(spacing: 0) {
                // Top Hero Balance & Trend Area
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    onOpenAccounts()
                }) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Total Balance")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                            
                            Text(hideBalance ? "••••••" : totalBalance.formattedCurrency(symbol: store.currencySymbol))
                                .spendyNumberFont(size: 24, weight: .heavy, tracking: -0.6)
                                .foregroundStyle(SpendyColors.textPrimary)
                                .contentTransition(.numericText())
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Clean Stroke-Only Sparkline Curve (No boxy background)
                        TrendSparkline(isPositive: isPositiveTrend, height: 30)
                            .frame(width: 80, height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // MARK: - 3. Wide Separator Line
                Rectangle()
                    .fill(SpendyColors.separator)
                    .frame(height: 0.8)
                
                // MARK: - 4. Account Rows List (Clean & Minimal)
                VStack(spacing: 0) {
                    ForEach(Array(store.accounts.enumerated()), id: \.element.id) { index, account in
                        accountRow(account: account)
                        
                        if index < store.accounts.count - 1 {
                            // Hairline Inset Divider between rows
                            Rectangle()
                                .fill(SpendyColors.separator.opacity(0.5))
                                .frame(height: 0.5)
                                .padding(.leading, 56)
                                .padding(.trailing, 16)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - Minimal Account Row Component (No clutter, pure Apple HIG)
    private func accountRow(account: Account) -> some View {
        let balance = store.balance(for: account.id)
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            onSelectAccount(account)
        }) {
            HStack(spacing: 12) {
                // Circular icon badge
                SpendyIconBadge(
                    sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                    color: account.color,
                    size: .small,
                    style: .circle,
                    showCutoutBorder: false
                )
                
                // Pure Account Name
                Text(account.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                // Monospaced Amount
                Text(hideBalance ? "••••" : balance.formattedCurrency(symbol: store.currencySymbol))
                    .spendyNumberFont(size: 15, weight: .bold, tracking: -0.3)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .contentTransition(.numericText())
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.label), balance \(hideBalance ? "hidden" : balance.formattedCurrency(symbol: store.currencySymbol))")
        .contextMenu {
            Button {
                HapticsManager.shared.trigger(.light)
                onSelectAccount(account)
            } label: {
                Label("View Analytics", systemImage: "chart.bar.xaxis")
            }
            
            Button {
                HapticsManager.shared.trigger(.light)
                UIPasteboard.general.string = "\(balance)"
            } label: {
                Label("Copy Balance", systemImage: "doc.on.clipboard")
            }
        }
    }
}
