import SwiftUI

// MARK: - Account Selection Drawer (Pure Native Liquid Glass Styling)
struct ReceiptAccountPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAccountId: String
    var title: String
    var accounts: [Account]
    var balances: [String: Double]?
    var currencySymbol: String
    var showsAllAccounts = false
    
    var body: some View {
        ZStack {
            SpendyPinnedHeaderLayout(usesSoftScrollEdge: true) {

                // Clean Custom Header
                HStack {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 14,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .selection
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)
            } content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(spacing: 0) {
                            if showsAllAccounts {
                                Button {
                                    selectedAccountId = "all"
                                    HapticsManager.shared.trigger(.selection)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 14) {
                                        SpendyIconBadge(sfSymbol: "wallet.pass.fill", color: SpendyColors.textPrimary,
                                            size: .medium, monogramName: "All accounts")
                                        Text("All accounts")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(SpendyColors.textPrimary)
                                        Spacer()
                                        if selectedAccountId == "all" {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(SpendyColors.textPrimary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("account-filter-all")
                                Divider()
                                    .background(SpendyColors.separator)
                                    .padding(.leading, 68)
                            }
                            ForEach(accounts) { acc in
                                let isSelected = selectedAccountId == acc.id
                                let liveBalance = balances?[acc.id]
                                Button(action: {
                                    selectedAccountId = acc.id
                                    HapticsManager.shared.trigger(.selection)
                                    dismiss()
                                }) {
                                    HStack(spacing: 14) {
                                        // Vibrant Account Badge
                                        SpendyIconBadge(
                                            sfSymbol: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol,
                                            color: acc.color,
                                            size: .medium,
                                            monogramName: acc.label
                                        )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(acc.label)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(SpendyColors.textPrimary)
                                            
                                            if let liveBalance {
                                                Text(liveBalance.formattedCurrency(symbol: currencySymbol, decimals: 0))
                                                    .font(.system(size: 13, weight: .medium))
                                                    .monospacedDigit()
                                                    .foregroundStyle(SpendyColors.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(SpendyColors.textPrimary)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if acc.id != accounts.last?.id {
                                    Divider()
                                        .background(SpendyColors.separator)
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(SpendyColors.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .presentationDetents([.fraction(0.55), .medium])
        .presentationDragIndicator(.visible)
    }
}

