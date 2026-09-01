//
//  EditBudgetSheet.swift
//  Spendy
//
//  Redesigned Liquid Glass Budget Creation & Edit Sheet
//  Features:
//  - Uniform 44pt Control Heights and Capsule Buttons
//  - Clean 3-Column Numeric Keypad (No Math Operators)
//  - Dynamic Period Switcher (Monthly vs Weekly)
//  - Start Day/Date Selector that dynamically switches between Weekdays (Monday-Sunday) and Month Dates (1st-28th)
//  - Fully Glassmorphic Material Backdrop & Transparent ZStack Layers
//

import SwiftUI

struct WeekdayItem: Identifiable, Hashable {
    var id: Int // Calendar weekday component: 1 = Sunday, 2 = Monday, ...
    var name: String
}

struct EditBudgetSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var amountString: String = "0"
    @State private var selectedPeriod: BudgetPeriod = .monthly
    @State private var selectedStartDay: Int = 1
    @State private var showDiscardConfirm: Bool = false
    @Namespace private var budgetSheetNamespace
    
    let isEditing: Bool
    var onSave: (() -> Void)? = nil
    
    private var hasUnsavedChanges: Bool {
        let currentAmt = Double(amountString) ?? 0.0
        if isEditing && store.budget.isActive {
            return currentAmt != store.budget.amount ||
                   selectedPeriod != store.budget.period ||
                   selectedStartDay != store.budget.startDay
        } else {
            return currentAmt > 0
        }
    }
    
    private let weekdays = [
        WeekdayItem(id: 2, name: "Mon"),
        WeekdayItem(id: 3, name: "Tue"),
        WeekdayItem(id: 4, name: "Wed"),
        WeekdayItem(id: 5, name: "Thu"),
        WeekdayItem(id: 6, name: "Fri"),
        WeekdayItem(id: 7, name: "Sat"),
        WeekdayItem(id: 1, name: "Sun")
    ]
    
    private var formattedAmountDisplay: String {
        if amountString == "0" || amountString.isEmpty { return "0" }
        let parts = amountString.split(separator: ".")
        if let intVal = Int(parts[0]) {
            let formattedInt = NumberFormatter.localizedString(from: NSNumber(value: intVal), number: .decimal)
            if amountString.hasSuffix(".") {
                return formattedInt + "."
            } else if parts.count > 1 {
                return formattedInt + "." + parts[1]
            }
            return formattedInt
        }
        return amountString
    }
    
    private func ordinalSuffix(for day: Int) -> String {
        let n = day % 100
        if (11...13).contains(n) { return "\(day)th" }
        switch day % 10 {
        case 1: return "\(day)st"
        case 2: return "\(day)nd"
        case 3: return "\(day)rd"
        default: return "\(day)th"
        }
    }
    
    private var startDayLabel: String {
        if selectedPeriod == .weekly {
            return weekdays.first(where: { $0.id == selectedStartDay })?.name ?? "Mon"
        } else {
            return ordinalSuffix(for: selectedStartDay)
        }
    }
    
    var body: some View {
        ZStack {
            // Adaptive Base Background
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                SpendyGlassEffectContainer(spacing: 0) {
                    HStack {
                        GlassCircleButton(
                            icon: "xmark",
                            size: 44,
                            iconSize: 15,
                            foregroundColor: SpendyColors.textPrimary,
                            haptic: .selection,
                            accessibilityLabel: "Close",
                            morphID: "closeButton",
                            namespace: budgetSheetNamespace
                        ) {
                            if hasUnsavedChanges {
                                showDiscardConfirm = true
                            } else {
                                dismiss()
                            }
                        }
                        
                        Spacer()
                        
                        Text("Edit Budget")
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Amount Display Area
                VStack(spacing: 6) {
                    Text("Budget Limit")
                        .font(AppTypography.subheadlineSemibold)
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Text("\(store.currencySymbol)\(formattedAmountDisplay)")
                        .spendyNumberFont(size: 44, weight: .heavy, tracking: -1.2)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Mode Selectors Row: [ Monthly / Weekly ] + [ Starts: 1st ⌄ ]
                SpendyGlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        // Monthly / Weekly Expanding Toggle Capsule (44pt height, M / W icons)
                        SpendyBudgetPeriodToggle(
                            selection: $selectedPeriod
                        )
                        
                        Spacer()
                        
                        // Start Day Dropdown (44pt height, changes dynamically)
                        Menu {
                            if selectedPeriod == .weekly {
                                ForEach(weekdays) { day in
                                    Button(action: {
                                        HapticsManager.shared.trigger(.selection)
                                        selectedStartDay = day.id
                                    }) {
                                        HStack {
                                            Text(day.name)
                                            if selectedStartDay == day.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } else {
                                ForEach(1...28, id: \.self) { day in
                                    Button(action: {
                                        HapticsManager.shared.trigger(.selection)
                                        selectedStartDay = day
                                    }) {
                                        HStack {
                                            Text(ordinalSuffix(for: day))
                                            if selectedStartDay == day {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                
                                Text("Starts: \(startDayLabel)")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundStyle(SpendyColors.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .nativeLiquidGlassCapsule(isInteractive: true)
                            .glassMorphID("startDayDropdown", in: budgetSheetNamespace)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                // Shared 3x4 Numpad Grid
                SpendyKeypad(amountString: $amountString, maxDigits: 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                // Save Button (Adaptive Apple styling)
                Button(action: handleSave) {
                    Text("Save Budget")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(SpendyColors.inverseText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill((Double(amountString) ?? 0) > 0 ? SpendyColors.primaryBlue : SpendyColors.cardBackgroundSecondary)
                                .overlay {
                                    if (Double(amountString) ?? 0) <= 0 {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                                    }
                                }
                        }
                }
                .disabled((Double(amountString) ?? 0) <= 0)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .presentationBackground(SpendyColors.appBackground)
        .alert("Discard Changes?", isPresented: $showDiscardConfirm) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .onChange(of: selectedPeriod) { oldValue, newValue in
            if newValue == .weekly {
                selectedStartDay = 2 // Default to Monday
            } else {
                selectedStartDay = 1 // Default to 1st of month
            }
        }
        .onAppear {
            if isEditing && store.budget.isActive {
                amountString = String(format: "%.0f", store.budget.amount)
                selectedPeriod = store.budget.period
                selectedStartDay = store.budget.startDay
            } else {
                amountString = "0"
                selectedPeriod = .monthly
                selectedStartDay = 1
            }
        }
    }
    
    
    
    private func handleSave() {
        guard let amt = Double(amountString), amt > 0 else { return }
        HapticsManager.shared.trigger(.success)
        store.setBudget(
            amount: amt,
            period: selectedPeriod,
            startDay: selectedStartDay
        )
        dismiss()
        onSave?()
    }
}
