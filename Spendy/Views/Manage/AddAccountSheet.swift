//
//  AddAccountSheet.swift
//  Spendy
//
//  Modal Sheet for Adding New Financial Accounts
//

import SwiftUI

struct AddAccountSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var label: String = ""
    @State private var openingBalanceString: String = ""
    @State private var selectedSymbol: String = SFIcons.bankAccount
    @State private var selectedColorHex: String = "#007AFF"
    
    private let availableSymbols = [
        SFIcons.bankAccount, SFIcons.cashAccount, SFIcons.savingsAccount,
        SFIcons.creditCard, SFIcons.cryptoAccount, SFIcons.investmentAccount,
        SFIcons.wallet, SFIcons.lock
    ]
    
    private let availableColors = [
        "#007AFF", "#30D158", "#FF9500", "#AF52DE",
        "#FF453A", "#5856D6", "#32ADE6", "#FFD60A"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                Form {
                    Section("Account Details") {
                        TextField("Account Name (e.g. Chase Bank)", text: $label)
                        TextField("Starting Balance (\(store.currencySymbol))", text: $openingBalanceString)
                            .keyboardType(.decimalPad)
                    }
                    .listRowBackground(SpendyColors.cardBackground)
                    
                    Section("Icon") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(availableSymbols, id: \.self) { sym in
                                Button(action: {
                                    selectedSymbol = sym
                                    HapticsManager.shared.trigger(.selection)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedSymbol == sym ? Color(hex: selectedColorHex) : Color.white.opacity(0.08))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: sym)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(selectedSymbol == sym ? .white : .white.opacity(0.7))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(SpendyColors.cardBackground)
                    
                    Section("Color") {
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { hex in
                                Button(action: {
                                    selectedColorHex = hex
                                    HapticsManager.shared.trigger(.selection)
                                }) {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            if selectedColorHex == hex {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(SpendyColors.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newAcc = Account(
                            id: UUID().uuidString.lowercased(),
                            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                            sfSymbol: selectedSymbol,
                            colorHex: selectedColorHex,
                            openingBalance: Double(openingBalanceString) ?? 0.0,
                            order: store.accounts.count
                        )
                        store.addAccount(newAcc)
                        dismiss()
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
