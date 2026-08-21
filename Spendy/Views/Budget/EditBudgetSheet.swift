//
//  EditBudgetSheet.swift
//  Spendy
//
//  Apple Design Budget Edit & Creation Sheet matching Screenshot #2
//

import SwiftUI

struct EditBudgetSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var amountString: String = "0"
    @State private var selectedPeriod: BudgetPeriod = .monthly
    @State private var selectedStartDay: Int = 1
    
    let isEditing: Bool
    
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
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        dismiss()
                    }) {
                        Image(systemName: SFIcons.close)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Budget")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Amount Display Area
                VStack(spacing: 8) {
                    Text("Set your overall budget limit for this period")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(store.currencySymbol)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Text(formattedAmountDisplay)
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    // Spending context & recommendation badge
                    VStack(spacing: 6) {
                        Text("Last 30 days: \(store.last30DaysExpenses.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                        
                        if let recommended = store.recommendedBudget {
                            Button(action: {
                                HapticsManager.shared.trigger(.light)
                                amountString = String(format: "%.0f", recommended)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: "#FFD60A"))
                                    Text("Suggested budget: ")
                                        .foregroundStyle(.white.opacity(0.6))
                                    + Text(recommended.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                        .bold()
                                        .foregroundStyle(.white)
                                    + Text(" (Use)")
                                        .foregroundStyle(SpendyColors.primaryBlue)
                                }
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.08), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // Controls Row: Period Toggle & Start Day Picker
                HStack(spacing: 12) {
                    // Segment Toggle for Period
                    HStack(spacing: 4) {
                        ForEach(BudgetPeriod.allCases) { period in
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                selectedPeriod = period
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: period == .monthly ? "calendar.day.timeline.left" : "calendar")
                                        .font(.system(size: 13, weight: .medium))
                                    Text(period.title)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(selectedPeriod == period ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background {
                                    if selectedPeriod == period {
                                        Capsule()
                                            .fill(SpendyColors.primaryBlue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(Color.white.opacity(0.08), in: Capsule())
                    
                    Spacer()
                    
                    // Start Day Menu Dropdown
                    Menu {
                        ForEach(1...28, id: \.self) { day in
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                selectedStartDay = day
                            }) {
                                HStack {
                                    Text("Start \(ordinalSuffix(for: day))")
                                    if selectedStartDay == day {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Start \(selectedStartDay)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Image(systemName: SFIcons.chevronDown)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08), in: Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Custom 3x4 Numpad Grid
                let numPadGrid: [[String]] = [
                    ["7", "8", "9"],
                    ["4", "5", "6"],
                    ["1", "2", "3"],
                    [".", "0", "backspace"]
                ]
                
                VStack(spacing: 10) {
                    ForEach(0..<numPadGrid.count, id: \.self) { rowIdx in
                        HStack(spacing: 12) {
                            ForEach(numPadGrid[rowIdx], id: \.self) { key in
                                Button(action: {
                                    handleNumPadKey(key)
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.08))
                                            .frame(height: 52)
                                        
                                        if key == "backspace" {
                                            Image(systemName: "delete.left")
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundStyle(.white)
                                        } else {
                                            Text(key)
                                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Save Button
                Button(action: handleSave) {
                    Text("Save")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white, in: Capsule())
                }
                .disabled((Double(amountString) ?? 0) <= 0)
                .opacity((Double(amountString) ?? 0) <= 0 ? 0.5 : 1.0)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
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
            HapticsManager.shared.trigger(.medium)
            if amountString.count <= 1 {
                amountString = "0"
            } else {
                amountString.removeLast()
            }
        } else if key == "." {
            HapticsManager.shared.trigger(.light)
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
        HapticsManager.shared.trigger(.medium)
        store.setBudget(
            amount: amt,
            period: selectedPeriod,
            startDay: selectedStartDay
        )
        dismiss()
    }
}
