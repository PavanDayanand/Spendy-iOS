//
//  AddTransactionView.swift
//  Spendy
//
//  Full-Featured Transaction Screen with Custom Tactile Keypad, Liquid Glass Controls, and Transfer Route
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var transactionToEdit: Transaction? = nil
    
    // State
    @State private var type: TransactionType = .expense
    @State private var amountString: String = "0"
    @State private var selectedCategoryId: String = "food"
    @State private var fromAccountId: String = "bank"
    @State private var toAccountId: String = "cash"
    @State private var note: String = ""
    @State private var date: Date = Date()
    
    @State private var showCategoryPicker: Bool = false
    @State private var showDatePicker: Bool = false
    
    private var isEditing: Bool {
        transactionToEdit != nil
    }
    
    private var numericAmount: Double {
        Double(amountString) ?? 0.0
    }
    
    private var selectedCategory: Category? {
        store.categories.first(where: { $0.id == selectedCategoryId })
    }
    
    private var fromAccount: Account? {
        store.accounts.first(where: { $0.id == fromAccountId }) ?? store.accounts.first
    }
    
    private var toAccount: Account? {
        store.accounts.first(where: { $0.id == toAccountId }) ?? store.accounts.last
    }
    
    private var availableCategories: [Category] {
        store.categories.filter { $0.type == type }
    }
    
    init(transactionToEdit: Transaction? = nil, defaultType: TransactionType = .expense) {
        self.transactionToEdit = transactionToEdit
        if let t = transactionToEdit {
            _type = State(initialValue: t.type)
            _amountString = State(initialValue: String(format: t.amount.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", t.amount))
            _selectedCategoryId = State(initialValue: t.categoryId)
            _fromAccountId = State(initialValue: t.accountId)
            _toAccountId = State(initialValue: t.toAccountId ?? "cash")
            _note = State(initialValue: t.notes ?? "")
            _date = State(initialValue: t.date)
        } else {
            _type = State(initialValue: defaultType)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header: Close ✕ & Type Toggle
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Large Formatted Amount Display
                        amountDisplaySection
                            .padding(.top, 10)
                        
                        // Category & Account Selector Chips Row
                        selectorsRow
                        
                        // Note Input Field
                        noteInputRow
                        
                        // Custom Tactile Keypad
                        tactileKeypadGrid
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }
            
            // Bottom Action Save Button
            bottomSaveButton
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
        }
        .sheet(isPresented: $showCategoryPicker) {
            categorySelectionModal
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerModal
        }
        .onAppear {
            if transactionToEdit == nil {
                if let firstCat = availableCategories.first {
                    selectedCategoryId = firstCat.id
                }
                if let firstAcc = store.accounts.first {
                    fromAccountId = firstAcc.id
                }
                if store.accounts.count > 1 {
                    toAccountId = store.accounts[1].id
                }
            }
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            // Circular Glass Close Button ✕
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Expense / Income / Transfer Glass Toggle
            typeSegmentedPicker
            
            Spacer()
            
            // Date Picker Icon Chip
            Button(action: {
                HapticsManager.shared.trigger(.light)
                showDatePicker = true
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Type Segmented Picker (Expense | Income | Transfer)
    private var typeSegmentedPicker: some View {
        HStack(spacing: 3) {
            ForEach(TransactionType.allCases) { t in
                Button(action: {
                    withAnimation(.spring(response: 0.25)) {
                        type = t
                        if let first = store.categories.filter({ $0.type == t }).first {
                            selectedCategoryId = first.id
                        }
                    }
                    HapticsManager.shared.trigger(.selection)
                }) {
                    Text(t.title)
                        .font(.system(size: 13, weight: type == t ? .bold : .medium, design: .rounded))
                        .foregroundStyle(type == t ? .white : .white.opacity(0.45))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background {
                            if type == t {
                                Capsule()
                                    .fill(Color.white.opacity(0.18))
                                    .shadow(color: Color.black.opacity(0.2), radius: 3)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay {
            Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        }
    }
    
    // MARK: - Amount Display Section
    private var amountDisplaySection: some View {
        VStack(spacing: 4) {
            Text(type == .expense ? "EXPENSE AMOUNT" : (type == .income ? "INCOME AMOUNT" : "TRANSFER AMOUNT"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.40))
            
            HStack(spacing: 2) {
                Text(store.currencySymbol)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(typeColor)
                
                Text(amountString)
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Selectors Row (Category & Account Chips)
    private var selectorsRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Category Chip (for Expense & Income)
                if type != .transfer {
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        showCategoryPicker = true
                    }) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory?.color ?? SpendyColors.primaryBlue)
                                    .frame(width: 26, height: 26)
                                Image(systemName: selectedCategory?.sfSymbol ?? "tag.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            Text(selectedCategory?.label ?? "Category")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .nativeLiquidGlassCapsule(isInteractive: true)
                    }
                    .buttonStyle(.plain)
                }
                
                // Account Selector (From Account)
                Menu {
                    ForEach(store.accounts) { acc in
                        Button(action: {
                            fromAccountId = acc.id
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            Label(acc.label, systemImage: acc.sfSymbol)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: fromAccount?.sfSymbol ?? "creditcard.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(fromAccount?.color ?? SpendyColors.primaryBlue)
                        
                        Text(fromAccount?.label ?? "Account")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .nativeLiquidGlassCapsule(isInteractive: true)
                }
                .buttonStyle(.plain)
                
                // If Transfer, show "To Account"
                if type == .transfer {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.40))
                    
                    Menu {
                        ForEach(store.accounts.filter { $0.id != fromAccountId }) { acc in
                            Button(action: {
                                toAccountId = acc.id
                                HapticsManager.shared.trigger(.selection)
                            }) {
                                Label(acc.label, systemImage: acc.sfSymbol)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: toAccount?.sfSymbol ?? "creditcard.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(toAccount?.color ?? SpendyColors.incomeGreen)
                            
                            Text(toAccount?.label ?? "To Account")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .nativeLiquidGlassCapsule(isInteractive: true)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Note Input Row
    private var noteInputRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.40))
            
            TextField("Add a note (optional)", text: $note)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Custom Tactile Keypad Grid (1-9, ., 0, ⌫)
    private var tactileKeypadGrid: some View {
        let keys = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            [".", "0", "delete.left.fill"]
        ]
        
        return VStack(spacing: 10) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(key: key)
                    }
                }
            }
        }
    }
    
    private func keypadButton(key: String) -> some View {
        Button(action: {
            handleKeypadPress(key)
        }) {
            ZStack {
                if key == "delete.left.fill" {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary.opacity(0.85))
                } else {
                    Text(key)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func handleKeypadPress(_ key: String) {
        HapticsManager.shared.trigger(.light)
        
        if key == "delete.left.fill" {
            if amountString.count > 1 {
                amountString.removeLast()
            } else {
                amountString = "0"
            }
        } else if key == "." {
            if !amountString.contains(".") {
                amountString += "."
            }
        } else {
            // Numbers 0-9
            if amountString == "0" {
                amountString = key
            } else {
                // Limit to 2 decimal places
                if let dotIndex = amountString.firstIndex(of: ".") {
                    let decimalDigits = amountString[dotIndex...].count - 1
                    if decimalDigits >= 2 { return }
                }
                // Limit max length
                if amountString.count < 10 {
                    amountString += key
                }
            }
        }
    }
    
    // MARK: - Bottom Action Save Button
    private var bottomSaveButton: some View {
        Button(action: {
            saveTransaction()
        }) {
            Text(buttonTitle)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(SpendyColors.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SpendyColors.textPrimary, in: Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(numericAmount <= 0)
        .opacity(numericAmount <= 0 ? 0.45 : 1.0)
    }
    
    private var buttonTitle: String {
        if isEditing { return "Save Changes" }
        switch type {
        case .expense: return "Add Expense"
        case .income: return "Add Income"
        case .transfer: return "Transfer Funds"
        }
    }
    
    private var typeColor: Color {
        switch type {
        case .expense: return SpendyColors.expenseRed
        case .income: return SpendyColors.incomeGreen
        case .transfer: return SpendyColors.transferBlue
        }
    }
    
    private func saveTransaction() {
        guard numericAmount > 0 else { return }
        HapticsManager.shared.trigger(.success)
        
        let txTitle = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (selectedCategory?.label ?? type.title)
            : note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existing = transactionToEdit {
            var updated = existing
            updated.amount = numericAmount
            updated.type = type
            updated.categoryId = selectedCategoryId
            updated.accountId = fromAccountId
            updated.toAccountId = type == .transfer ? toAccountId : nil
            updated.title = txTitle
            updated.notes = note.isEmpty ? nil : note
            updated.date = date
            store.updateTransaction(updated)
        } else {
            let newTx = Transaction(
                title: txTitle,
                amount: numericAmount,
                type: type,
                categoryId: selectedCategoryId,
                accountId: fromAccountId,
                toAccountId: type == .transfer ? toAccountId : nil,
                date: date,
                notes: note.isEmpty ? nil : note
            )
            store.addTransaction(newTx)
        }
        dismiss()
    }
    
    // MARK: - Category Selection Modal
    private var categorySelectionModal: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 14) {
                        ForEach(availableCategories) { cat in
                            Button(action: {
                                selectedCategoryId = cat.id
                                HapticsManager.shared.trigger(.selection)
                                showCategoryPicker = false
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(cat.color)
                                            .frame(width: 48, height: 48)
                                            .shadow(color: cat.color.opacity(0.35), radius: 6, y: 2)
                                        
                                        Image(systemName: cat.sfSymbol)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Text(cat.label)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedCategoryId == cat.id ? Color.white.opacity(0.12) : SpendyColors.cardBackground)
                                        .overlay {
                                            if selectedCategoryId == cat.id {
                                                RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                            }
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showCategoryPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Date Picker Modal
    private var datePickerModal: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack {
                    DatePicker("Transaction Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(SpendyColors.primaryBlue)
                        .padding(20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Transaction Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDatePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
