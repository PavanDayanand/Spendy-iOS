//
//  AddAccountSheet.swift
//  Spendy
//
//  Modal Drawer Sheet for Adding & Editing Financial Accounts
//  Features:
//  - Dynamic ambient header gradient glow based on account color
//  - Clean capsule rows (Account Name & Color, Type, Tappable Balance)
//  - Dedicated Bottom Sheet Numeric Keypad Drawer for Balance Entry with live commas & currency icon
//  - Apple HIG compliant 44pt+ touch targets and haptic feedback
//

import SwiftUI

struct AddAccountSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var accountToEdit: Account? = nil
    
    @State private var label: String = ""
    @State private var openingBalanceString: String = ""
    @State private var selectedSymbol: String = SFIcons.bankAccount
    @State private var selectedColorHex: String = "#007AFF"
    @State private var selectedType: AccountType = .bank
    
    // Color picker sliders & sheets
    @State private var sliderHue: Double = 0.65
    @State private var sliderBrightness: Double = 0.45
    @State private var showIconPickerSheet: Bool = false
    @State private var showColorPalette: Bool = false
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
                   selectedColorHex != acc.colorHex ||
                   selectedType != acc.type
        } else {
            return !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   openingBalanceDouble != 0.0 ||
                   selectedSymbol != SFIcons.bankAccount ||
                   selectedColorHex != "#007AFF" ||
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
        _showColorPalette = State(initialValue: false)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            // Dynamic Account Top Ambient Gradient Glow based on selected account color
            let themeColor = Color(hex: selectedColorHex)
            SpendyAmbientHeaderBackground(color: themeColor, height: 340, opacity: 0.32)
            
            VStack(spacing: 0) {
                // Top Header Bar (Sticky at top!)
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Circle Avatar
                        avatarHeroSection
                            .padding(.top, 24)
                        
                        // Form Content
                        formContentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom button
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            // Bottom Action Button Container (Full Width)
            VStack(spacing: 0) {
                bottomActionButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 16)
            }
        }
        .onAppear {
            syncSlidersFromHex(selectedColorHex)
        }
        .presentationBackground(SpendyColors.appBackground)
        .presentationDetents([.large])
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
    
    // MARK: - Components
    @Namespace private var headerNamespace
    
    private var topHeaderBar: some View {
        HStack {
            // Close Button
            GlassCircleButton(
                icon: "xmark",
                size: 44,
                iconSize: 14,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close",
                morphID: "closeButton",
                namespace: headerNamespace
            ) {
                if hasUnsavedChanges {
                    showDiscardConfirm = true
                } else {
                    dismiss()
                }
            }
            
            Spacer()
            
            Text(isEditing ? "Edit Account" : "New Account")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            // Delete button (visible in Edit Mode, except for Cash account)
            if isEditing && accountToEdit?.id != "cash" && store.accounts.count > 1 {
                GlassCircleButton(
                    icon: "trash.fill",
                    size: 44,
                    iconSize: 14,
                    tintColor: SpendyColors.expenseRed.opacity(0.18),
                    foregroundColor: SpendyColors.expenseRed,
                    haptic: .warning,
                    accessibilityLabel: "Delete Account",
                    morphID: "deleteButton",
                    namespace: headerNamespace
                ) {
                    showDeleteConfirm = true
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }
    
    private var avatarHeroSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showIconPickerSheet = true
                }) {
                    SpendyIconBadge(
                        sfSymbol: selectedSymbol.isEmpty ? selectedType.defaultSymbol : selectedSymbol,
                        color: Color(hex: selectedColorHex),
                        size: .hero,
                        style: .circle
                    )
                }
                .buttonStyle(.plain)
                
                // Small Pencil Edit Badge
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showIconPickerSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(SpendyColors.cardBackground)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Circle().stroke(SpendyColors.separator, lineWidth: 1)
                            }
                            .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
            }
            
            Text(label.isEmpty ? "Account Name" : label)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }
    
    private var formContentSection: some View {
        VStack(spacing: 16) {
            // Row 1: Unified Account Name & Color Swatch Capsule (80/20 Split)
            HStack {
                if isEditing && accountToEdit?.id == "cash" {
                    Text("Cash")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                } else {
                    TextField("Account Name", text: $label)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .autocorrectionDisabled()
                }
                
                Spacer()
                
                // Hide color picker in Mono Icon Mode
                if !store.isMonoIconMode {
                    // Integrated Color Picker Swatch Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showColorPalette.toggle()
                        }
                        HapticsManager.shared.trigger(.light)
                    }) {
                        Circle()
                            .fill(Color(hex: selectedColorHex))
                            .frame(width: 24, height: 24)
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
            
            // Hue & Brightness Custom sliders
            if showColorPalette && !store.isMonoIconMode {
                colorSlidersCard
            }
            
            // Row 2: Account Type Selector Capsule
            HStack {
                Text("Type")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Menu {
                    ForEach(AccountType.allCases) { type in
                        Button(action: {
                            selectedType = type
                            selectedSymbol = type.defaultSymbol
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            HStack {
                                Text(type.rawValue)
                                Spacer()
                                Image(systemName: type.defaultSymbol)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedType.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textPrimary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
            
            // Row 3: Interactive Balance Field (Opens Numeric Keypad Drawer Sheet)
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                showBalanceKeypadSheet = true
            }) {
                HStack {
                    Text("Balance")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text(store.currencySymbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Text(formattedBalanceDisplay)
                            .font(Font.system(size: 16, weight: .bold, design: .default).monospacedDigit())
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
    
    private var colorSlidersCard: some View {
        VStack(spacing: 16) {
            SpendyColorPresetSwatches(selectedHex: $selectedColorHex, hue: $sliderHue, brightness: $sliderBrightness)
                .onChange(of: selectedColorHex) { _, newHex in
                    syncSlidersFromHex(newHex)
                }
                .onChange(of: sliderHue) { _, _ in
                    updateHexFromHSB()
                }
                .onChange(of: sliderBrightness) { _, _ in
                    updateHexFromHSB()
                }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "#141416"))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    private var bottomActionButton: some View {
        Button(action: {
            HapticsManager.shared.trigger(.success)
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
        }) {
            let isLightColor = selectedColorHex.uppercased() == "#FFFFFF" || selectedColorHex.uppercased() == "FFFFFF" || selectedColorHex.uppercased() == "#E4E4E7" || selectedColorHex.uppercased() == "#D4D4D8"
            
            Text("Save")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isLightColor ? Color.black : Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: selectedColorHex), in: Capsule())
                .shadow(color: Color(hex: selectedColorHex).opacity(0.2), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEditing && label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((!isEditing && label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1.0)
    }
    
    // MARK: - Color Methods
    private func syncSlidersFromHex(_ hex: String) {
        let uiColor = UIColor(Color(hex: hex))
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            sliderHue = Double(h)
            sliderBrightness = Double(b)
        }
    }
    
    private func updateHexFromHSB() {
        let uiColor = UIColor(hue: CGFloat(sliderHue), saturation: 0.85, brightness: CGFloat(sliderBrightness), alpha: 1.0)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            selectedColorHex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
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
