//
//  AddAccountSheet.swift
//  Spendy
//
//  Modal Drawer Sheet for Adding & Editing Financial Accounts
//  Features:
//  - Clean capsule rows (Account Name, Type, Tappable Balance)
//  - Dedicated Bottom Sheet Numeric Keypad Drawer for Balance Entry with live commas & currency icon
//  - Apple HIG compliant 44pt+ touch targets and haptic feedback
//

import SwiftUI

struct AddAccountSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var accountToEdit: Account? = nil
    
    @State private var label: String = ""
    @State private var openingBalanceString: String = ""
    @State private var selectedSymbol: String = SFIcons.bankAccount
    @State private var selectedColorHex: String = "#007AFF"
    @State private var selectedType: AccountType = .bank
    
    @State private var showIconPickerSheet: Bool = false
    @State private var showBalanceKeypadSheet: Bool = false
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
    
    private var formattedBalanceDisplay: String {
        openingBalanceString.formattedNumberStringWithCommas()
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
                            
                            Button {
                                HapticsManager.shared.trigger(.selection)
                                showBalanceKeypadSheet = true
                            } label: {
                                SpendyCreateFormRow {
                                    Text("Balance")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                } trailing: {
                                    HStack(spacing: 6) {
                                        Text("\(store.currencySymbol)\(formattedBalanceDisplay)")
                                            .font(.system(size: 16, weight: .semibold).monospacedDigit())
                                            .foregroundStyle(SpendyColors.textPrimary)
                                        Image(systemName: SFIcons.chevronRight)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(SpendyColors.textTertiary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
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
        .sheet(isPresented: $showBalanceKeypadSheet) {
            AccountBalanceInputSheet(
                amountString: $openingBalanceString,
                currencySymbol: store.currencySymbol
            )
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
    
    private func saveAccount() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBalance = openingBalanceString.replacingOccurrences(of: ",", with: "")
        let parsedBalance = Double(cleanBalance) ?? 0.0
        
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

// MARK: - Dedicated Account Balance Numeric Keypad Sheet Drawer
struct AccountBalanceInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var amountString: String
    var currencySymbol: String
    
    @Namespace private var balanceNamespace
    
    private var displayAmount: String {
        amountString.formattedNumberStringWithCommas()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Shared 44pt Liquid Glass Header Bar (Exact match to Currency & Icon pickers)
                SpendyGlassEffectContainer(spacing: 0) {
                    ZStack {
                        Text("Account Balance")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                            .padding(.horizontal, 60)
                        
                        HStack {
                            GlassCircleButton(
                                icon: "xmark",
                                size: 44,
                                iconSize: 14,
                                foregroundColor: SpendyColors.textPrimary,
                                haptic: .selection,
                                accessibilityLabel: "Close",
                                morphID: "closeBalanceSheetButton",
                                namespace: balanceNamespace
                            ) {
                                dismiss()
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Hero Display: Currency Symbol & Large Dynamic Amount with Commas
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(currencySymbol)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(displayAmount)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .padding(.top, 6)
                .padding(.bottom, 10)
                
                // Tactile 3x4 Keypad with Currency Converter Match Keys
                SpendyKeypad(
                    amountString: $amountString,
                    maxDigits: 10,
                    maxDecimals: 2,
                    buttonBackgroundColor: SpendyColors.separator
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                
                // Done Button (Apple Primary Blue with crisp contrast)
                Button(action: {
                    HapticsManager.shared.trigger(.success)
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SpendyColors.primaryBlue, in: Capsule())
                        .shadow(color: SpendyColors.primaryBlue.opacity(0.25), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.height(470)])
        .presentationDragIndicator(.visible)
    }
}
