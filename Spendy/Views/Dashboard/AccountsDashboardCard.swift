//
//  AccountsDashboardCard.swift
//  Spendy
//
//  Refined Master Accounts Card for the Spendy Dashboard matching Apple HIG.
//  Features:
//  - Elevated container surface (24pt corner radius) with hairline stroke border.
//  - Balanced header with circular icon container, bold title, balance summary, and circular arrow.up.right button.
//  - Clean, un-nested row list with vibrant SpendyIconBadge icons, monospaced digits, and hairline dividers.
//  - Smooth spring press micro-interactions, haptics, and context menu actions.
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
    
    private var subtitleText: String {
        let countText = "\(store.accounts.count) \(store.accounts.count == 1 ? "account" : "accounts")"
        if hideBalance {
            return "\(countText)  •  ••••••"
        }
        return "\(countText)  •  \(totalBalance.formattedCurrency(symbol: store.currencySymbol))"
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - 1. Card Header
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)
            
            // MARK: - 2. Wide Separator Line
            Rectangle()
                .fill(SpendyColors.separator)
                .frame(height: 0.8)
            
            // MARK: - 3. Account Rows List (Clean, Unified & Grounded)
            if store.accounts.isEmpty {
                emptyAccountsRow
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.accounts.enumerated()), id: \.element.id) { index, account in
                        accountRow(account: account)
                        
                        if index < store.accounts.count - 1 {
                            // Inset hairline divider between rows
                            Rectangle()
                                .fill(SpendyColors.separator.opacity(0.5))
                                .frame(height: 0.5)
                                .padding(.leading, 64)
                                .padding(.trailing, 16)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            // Balanced Circular Icon Badge
            ZStack {
                Circle()
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            // Header Titles
            VStack(alignment: .leading, spacing: 2) {
                Text("Accounts")
                    .font(.system(size: 17, weight: .bold, design: .default))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                Text(subtitleText)
                    .font(.system(size: 12.5, weight: .medium, design: .default))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            // Top-Right Circular Action Button (arrow.up.right)
            Button(action: {
                HapticsManager.shared.trigger(.light)
                onOpenAccounts()
            }) {
                ZStack {
                    Circle()
                        .fill(SpendyColors.elevatedControlFill)
                        .frame(width: 34, height: 34)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.elevatedControlForeground)
                }
            }
            .buttonStyle(HeaderActionPressStyle())
            .accessibilityLabel("Open Accounts Management")
        }
    }
    
    // MARK: - Single Account Row
    private func accountRow(account: Account) -> some View {
        let balance = store.balance(for: account.id)
        let txCount = store.transactions.filter { $0.accountId == account.id }.count
        let typeName = account.type.rawValue.capitalized
        let subtitle = "\(typeName)  •  \(txCount) \(txCount == 1 ? "txn" : "txns")"
        let formattedBalance = hideBalance ? "••••" : balance.formattedCurrency(symbol: store.currencySymbol)
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            onSelectAccount(account)
        }) {
            HStack(spacing: 12) {
                // Vibrant Spendy Icon Badge
                SpendyIconBadge(
                    sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                    color: account.color,
                    size: .small,
                    style: .rounded(),
                    showCutoutBorder: false
                )
                
                // Account Label & Type
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.label)
                        .font(.system(size: 15.5, weight: .semibold, design: .default))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 12.5, weight: .medium, design: .default))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                // Monospaced Amount
                Text(formattedBalance)
                    .spendyNumberFont(size: 15.5, weight: .bold, tracking: -0.3)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                
                // Disclosure Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(AccountRowPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.label), \(typeName), balance \(formattedBalance)")
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
    
    // MARK: - Empty State Row
    private var emptyAccountsRow: some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            onOpenAccounts()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SpendyColors.cardBackgroundSecondary)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add your first account")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("Checking, Savings, Credit Card or Cash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Button Press Styles
private struct AccountRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? SpendyColors.cardBackgroundSecondary.opacity(0.7) : Color.clear
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private struct HeaderActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview("Accounts Dashboard Card") {
    ZStack {
        SpendyColors.appBackground
            .ignoresSafeArea()
        
        AccountsDashboardCard(
            hideBalance: false,
            onOpenAccounts: {},
            onSelectAccount: { _ in }
        )
        .padding(20)
    }
    .environment(ExpenseStore())
}
