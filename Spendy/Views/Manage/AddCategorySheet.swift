//
//  AddCategorySheet.swift
//  Spendy
//
//  Modal Sheet for Adding New Custom Categories
//

import SwiftUI

struct AddCategorySheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var defaultType: TransactionType
    @State private var label: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedSymbol: String = SFIcons.food
    @State private var selectedColorHex: String = "#FF9500"
    
    private let availableSymbols = [
        SFIcons.food, SFIcons.transport, SFIcons.groceries, SFIcons.entertainment,
        SFIcons.shopping, SFIcons.subscriptions, SFIcons.housing, SFIcons.utilities,
        SFIcons.health, SFIcons.travel, SFIcons.paycheck, SFIcons.freelance,
        SFIcons.investment, SFIcons.refund, SFIcons.gift, SFIcons.bonus
    ]
    
    private let availableColors = [
        "#007AFF", "#30D158", "#FF9500", "#AF52DE",
        "#FF453A", "#5856D6", "#32ADE6", "#FFD60A"
    ]
    
    init(defaultType: TransactionType) {
        self.defaultType = defaultType
        _type = State(initialValue: defaultType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                Form {
                    Section("Category Details") {
                        TextField("Category Name (e.g. Coffee, Gym)", text: $label)
                        
                        Picker("Type", selection: $type) {
                            Text("Expense").tag(TransactionType.expense)
                            Text("Income").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
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
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newCat = Category(
                            id: UUID().uuidString.lowercased(),
                            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                            sfSymbol: selectedSymbol,
                            colorHex: selectedColorHex,
                            type: type,
                            order: store.categories.count
                        )
                        store.addCategory(newCat)
                        dismiss()
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
