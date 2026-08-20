//
//  AddSubscriptionSheet.swift
//  Spendy
//
//  Modal Sheet for Adding Recurring Subscriptions
//

import SwiftUI

struct AddSubscriptionSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var amountString: String = ""
    @State private var cycle: BillingCycle = .monthly
    @State private var selectedAccountId: String = "bank"
    @State private var selectedSymbol: String = SFIcons.subscriptions
    @State private var selectedColorHex: String = "#5856D6"
    
    private let availableSymbols = [
        SFIcons.streaming, SFIcons.music, SFIcons.cloudStorage,
        SFIcons.artificialIntelligence, SFIcons.gaming, SFIcons.fitness,
        SFIcons.news, SFIcons.subscriptions
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                Form {
                    Section("Subscription") {
                        TextField("Service Name (e.g. Netflix, iCloud)", text: $name)
                        TextField("Amount (\(store.currencySymbol))", text: $amountString)
                            .keyboardType(.decimalPad)
                        
                        Picker("Billing Cycle", selection: $cycle) {
                            ForEach(BillingCycle.allCases) { c in
                                Text(c.label).tag(c)
                            }
                        }
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
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newSub = Subscription(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount: Double(amountString) ?? 0.0,
                            cycle: cycle,
                            accountId: selectedAccountId,
                            sfSymbol: selectedSymbol,
                            colorHex: selectedColorHex
                        )
                        store.addSubscription(newSub)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Double(amountString) ?? 0) <= 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
