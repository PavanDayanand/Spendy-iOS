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
    
    private var currentAmountValue: Double {
        Double(amountString) ?? 0
    }
    
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
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                amountHero
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                dockCard
                    .padding(.horizontal, 12)
                    .padding(.bottom, 0)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .presentationBackground(SpendyColors.appBackground)
        .alert("Discard Changes?", isPresented: $showDiscardConfirm) {
            Button("Discard Changes", role: .destructive) {
                HapticsManager.shared.trigger(.warning)
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
    
    
    
    private var headerBar: some View {
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
            
            Text(isEditing ? "Edit Budget" : "Set Budget")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
    }
    
    private var amountHero: some View {
        VStack(spacing: 10) {
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.currencySymbol)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .fixedSize()
                
                Text(amountString)
                    .spendyNumberFont(size: 72, weight: .heavy, tracking: -1.2)
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(1)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: amountString)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            
            if currentAmountValue > 0 {
                Text(selectedPeriod == .weekly ? "weekly limit" : "monthly limit")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .textCase(.lowercase)
            }
            
            Spacer()
        }
    }
    
    private var dockCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SpendyBudgetPeriodToggle(selection: $selectedPeriod)
                
                Spacer(minLength: 0)
                
                startDayMenu
            }
            
            SpendyKeypad(
                amountString: $amountString,
                maxDigits: 8,
                useLiquidGlass: false
            )
            
            HStack {
                Spacer()
                
                Button(action: handleSave) {
                    Text("Save")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(currentAmountValue > 0 ? Color.black : SpendyColors.textTertiary)
                        .padding(.horizontal, 32)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(currentAmountValue > 0 ? Color.white : SpendyColors.cardBackgroundSecondary)
                        }
                }
                .buttonStyle(KeypadPressStyle())
                .disabled(currentAmountValue <= 0)
                .accessibilityLabel("Save")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: "#141416").opacity(0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.14),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                }
        }
    }
    
    private var startDayMenu: some View {
        Menu {
            if selectedPeriod == .weekly {
                ForEach(weekdays) { day in
                    Button {
                        HapticsManager.shared.trigger(.selection)
                        selectedStartDay = day.id
                    } label: {
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
                    Button {
                        HapticsManager.shared.trigger(.selection)
                        selectedStartDay = day
                    } label: {
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
                    .font(.system(size: 14, weight: .semibold))
                
                Text(startDayLabel)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(SpendyColors.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "#1C1C1E"))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.04), lineWidth: 0.8)
                    }
            }
        }
        .accessibilityLabel("Starts \(startDayLabel)")
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
