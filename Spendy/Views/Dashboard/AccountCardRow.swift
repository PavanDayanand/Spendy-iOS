//
//  AccountCardRow.swift
//  Spendy
//
//  Horizontal Scrolling Account Cards with Pure SF Symbols
//

import SwiftUI

struct AccountCardRow: View {
    @Environment(ExpenseStore.self) private var store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACCOUNTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.accounts) { account in
                        let balance = store.balance(for: account.id)
                        
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    CategoryIconBadge(
                                        sfSymbol: account.sfSymbol,
                                        tintColor: account.color,
                                        size: .small
                                    )
                                    
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.label)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.65))
                                        .lineLimit(1)
                                    
                                    Text(balance.formattedCurrency(symbol: store.currencySymbol))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(width: 145)
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
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}
