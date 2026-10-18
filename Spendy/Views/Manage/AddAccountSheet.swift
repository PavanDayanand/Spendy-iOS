//
//  AddAccountSheet.swift
//  Spendy
//
//  Modal Drawer Sheet for Adding & Editing Financial Accounts
//  Features:
//  - Clean capsule rows (Account Name, Type, Tappable Balance)
//  - Inline balance entry with the native decimal keyboard
//  - Apple HIG compliant 44pt+ touch targets and haptic feedback
//

import SwiftUI

struct AddAccountSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var accountToEdit: Account? = nil
    
    @State private var label: String = ""
    @State private var openingBalanceString: String = ""
    @State private var selectedSymbol: String = SFIcons.bankAccount
    @State private var selectedColorHex: String = "#007AFF"
    @State private var selectedType: AccountType = .bank
    
    @State private var showIconPickerSheet: Bool = false
    @FocusState private var isBalanceFocused: Bool
    @State private var balanceDraft = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var showDiscardConfirm: Bool = false
    
    private var isEditing: Bool {
        accountToEdit != nil
    }
    
    private var hasUnsavedChanges: Bool {
        let cleanBalance = openingBalanceString.replacingOccurrences(of: ",", with: "")
        let openingBalanceDouble = Double(cleanBalance) ?? 0.0
        
        if let acc = accountToEdit {
            return label != acc.label ||
                   openingBalanceDouble != acc.openingBalance ||
                   selectedSymbol != acc.sfSymbol ||
                   selectedType != acc.type
        } else {
            return !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   openingBalanceDouble != 0.0 ||
                   selectedSymbol != SFIcons.bankAccount ||
                   selectedType != .bank
        }
    }
    
    init(accountToEdit: Account? = nil) {
        self.accountToEdit = accountToEdit
        
        if let acc = accountToEdit {
            _label = State(initialValue: acc.label)
            let formattedInit = acc.openingBalance.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", acc.openingBalance) : String(format: "%.2f", acc.openingBalance)
            _openingBalanceString = State(initialValue: formattedInit)
            _selectedSymbol = State(initialValue: acc.sfSymbol)
            _selectedColorHex = State(initialValue: acc.colorHex)
            _selectedType = State(initialValue: acc.type)
        } else {
            _label = State(initialValue: "")
            _openingBalanceString = State(initialValue: "0")
            _selectedSymbol = State(initialValue: SFIcons.bankAccount)
            _selectedColorHex = State(initialValue: "#007AFF")
            _selectedType = State(initialValue: .bank)
        }
    }
    
    private var canSave: Bool {
        isEditing || !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var canDelete: Bool {
        isEditing && accountToEdit?.id != "cash" && store.accounts.count > 1
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyPinnedHeaderLayout {

                SpendyCreateSheetHeader(
                    title: isEditing ? "Edit Account" : "New Account",
                    showDelete: canDelete,
                    deleteLabel: "Delete Account",
                    onClose: {
                        if hasUnsavedChanges {
                            showDiscardConfirm = true
                        } else {
                            dismiss()
                        }
                    },
                    onDelete: { showDeleteConfirm = true }
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
            } content: {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        avatarHeroSection
                            .padding(.top, 20)
                        
                        SpendyCreateFormCard {
                            SpendyCreateFormRow {
                                Group {
                                    if isEditing && accountToEdit?.id == "cash" {
                                        Text("Cash")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(SpendyColors.textSecondary)
                                    } else {
                                        TextField("Account name", text: $label)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(SpendyColors.textPrimary)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.words)
                                    }
                                }
                            } trailing: {
                                EmptyView()
                            }
                            
                            SpendyCreateFormDivider()
                            
                            Menu {
                                ForEach(AccountType.allCases) { type in
                                    Button {
                                        selectedType = type
                                        selectedSymbol = type.defaultSymbol
                                        HapticsManager.shared.trigger(.selection)
                                    } label: {
                                        Label(type.rawValue, systemImage: type.defaultSymbol)
                                    }
                                }
                            } label: {
                                SpendyCreateFormRow {
                                    Text("Type")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                } trailing: {
                                    HStack(spacing: 6) {
                                        Text(selectedType.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(SpendyColors.textSecondary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(SpendyColors.textTertiary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            
                            SpendyCreateFormDivider()
                            
                            SpendyCreateFormRow {
                                Text("Balance")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(SpendyColors.textPrimary)
                            } trailing: {
                                HStack(spacing: 4) {
                                    Text(store.currencySymbol)
                                    TextField("0", text: $balanceDraft)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($isBalanceFocused)
                                        .accessibilityLabel("Balance")
                                        .accessibilityIdentifier("account-balance-input")
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                                .foregroundStyle(SpendyColors.textPrimary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { isBalanceFocused = true }
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            VStack(spacing: 0) {
                SpendyCreatePrimaryButton(
                    title: isEditing ? "Save" : "Create",
                    isEnabled: canSave
                ) {
                    saveAccount()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .padding(.top, 12)
            }
        }
        // Short forms start compact; larger text can use the full sheet.
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(480), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .sheet(isPresented: $showIconPickerSheet) {
            CategoryIconPickerSheet(selectedSymbol: $selectedSymbol)
        }
        .onAppear { formatBalanceDraft() }
        .onChange(of: isBalanceFocused) { _, focused in
            if focused {
                balanceDraft = openingBalanceString == "0" ? "" : openingBalanceString
                    .replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
            } else {
                formatBalanceDraft()
            }
        }
        .onChange(of: balanceDraft) { oldValue, newValue in
            guard isBalanceFocused else { return }
            guard let normalized = AccountBalanceEntry.normalized(newValue, locale: locale) else {
                balanceDraft = oldValue
                return
            }
            openingBalanceString = normalized.isEmpty ? "0" : normalized
        }
        .alert("Discard Changes?", isPresented: $showDiscardConfirm) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            let fallback = store.accounts.first(where: { $0.id != accountToEdit?.id })
            
            Button("Delete & Move Transactions to \(fallback?.label ?? "Cash")", role: .destructive) {
                if let acc = accountToEdit {
                    store.deleteAccount(id: acc.id, fallbackId: fallback?.id ?? "cash")
                }
                dismiss()
            }
            
            Button("Delete Without Moving", role: .destructive) {
                if let acc = accountToEdit {
                    store.deleteAccount(id: acc.id, fallbackId: nil)
                }
                dismiss()
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What would you like to do with transactions linked to \(accountToEdit?.label ?? "this account")?")
        }
    }
    
    private var avatarHeroSection: some View {
        SpendyEditableHeroIcon(
            sfSymbol: selectedSymbol.isEmpty ? selectedType.defaultSymbol : selectedSymbol,
            color: Color(hex: selectedColorHex),
            style: .rounded(),
            monogramName: label,
            accessibilityLabel: "Edit account icon"
        ) {
            showIconPickerSheet = true
        }
    }
    
    private func formatBalanceDraft() {
        balanceDraft = (Double(openingBalanceString) ?? 0).formatted(
            .number.precision(.fractionLength(0...2)).locale(locale)
        )
    }

    private func saveAccount() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBalance = openingBalanceString.replacingOccurrences(of: ",", with: "")
        let parsedBalance = Double(cleanBalance) ?? 0.0
        guard parsedBalance.isFinite else { return }
        
        if isEditing, let acc = accountToEdit {
            var updated = acc
            if acc.id != "cash" {
                updated.label = trimmedLabel.isEmpty ? acc.label : trimmedLabel
            }
            updated.sfSymbol = selectedSymbol
            updated.colorHex = selectedColorHex
            updated.type = selectedType
            store.updateAccount(updated)
            store.updateAccountBalance(id: acc.id, newBalance: parsedBalance)
        } else {
            let newId = UUID().uuidString.lowercased()
            let finalLabel = trimmedLabel.isEmpty ? "New Account" : trimmedLabel
            let newAcc = Account(
                id: newId,
                label: finalLabel,
                sfSymbol: selectedSymbol,
                colorHex: selectedColorHex,
                openingBalance: parsedBalance,
                order: store.accounts.count,
                type: selectedType
            )
            store.addAccount(newAcc)
        }
        
        dismiss()
    }
    
}
