//
//  AddSubscriptionSheet.swift
//  Spendy
//
//  Minimal Liquid Glass Drawer Sheet for Adding and Editing Recurring Subscriptions
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
    @State private var selectedColorHex: String = "#FFFFFF"
    @State private var isDarkBadge: Bool = false
    @State private var showIconPickerSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    var isEditing: Bool {
        subscriptionToEdit != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // MARK: - Header Icon Preview Button
                        VStack(spacing: 10) {
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                showIconPickerSheet = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(isDarkBadge ? Color(hex: "#18181B") : Color.white)
                                        .frame(width: 76, height: 76)
                                        .shadow(color: isDarkBadge ? Color.black.opacity(0.5) : Color.white.opacity(0.15), radius: 16, x: 0, y: 8)
                                        .overlay {
                                            Circle()
                                                .stroke(isDarkBadge ? Color.white.opacity(0.25) : Color.black.opacity(0.15), lineWidth: 1.5)
                                        }
                                    
                                    Image(systemName: selectedSymbol)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(isDarkBadge ? .white : .black)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                showIconPickerSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Text("Tap icon to change")
                                        .font(.system(size: 13, weight: .semibold, design: .default))
                                    Image(systemName: SFIcons.chevronRight)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(SpendyColors.primaryBlue)
                            }
                        }
                        .padding(.top, 10)
                        
                        // MARK: - Main Inputs Section
                        VStack(spacing: 12) {
                            // Service / Platform Name
                            HStack {
                                Image(systemName: SFIcons.subscriptions)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(width: 24)
                                
                                TextField("Service Name (e.g. Netflix, iCloud)", text: $name)
                                    .font(.system(size: 15, weight: .medium, design: .default))
                                    .foregroundStyle(.white)
                            }
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                    }
                            }
                            
                            // Amount
                            HStack {
                                Text(store.currencySymbol)
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(width: 24)
                                
                                TextField("0.00", text: $amountString)
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundStyle(.white)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                    }
                            }
                        }
                        
                        // MARK: - Cycle & Free Trial Card
                        GlassCard(cornerRadius: 20) {
                            VStack(spacing: 16) {
                                // Date Picker
                                DatePicker(
                                    isTrial ? "Trial ends on" : "First payment date",
                                    selection: $nextBillingDate,
                                    displayedComponents: [.date]
                                )
                                .font(.system(size: 15, weight: .medium, design: .default))
                                .foregroundStyle(.white)
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                
                                // Billing Cycle
                                HStack {
                                    Text("Billing Cycle")
                                        .font(.system(size: 15, weight: .medium, design: .default))
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    GlassSegmentedPicker(
                                        selection: $cycle,
                                        items: BillingCycle.allCases,
                                        titleFor: { $0.label },
                                        activeTint: SpendyColors.primaryBlue
                                    )
                                    .frame(width: 180)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                
                                // Free Trial Toggle Switch
                                Toggle(isOn: $isTrial) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Free Trial")
                                            .font(.system(size: 15, weight: .semibold, design: .default))
                                            .foregroundStyle(.white)
                                        Text("Don't charge amount until trial ends")
                                            .font(.system(size: 12, weight: .regular, design: .default))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                .tint(SpendyColors.incomeGreen)
                            }
                        }
                        
                        // MARK: - Linked Payment Account Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LINKED PAYMENT ACCOUNT")
                                .font(.system(size: 11, weight: .bold, design: .default))
                                .tracking(1.0)
                                .foregroundStyle(.white.opacity(0.45))
                                .padding(.horizontal, 4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(store.accounts) { acc in
                                        Button(action: {
                                            selectedAccountId = acc.id
                                            HapticsManager.shared.trigger(.selection)
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: acc.sfSymbol)
                                                    .font(.system(size: 12, weight: .bold))
                                                Text(acc.label)
                                                    .font(.system(size: 13, weight: .semibold, design: .default))
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background {
                                                Capsule()
                                                    .fill(selectedAccountId == acc.id ? Color.white : Color.white.opacity(0.06))
                                            }
                                            .foregroundStyle(selectedAccountId == acc.id ? Color.black : Color.white.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Delete Action (If Editing)
                        if isEditing {
                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: SFIcons.delete)
                                    Text("Delete Subscription")
                                        .font(.system(size: 15, weight: .bold, design: .default))
                                    Spacer()
                                }
                                .foregroundStyle(SpendyColors.expenseRed)
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(SpendyColors.expenseRed.opacity(0.12))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(SpendyColors.expenseRed.opacity(0.3), lineWidth: 0.8)
                                        }
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(isEditing ? "Edit Subscription" : "New Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveSubscription()
                    }
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Double(amountString) ?? 0) <= 0)
                }
            }
            .sheet(isPresented: $showIconPickerSheet) {
                SubscriptionIconPickerSheet(selectedSymbol: $selectedSymbol, isDarkBadge: $isDarkBadge)
            }
            .alert("Delete Subscription?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let sub = subscriptionToEdit {
                        store.deleteSubscription(id: sub.id)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this subscription? This action cannot be undone.")
            }
            .onAppear {
                if let sub = subscriptionToEdit {
                    name = sub.name
                    amountString = sub.amount > 0 ? String(format: "%.2f", sub.amount) : ""
                    cycle = sub.cycle
                    nextBillingDate = sub.nextBillingDate
                    isTrial = sub.isTrial
                    selectedAccountId = sub.accountId
                    selectedSymbol = sub.sfSymbol
                    selectedColorHex = sub.colorHex
                    isDarkBadge = sub.isDarkBadge
                }
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Save Action
    private func saveSubscription() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let amountVal = Double(amountString) ?? 0.0
        let colorToSave = isDarkBadge ? "#18181B" : "#FFFFFF"
        
        if let existing = subscriptionToEdit {
            var updated = existing
            updated.name = trimmedName
            updated.amount = amountVal
            updated.cycle = cycle
            updated.nextBillingDate = nextBillingDate
            updated.isTrial = isTrial
            updated.accountId = selectedAccountId
            updated.sfSymbol = selectedSymbol
            updated.colorHex = colorToSave
            updated.isDarkBadge = isDarkBadge
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
                colorHex: colorToSave,
                isDarkBadge: isDarkBadge
            )
            store.addSubscription(newSub)
        }
        dismiss()
    }
}
