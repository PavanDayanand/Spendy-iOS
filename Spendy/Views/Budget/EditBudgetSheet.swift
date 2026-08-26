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
    
    let isEditing: Bool
    var onSave: (() -> Void)? = nil
    
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
            // Dark Base Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 15,
                        foregroundColor: .white,
                        haptic: .selection,
                        accessibilityLabel: "Close"
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Edit Budget")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Amount Display Area
                VStack(spacing: 6) {
                    Text("Budget Limit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#8E8E93"))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(store.currencySymbol)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(Color(hex: "#505054"))
                        
                        Text(formattedAmountDisplay)
                            .font(.system(size: 56, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Controls Row: Period Selector & dynamic Start Day Menu (Uniform 44pt height)
                HStack(spacing: 12) {
                    // Period Selector (Monthly vs Weekly)
                    HStack(spacing: 4) {
                        ForEach(BudgetPeriod.allCases) { period in
                            let isSelected = selectedPeriod == period
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    selectedPeriod = period
                                }
                            }) {
                                Text(period.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(isSelected ? .white : Color(hex: "#8E8E93"))
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background {
                                        if isSelected {
                                            Capsule()
                                                .fill(Color(hex: "#242426"))
                                                .overlay {
                                                    Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                                                }
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .frame(height: 44)
                    .nativeLiquidGlassCapsule(isInteractive: true)
                    
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
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .nativeLiquidGlassCapsule(isInteractive: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                // Custom 3x4 Numpad Grid (Standard 3-column no-operator style)
                let numPadGrid: [[String]] = [
                    ["7", "8", "9"],
                    ["4", "5", "6"],
                    ["1", "2", "3"],
                    [".", "0", "backspace"]
                ]
                
                VStack(spacing: 8) {
                    ForEach(0..<numPadGrid.count, id: \.self) { rowIdx in
                        HStack(spacing: 8) {
                            ForEach(numPadGrid[rowIdx], id: \.self) { key in
                                Button(action: {
                                    handleNumPadKey(key)
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(hex: "#18181A"))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                            }
                                            .frame(height: 52)
                                        
                                        if key == "backspace" {
                                            Image(systemName: "delete.left.fill")
                                                .font(.system(size: 19, weight: .bold))
                                                .foregroundStyle(.white)
                                        } else {
                                            Text(key)
                                                .font(.system(size: 24, weight: .medium))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(KeypadPressStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                // Save Button (Uniform capsule styling)
                Button(action: handleSave) {
                    Text("Save")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle((Double(amountString) ?? 0) > 0 ? Color.black : Color(hex: "#A0A0A4"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background {
                            Capsule()
                                .fill((Double(amountString) ?? 0) > 0 ? Color.white : Color(hex: "#444448"))
                                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
                        }
                }
                .disabled((Double(amountString) ?? 0) <= 0)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
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
    
    private func handleNumPadKey(_ key: String) {
        if key == "backspace" {
            HapticsManager.shared.trigger(.light)
            if amountString.count <= 1 {
                amountString = "0"
            } else {
                amountString.removeLast()
            }
        } else if key == "." {
            HapticsManager.shared.trigger(.selection)
            if !amountString.contains(".") {
                amountString += "."
            }
        } else {
            HapticsManager.shared.trigger(.light)
            if amountString == "0" {
                amountString = key
            } else {
                let parts = amountString.split(separator: ".")
                if parts.count > 1 && parts[1].count >= 2 { return }
                if parts.count == 1 && amountString.count >= 8 { return }
                amountString += key
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
