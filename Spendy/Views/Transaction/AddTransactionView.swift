//
//  AddTransactionView.swift
//  Spendy
//
//  Native iOS Quick Add Transaction Modal Sheet with Pure SF Symbols
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var type: TransactionType = .expense
    @State private var amountString: String = "0"
    @State private var title: String = ""
    @State private var selectedCategoryId: String = "food"
    @State private var selectedAccountId: String = "bank"
    @State private var selectedToAccountId: String = "savings"
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    
    var amountValue: Double {
        Double(amountString) ?? 0.0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Type Selector (Segmented)
                        Picker("Transaction Type", selection: $type) {
                            ForEach(TransactionType.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: type) { _, newType in
                            if let firstCat = filteredCategories.first {
                                selectedCategoryId = firstCat.id
                            }
                            HapticsManager.shared.trigger(.selection)
                        }
                        
                        // Large Amount Display Card
                        amountDisplayCard
                        
                        // Quick Amount Increment Chips
                        quickAmountChips
                        
                        // Transaction Details Form
                        detailsForm
                        
                        // Save Button
                        saveButton
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticsManager.shared.trigger(.light)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.90), .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let firstCat = filteredCategories.first {
                selectedCategoryId = firstCat.id
            }
        }
    }
    
    // MARK: - Amount Display Card
    private var amountDisplayCard: some View {
        VStack(spacing: 4) {
            Text("AMOUNT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.45))
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(store.currencySymbol)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(type.color)
                
                TextField("0", text: $amountString)
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 80)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Quick Amount Increment Chips
    private var quickAmountChips: some View {
        HStack(spacing: 10) {
            ForEach([10, 50, 100, 500], id: \.self) { val in
                Button(action: {
                    let current = Double(amountString) ?? 0
                    amountString = String(format: "%.0f", current + Double(val))
                    HapticsManager.shared.trigger(.light)
                }) {
                    Text("+\(store.currencySymbol)\(val)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
                                }
                        }
                }
            }
        }
    }
    
    // MARK: - Details Form
    private var detailsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title Input
            VStack(alignment: .leading, spacing: 6) {
                Text("TITLE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                TextField("e.g. Dinner, Coffee, Salary", text: $title)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(SpendyColors.cardBackgroundSecondary)
                    }
            }
            
            // Category Picker
            if type != .transfer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white.opacity(0.45))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(filteredCategories) { cat in
                                let isSelected = selectedCategoryId == cat.id
                                Button(action: {
                                    selectedCategoryId = cat.id
                                    HapticsManager.shared.trigger(.selection)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: SFIcons.symbol(named: cat.sfSymbol))
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(cat.label)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background {
                                        if isSelected {
                                            Capsule().fill(cat.color)
                                        } else {
                                            Capsule().fill(SpendyColors.cardBackgroundSecondary)
                                        }
                                    }
                                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
            }
            
            // Account Picker
            VStack(alignment: .leading, spacing: 8) {
                Text(type == .transfer ? "FROM ACCOUNT" : "ACCOUNT")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.accounts) { acc in
                            let isSelected = selectedAccountId == acc.id
                            Button(action: {
                                selectedAccountId = acc.id
                                HapticsManager.shared.trigger(.selection)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: SFIcons.symbol(named: acc.sfSymbol))
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(acc.label)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background {
                                    if isSelected {
                                        Capsule().fill(acc.color)
                                    } else {
                                        Capsule().fill(SpendyColors.cardBackgroundSecondary)
                                    }
                                }
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                            }
                        }
                    }
                }
            }
            
            // To Account for Transfer
            if type == .transfer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TO ACCOUNT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(.white.opacity(0.45))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.accounts.filter { $0.id != selectedAccountId }) { acc in
                                let isSelected = selectedToAccountId == acc.id
                                Button(action: {
                                    selectedToAccountId = acc.id
                                    HapticsManager.shared.trigger(.selection)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: SFIcons.symbol(named: acc.sfSymbol))
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(acc.label)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background {
                                        if isSelected {
                                            Capsule().fill(SpendyColors.transferBlue)
                                        } else {
                                            Capsule().fill(SpendyColors.cardBackgroundSecondary)
                                        }
                                    }
                                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                                }
                            }
                        }
                    }
                }
            }
            
            // Date Row
            HStack {
                Text("DATE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                Spacer()
                
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .labelsHidden()
                    .colorScheme(.dark)
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SpendyColors.cardBackgroundSecondary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveTransaction) {
            HStack(spacing: 8) {
                Image(systemName: SFIcons.checkmarkCircle)
                    .font(.system(size: 18, weight: .bold))
                Text("Add \(type.title)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(type.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.white)
        }
        .disabled(amountValue <= 0)
        .opacity(amountValue <= 0 ? 0.4 : 1.0)
    }
    
    private var filteredCategories: [Category] {
        store.categories.filter { $0.type == (type == .income ? .income : .expense) && !$0.isHidden }
    }
    
    private func saveTransaction() {
        guard amountValue > 0 else { return }
        
        let resolvedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (type == .transfer ? "Transfer" : store.category(for: selectedCategoryId).label)
            : title
        
        let newTransaction = Transaction(
            title: resolvedTitle,
            amount: amountValue,
            type: type,
            categoryId: type == .transfer ? "savings" : selectedCategoryId,
            accountId: selectedAccountId,
            toAccountId: type == .transfer ? selectedToAccountId : nil,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes
        )
        
        store.addTransaction(newTransaction)
        dismiss()
    }
}
