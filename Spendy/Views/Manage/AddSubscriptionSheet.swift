//
//  AddSubscriptionSheet.swift
//  Spendy
//
//  Modal Drawer Sheet for Adding & Editing Subscriptions with Aligned Styling
//

import SwiftUI

struct AddSubscriptionSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var subscriptionToEdit: Subscription? = nil

    @State private var name: String = ""
    @State private var amountString: String = ""
    @State private var cycle: BillingCycle = .monthly
    @State private var nextBillingDate: Date = Date()
    @State private var isTrial: Bool = false
    @State private var selectedAccountId: String = "bank"
    @State private var selectedSymbol: String = SFIcons.subscriptions
    @State private var selectedColorHex: String = "#5856D6"
    @State private var isDarkBadge: Bool = false
    
    // UI states
    @State private var showIconPickerSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showColorPalette: Bool = false
    
    // Sliders state
    @State private var sliderHue: Double = 0.65
    @State private var sliderBrightness: Double = 0.45
    @State private var showSliders: Bool = false

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

    var isEditing: Bool { subscriptionToEdit != nil }

    private var selectedAccount: Account? {
        store.accounts.first { $0.id == selectedAccountId }
    }

    init(subscriptionToEdit: Subscription? = nil) {
        self.subscriptionToEdit = subscriptionToEdit

        if let sub = subscriptionToEdit {
            _name = State(initialValue: sub.name)
            _amountString = State(initialValue: sub.amount > 0 ? String(format: "%.2f", sub.amount) : "")
            _cycle = State(initialValue: sub.cycle)
            _nextBillingDate = State(initialValue: sub.nextBillingDate)
            _isTrial = State(initialValue: sub.isTrial)
            _selectedAccountId = State(initialValue: sub.accountId)
            _selectedSymbol = State(initialValue: sub.sfSymbol)
            _selectedColorHex = State(initialValue: sub.colorHex)
            _isDarkBadge = State(initialValue: true)
        } else {
            _name = State(initialValue: "")
            _amountString = State(initialValue: "")
            _cycle = State(initialValue: .monthly)
            _nextBillingDate = State(initialValue: Date())
            _isTrial = State(initialValue: false)
            _selectedAccountId = State(initialValue: "bank")
            _selectedSymbol = State(initialValue: SFIcons.subscriptions)
            _selectedColorHex = State(initialValue: "#5856D6")
            _isDarkBadge = State(initialValue: true)
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
                        // Hero Circle Avatar
                        avatarHeroSection
                            .padding(.top, 52)

                        // Form content
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
                .presentationBackground(SpendyColors.appBackground)
        }
        .alert("Delete Subscription?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let sub = subscriptionToEdit { store.deleteSubscription(id: sub.id) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this subscription? This action cannot be undone.")
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

            Text(isEditing ? "Edit Subscription" : "New Subscription")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)

            Spacer()

            // Delete button (visible in Edit Mode)
            if isEditing {
                GlassCircleButton(
                    icon: "trash.fill",
                    size: 44,
                    iconSize: 14,
                    tintColor: SpendyColors.expenseRed,
                    foregroundColor: SpendyColors.expenseRed,
                    haptic: .warning,
                    accessibilityLabel: "Delete Subscription"
                ) {
                    showDeleteConfirmation = true
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }

    private var avatarHeroSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showIconPickerSheet = true
                }) {
                    ZStack {
                        let circleColor = Color(hex: selectedColorHex)
                        Circle()
                            .fill(circleColor)
                            .frame(width: 80, height: 80)
                            .shadow(color: circleColor.opacity(0.40), radius: 12, y: 4)
                        
                        let isLightColor = selectedColorHex.uppercased() == "#FFFFFF" || selectedColorHex.uppercased() == "FFFFFF"
                        Image(systemName: selectedSymbol)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(isLightColor ? Color.black : Color.white)
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
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                            }

                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: -2)
            }

            Text(name.isEmpty ? "Subscription Name" : name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }

    private var formContentSection: some View {
        VStack(spacing: 16) {
            // Row 1: Unified Service Name & Color Circle Split Capsule (80/20 Split)
            HStack {
                TextField("Service Name (e.g. Netflix, iCloud)", text: $name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .autocorrectionDisabled()

                Spacer()

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

            // Row 2: Amount Field capsule
            HStack(spacing: 12) {
                Text(store.currencySymbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SpendyColors.textSecondary)

                TextField("Amount (e.g. 199.00)", text: $amountString)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.06), in: Capsule())

            // Detail Card (Grouped Settings Details)
            VStack(spacing: 0) {
                // Billing Cycle
                HStack {
                    Text("Billing Cycle")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)

                    Spacer()

                    Menu {
                        ForEach(BillingCycle.allCases) { item in
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                cycle = item
                            }) {
                                HStack {
                                    Text(item.label)
                                    Spacer()
                                    Image(systemName: cycleIcon(for: item))
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(cycle.label)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(SpendyColors.textPrimary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                }
                .padding(.vertical, 14)

                Divider().background(SpendyColors.separator)

                // First Payment
                DatePicker(
                    selection: $nextBillingDate,
                    displayedComponents: .date
                ) {
                    Text("First Payment")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                .datePickerStyle(.compact)
                .padding(.vertical, 8)

                Divider().background(SpendyColors.separator)

                // Free Trial
                Toggle(isOn: $isTrial) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Free Trial")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text("Remind before trial ends")
                            .font(.system(size: 12))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                }
                .tint(SpendyColors.primaryBlue)
                .padding(.vertical, 8)

                Divider().background(SpendyColors.separator)

                // Payment Account
                HStack {
                    Text("Payment Account")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)

                    Spacer()

                    Menu {
                        ForEach(store.accounts) { acc in
                            Button(action: {
                                selectedAccountId = acc.id
                                HapticsManager.shared.trigger(.selection)
                            }) {
                                HStack {
                                    Text(acc.label)
                                    Spacer()
                                    Image(systemName: acc.sfSymbol)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedAccount?.label ?? "Select Account")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(SpendyColors.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                }
                .padding(.vertical, 14)
            }
            .padding(.horizontal, 18)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }

    private var colorSlidersCard: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
            saveSubscription()
        }) {
            let isLightColor = selectedColorHex.uppercased() == "#FFFFFF" || selectedColorHex.uppercased() == "FFFFFF" || selectedColorHex.uppercased() == "#E4E4E7" || selectedColorHex.uppercased() == "#D4D4D8"

            Text(isEditing ? "Save Changes" : "Create Subscription")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isLightColor ? Color.black : Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: selectedColorHex), in: Capsule())
                .shadow(color: Color(hex: selectedColorHex).opacity(0.2), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Double(amountString) ?? 0) <= 0)
        .opacity((name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Double(amountString) ?? 0) <= 0) ? 0.5 : 1.0)
    }

    private func cycleIcon(for cycle: BillingCycle) -> String {
        switch cycle {
        case .weekly:  return "7.circle"
        case .monthly: return "30.circle"
        case .yearly:  return "calendar"
        }
    }

    private func saveSubscription() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let amountVal = Double(amountString) ?? 0.0

        if let existing = subscriptionToEdit {
            var updated = existing
            updated.name = trimmedName
            updated.amount = amountVal
            updated.cycle = cycle
            updated.nextBillingDate = nextBillingDate
            updated.isTrial = isTrial
            updated.accountId = selectedAccountId
            updated.sfSymbol = selectedSymbol
            updated.colorHex = selectedColorHex
            updated.isDarkBadge = true
            store.updateSubscription(updated)
        } else {
            let newSub = Subscription(
                name: trimmedName,
                amount: amountVal,
                cycle: cycle,
                nextBillingDate: nextBillingDate,
                accountId: selectedAccountId,
                isTrial: isTrial,
                status: "active",
                sfSymbol: selectedSymbol,
                colorHex: selectedColorHex,
                isDarkBadge: true
            )
            store.addSubscription(newSub)
        }
        dismiss()
    }

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
