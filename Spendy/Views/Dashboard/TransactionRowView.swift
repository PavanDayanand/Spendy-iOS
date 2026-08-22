//
//  TransactionRowView.swift
//  Spendy
//
//  Transaction Row Item with Pure SF Symbols and Native Styling
//

import SwiftUI

struct TransactionRowView: View {
    var transaction: Transaction
    @Environment(ExpenseStore.self) private var store
    
    var body: some View {
        let category = store.category(for: transaction.categoryId)
        let account = store.account(for: transaction.accountId)
        let subscription = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == transaction.subscriptionId?.lowercased() })
        let tintColor = subscription?.color ?? category.color
        
        HStack(spacing: 12) {
            // Icon Badge: Subscription glass circle if linked to subscription, else Category icon badge
            if let sub = subscription {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: sub.colorHex).opacity(0.35),
                                    Color(hex: sub.colorHex).opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                        .overlay {
                            Circle()
                                .stroke(Color(hex: sub.colorHex).opacity(0.35), lineWidth: 1)
                        }
                        .shadow(color: Color(hex: sub.colorHex).opacity(0.25), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: sub.sfSymbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: sub.colorHex))
                }
            } else {
                CategoryIconBadge(
                    sfSymbol: category.sfSymbol,
                    tintColor: category.color,
                    size: .medium
                )
            }
            
            // Transaction Info
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(account.label)
                    Text("•")
                    Text(transaction.date.formattedRelative)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Signed Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(.system(.body, weight: .bold))
                    .foregroundStyle(amountColor)
                
                if let toId = transaction.toAccountId, transaction.type == .transfer {
                    let toAccount = store.account(for: toId)
                    Text("→ \(toAccount.label)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SpendyColors.transferBlue)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    subscription != nil ? AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: subscription!.colorHex).opacity(0.12),
                                Color(hex: subscription!.colorHex).opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) : AnyShapeStyle(SpendyColors.cardBackground)
                )
                .background(SpendyColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    let strokeColor = subscription != nil ? Color(hex: subscription!.colorHex).opacity(0.15) : Color.white.opacity(0.06)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(strokeColor, lineWidth: 0.8)
                }
        }
    }
    
    private var amountText: String {
        switch transaction.type {
        case .expense:
            return "-\(transaction.amount.formattedCurrency(symbol: store.currencySymbol))"
        case .income:
            return "+\(transaction.amount.formattedCurrency(symbol: store.currencySymbol))"
        case .transfer:
            return transaction.amount.formattedCurrency(symbol: store.currencySymbol)
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .expense:
            return .white
        case .income:
            return SpendyColors.incomeGreen
        case .transfer:
            return SpendyColors.transferBlue
        }
    }
}
