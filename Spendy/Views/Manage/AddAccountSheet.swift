//
//  AddAccountSheet.swift
//  Spendy
//
//  Modal Drawer Sheet for Adding & Editing Financial Accounts
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
    
    // Color picker sliders
    @State private var sliderHue: Double = 0.65
    @State private var sliderBrightness: Double = 0.45
    @State private var showSliders: Bool = false
    @State private var showIconPickerSheet: Bool = false
    @State private var showColorPalette: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var showBalanceAdjustSheet: Bool = false
    @State private var tempBalanceInput: String = ""
    
    private let presetColors = [
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Gold / Yellow
        "#34C759", // Green
        "#00C7BE", // Teal / Cyan
        "#007AFF", // Blue
        "#5856D6", // Purple
        "#AF52DE", // Pink Violet
        "#FFFFFF"  // White
    ]
    
    private var isEditing: Bool {
        accountToEdit != nil
    }
    
    private var avatarLetter: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "A" : String(trimmed.prefix(1)).uppercased()
    }
    
    init(accountToEdit: Account? = nil) {
        self.accountToEdit = accountToEdit
        
        if let acc = accountToEdit {
            _label = State(initialValue: acc.label)
            _openingBalanceString = State(initialValue: String(format: acc.openingBalance.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", acc.openingBalance))
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
        _showColorPalette = State(initialValue: false) // Always closed by default
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            // Top ambient gradient glow based on selected color
            let themeColor = Color(hex: selectedColorHex)
            VStack {
                RadialGradient(
                    colors: [
                        themeColor.opacity(0.3),
                        themeColor.opacity(0.08),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 360
                )
                .frame(height: 380)
                .blur(radius: 15)
                .ignoresSafeArea()
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                // Top Header Bar
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Rounded Square Avatar
                        avatarHeroSection
                            .padding(.top, 52)
                        
                        // Form list
                        formContentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom button
                }
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
        .sheet(isPresented: $showIconPickerSheet) {
            CategoryIconPickerSheet(selectedSymbol: $selectedSymbol)
        }
        .sheet(isPresented: $showBalanceAdjustSheet) {
            balanceAdjustmentSheet
        }
        .onChange(of: showBalanceAdjustSheet) { _, isPresented in
            if isPresented {
                tempBalanceInput = openingBalanceString
            }
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
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
    
    private var topHeaderBar: some View {
        HStack {
            // Close Button
            GlassCircleButton(
                icon: "xmark",
                size: 44,
                iconSize: 14,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close"
            ) {
                dismiss()
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
                    tintColor: SpendyColors.expenseRed,
                    foregroundColor: SpendyColors.expenseRed,
                    haptic: .warning,
                    accessibilityLabel: "Delete Account"
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(hex: selectedColorHex))
                            .frame(width: 96, height: 96)
                            .shadow(color: Color(hex: selectedColorHex).opacity(0.35), radius: 10, y: 4)
                        
                        let isLightColor = selectedColorHex.uppercased() == "#FFFFFF" || selectedColorHex.uppercased() == "FFFFFF" || selectedColorHex.uppercased() == "#E4E4E7" || selectedColorHex.uppercased() == "#D4D4D8"
                        
                        if selectedSymbol != SFIcons.bankAccount && selectedSymbol != SFIcons.cashAccount {
                            Image(systemName: selectedSymbol)
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(isLightColor ? .black : .white)
                        } else {
                            Text(avatarLetter)
                                .font(.system(size: 40, weight: .heavy))
                                .foregroundStyle(isLightColor ? .black : .white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // Small Pencil Edit Badge
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showIconPickerSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#1C1C1E"))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                            }
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
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
            // Row 1: Unified Account Name & Color Circle Split Capsule (80/20 Split)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.06), in: Capsule())
            
            // Hue & Brightness Custom sliders
            if showColorPalette {
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
            .background(Color.white.opacity(0.06), in: Capsule())
            
            // Row 3: Currency Lock
            HStack {
                Text("Currency")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    let flag = currencyFlag(for: store.currencyCode)
                    Text("\(flag) \(store.currencyCode)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.06), in: Capsule())
            
            // Row 4: Interactive Balance
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showBalanceAdjustSheet = true
                }) {
                    HStack {
                        Text("Balance")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Spacer()
                        
                        let parsedVal = Double(openingBalanceString.replacingOccurrences(of: ",", with: "")) ?? 0.0
                        Text(parsedVal.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.06), in: Capsule())
                
                Text("Changing this will prompt you to record a correction transaction.")
                    .font(.system(size: 12))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private var colorSlidersCard: some View {
        VStack(spacing: 16) {
            // Presets scroll row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Custom spectrum icon
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showSliders.toggle()
                        }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red]),
                                    center: .center
                                )
                            )
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: showSliders ? 2.5 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Preset items
                    ForEach(presetColors, id: \.self) { hex in
                        Button(action: {
                            selectedColorHex = hex
                            syncSlidersFromHex(hex)
                            HapticsManager.shared.trigger(.light)
                        }) {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Circle()
                                            .stroke(SpendyColors.textPrimary, lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            
            if showSliders {
                VStack(spacing: 14) {
                    HueSpectrumSlider(hue: $sliderHue)
                        .onChange(of: sliderHue) { _, _ in
                            updateHexFromHSB()
                        }
                    
                    DarkBrightnessSlider(hue: sliderHue, brightness: $sliderBrightness)
                        .onChange(of: sliderBrightness) { _, _ in
                            updateHexFromHSB()
                        }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    private var bottomActionButton: some View {
        Button(action: {
            HapticsManager.shared.trigger(.success)
            let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
            let parsedBalance = Double(openingBalanceString.replacingOccurrences(of: ",", with: "")) ?? 0.0
            
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
    
    private var balanceAdjustmentSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Adjust Balance")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .padding(.top, 24)
                    
                    VStack(alignment: .center, spacing: 8) {
                        let val = Double(tempBalanceInput) ?? 0.0
                        Text(val.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    
                    HStack(spacing: 8) {
                        Text(store.currencySymbol)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        TextField("0.00", text: $tempBalanceInput)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .keyboardType(.decimalPad)
                            .tint(SpendyColors.primaryBlue)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        openingBalanceString = tempBalanceInput
                        showBalanceAdjustSheet = false
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(uiColor: .dynamic(light: .white, dark: .black)))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(SpendyColors.primaryBlue, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(SpendyColors.appBackground)
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
    
    private func currencyFlag(for code: String) -> String {
        switch code {
        case "INR": return "🇮🇳"
        case "USD": return "🇺🇸"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "JPY": return "🇯🇵"
        case "CAD": return "🇨🇦"
        case "AUD": return "🇦🇺"
        case "AED": return "🇦🇪"
        case "SGD": return "🇸🇬"
        default: return "🏳️"
        }
    }
}

// MARK: - Hue Spectrum Slider Component
private struct HueSpectrumSlider: View {
    @Binding var hue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let thumbX = CGFloat(hue) * width
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hue: 0.0, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.17, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.33, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.50, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.67, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.83, saturation: 1.0, brightness: 0.95),
                                Color(hue: 1.0, saturation: 1.0, brightness: 0.95)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 38)
                
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .background(Circle().fill(Color(hue: hue, saturation: 1.0, brightness: 0.95)))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: max(16, min(width - 16, thumbX)), y: 19)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = max(0, min(geometry.size.width, value.location.x))
                        let newHue = Double(locationX / geometry.size.width)
                        self.hue = newHue
                    }
            )
        }
        .frame(height: 38)
    }
}

// MARK: - Dark-to-Medium Brightness Slider Component
private struct DarkBrightnessSlider: View {
    let hue: Double
    @Binding var brightness: Double
    
    private let minB: Double = 0.12
    private let maxB: Double = 0.95
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let normB = (brightness - minB) / (maxB - minB)
            let thumbX = CGFloat(max(0, min(1, normB))) * width
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black,
                                Color(hue: hue, saturation: 0.85, brightness: 0.50),
                                Color(hue: hue, saturation: 0.85, brightness: maxB)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 38)
                
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .background(Circle().fill(Color(hue: hue, saturation: 0.85, brightness: min(brightness, maxB))))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: max(16, min(width - 16, thumbX)), y: 19)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = max(0, min(geometry.size.width, value.location.x))
                        let fraction = Double(locationX / geometry.size.width)
                        let newB = minB + fraction * (maxB - minB)
                        self.brightness = min(max(minB, newB), maxB)
                    }
            )
        }
        .frame(height: 38)
    }
}
