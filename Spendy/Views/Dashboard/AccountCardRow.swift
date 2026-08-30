//
//  AccountCardRow.swift
//  Spendy
//
//  Horizontal Scrolling Account Cards with Pure SF Symbols
//

import SwiftUI

struct AccountCardRow: View {
    @Environment(ExpenseStore.self) private var store
    @State private var selectedAccountForSheet: Account? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACCOUNTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.accounts) { account in
                        let balance = store.balance(for: account.id)
                        
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                            selectedAccountForSheet = account
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    SpendyIconBadge(
                                        sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                                        color: account.color,
                                        size: .small,
                                        style: .circle
                                    )
                                    
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.label)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(SpendyColors.textSecondary)
                                        .lineLimit(1)
                                    
                                    Text(balance.formattedCurrency(symbol: store.currencySymbol))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                }
                            }
                            .frame(width: 145)
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .sheet(item: $selectedAccountForSheet) { account in
            AccountAnalyticsSheet(account: account)
        }
    }
}
