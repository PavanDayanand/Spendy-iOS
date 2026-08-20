//
//  SettingsView.swift
//  Spendy
//
//  Apple Native Settings & Preferences with Full React Parity
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    // Sheets and Dialogs
    @State private var showNameEdit: Bool = false
    @State private var tempName: String = ""
    
    @State private var showCurrencyPicker: Bool = false
    @State private var showAddAccountSheet: Bool = false
    
    @State private var editingAccountForName: Account? = nil
    @State private var tempAccountName: String = ""
    
    @State private var editingAccountForBalance: Account? = nil
    @State private var tempAccountBalance: String = ""
    
    @State private var accountToDelete: Account? = nil
    
    @State private var showClearConfirm: Bool = false
    @State private var showExportShareSheet: Bool = false
    @State private var exportFileURL: URL? = nil
    @State private var showFileImporter: Bool = false
    @State private var importAlertMessage: String? = nil
    
    @State private var biometricLockEnabled: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. Account & Cloud Profile Header
                        accountCloudCard
                        
                        // 2. Accounts Hub Section
                        accountsSection
                        
                        // 3. Preferences Section
                        preferencesSection
                        
                        // 4. Data & Backup Section
                        dataBackupSection
                        
                        // 5. Community & Developer Links
                        aboutAndSocialSection
                        
                        // Footer App Info
                        appFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
            // MARK: - Modals & Sheets
            .sheet(isPresented: $showNameEdit) {
                editNameSheet
            }
            .sheet(isPresented: $showCurrencyPicker) {
                currencyPickerSheet
            }
            .sheet(isPresented: $showAddAccountSheet) {
                AddAccountSheet()
            }
            .sheet(item: $editingAccountForName) { acc in
                renameAccountSheet(for: acc)
            }
            .sheet(item: $editingAccountForBalance) { acc in
                editBalanceSheet(for: acc)
            }
            .confirmationDialog(
                "Delete Account?",
                isPresented: Binding(
                    get: { accountToDelete != nil },
                    set: { if !$0 { accountToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete \(accountToDelete?.label ?? "Account")", role: .destructive) {
                    if let acc = accountToDelete {
                        store.deleteAccount(id: acc.id)
                    }
                    accountToDelete = nil
                }
            } message: {
                Text("This account will be permanently removed. Transactions tied to this account will remain.")
            }
            .confirmationDialog(
                "Erase All Local Data?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Erase All Data", role: .destructive) {
                    store.clearAllTransactions()
                    HapticsManager.shared.trigger(.warning)
                }
            } message: {
                Text("This will permanently delete all your transactions. This action cannot be undone.")
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let fileURL = urls.first else { return }
                    if fileURL.startAccessingSecurityScopedResource() {
                        defer { fileURL.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: fileURL) {
                            let success = store.importJSONData(data: data)
                            importAlertMessage = success ? "Data imported successfully!" : "Failed to parse JSON backup."
                        }
                    }
                case .failure(let error):
                    importAlertMessage = "Import failed: \(error.localizedDescription)"
                }
            }
            .alert("Backup Status", isPresented: Binding(
                get: { importAlertMessage != nil },
                set: { if !$0 { importAlertMessage = nil } }
            )) {
                Button("OK") { importAlertMessage = nil }
            } message: {
                Text(importAlertMessage ?? "")
            }
        }
    }
    
    // MARK: - 1. Account & Cloud Profile Header
    private var accountCloudCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(SpendyColors.primaryBlue.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Text(store.userName.isEmpty ? "S" : String(store.userName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.primaryBlue)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.userName.isEmpty ? "Spendy User" : store.userName)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(SpendyColors.incomeGreen)
                            .frame(width: 6, height: 6)
                        
                        Text("Local Storage • Offline First")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .overlay(Color.white.opacity(0.08))
            
            // Cloud Sync Placeholder Info
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.accentCyan)
                    
                    Text("Cloud Sync")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                
                Spacer()
                
                Text("Offline Mode")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - 2. Accounts Hub Section
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("ACCOUNTS & WALLETS", systemImage: SFIcons.wallet)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                ForEach(store.accounts) { account in
                    let balance = store.balance(for: account.id)
                    
                    HStack(spacing: 12) {
                        CategoryIconBadge(
                            sfSymbol: account.sfSymbol,
                            tintColor: account.color,
                            size: .small
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.label)
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Balance: \(balance.formattedCurrency(symbol: store.currencySymbol))")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        // Edit actions menu
                        Menu {
                            Button {
                                tempAccountName = account.label
                                editingAccountForName = account
                            } label: {
                                Label("Rename Account", systemImage: "pencil")
                            }
                            
                            Button {
                                tempAccountBalance = String(format: "%.2f", balance)
                                editingAccountForBalance = account
                            } label: {
                                Label("Edit Balance", systemImage: "dollarsign.circle")
                            }
                            
                            if store.accounts.count > 1 {
                                Divider()
                                Button(role: .destructive) {
                                    accountToDelete = account
                                } label: {
                                    Label("Delete Account", systemImage: SFIcons.delete)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.06), in: Circle())
                        }
                    }
                    .padding(14)
                    .background(SpendyColors.cardBackground)
                    
                    if account.id != store.accounts.last?.id {
                        Divider().overlay(Color.white.opacity(0.06))
                    }
                }
                
                // Add Account Button
                Divider().overlay(Color.white.opacity(0.06))
                
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showAddAccountSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: SFIcons.plus)
                            .font(.system(size: 14, weight: .bold))
                        Text("Add Account")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(SpendyColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SpendyColors.cardBackground)
                }
                .buttonStyle(.plain)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            }
        }
    }
    
    // MARK: - 3. Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("PREFERENCES", systemImage: "slider.horizontal.3")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.45))
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                // Name Row
                Button(action: {
                    tempName = store.userName
                    showNameEdit = true
                }) {
                    settingRow(
                        icon: "person.fill",
                        iconColor: SpendyColors.primaryBlue,
                        title: "Your Name",
                        detail: store.userName.isEmpty ? "Set Name" : store.userName,
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Currency Row
                Button(action: {
                    showCurrencyPicker = true
                }) {
                    settingRow(
                        icon: "dollarsign.circle.fill",
                        iconColor: SpendyColors.incomeGreen,
                        title: "Currency",
                        detail: "\(store.currencySymbol) (\(store.currencyCode))",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Sound & Haptics
                HStack(spacing: 12) {
                    CategoryIconBadge(
                        sfSymbol: "speaker.wave.2.fill",
                        tintColor: SpendyColors.warningOrange,
                        size: .small
                    )
                    
                    Text("Sound & Haptics")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { store.soundEnabled },
                        set: { store.soundEnabled = $0 }
                    ))
                    .labelsHidden()
                    .tint(SpendyColors.primaryBlue)
                }
                .padding(14)
                .background(SpendyColors.cardBackground)
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Face ID / App Lock
                HStack(spacing: 12) {
                    CategoryIconBadge(
                        sfSymbol: "faceid",
                        tintColor: SpendyColors.accentCyan,
                        size: .small
                    )
                    
                    Text("Face ID Protection")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $biometricLockEnabled)
                        .labelsHidden()
                        .tint(SpendyColors.primaryBlue)
                }
                .padding(14)
                .background(SpendyColors.cardBackground)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            }
        }
    }
    
    // MARK: - 4. Data & Backup Section
    private var dataBackupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("DATA & BACKUP", systemImage: "externaldrive.fill")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.45))
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                // Export JSON
                Button(action: {
                    exportData()
                }) {
                    settingRow(
                        icon: "square.and.arrow.up.fill",
                        iconColor: SpendyColors.primaryBlue,
                        title: "Export JSON Backup",
                        detail: "Save or share",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Import JSON
                Button(action: {
                    showFileImporter = true
                }) {
                    settingRow(
                        icon: "square.and.arrow.down.fill",
                        iconColor: SpendyColors.incomeGreen,
                        title: "Import JSON Backup",
                        detail: "Restore state",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Erase Local Data
                Button(action: {
                    showClearConfirm = true
                }) {
                    HStack(spacing: 12) {
                        CategoryIconBadge(
                            sfSymbol: SFIcons.delete,
                            tintColor: SpendyColors.expenseRed,
                            size: .small
                        )
                        
                        Text("Erase All Transactions")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(SpendyColors.expenseRed)
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(SpendyColors.cardBackground)
                }
                .buttonStyle(.plain)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            }
        }
    }
    
    // MARK: - 5. Community & Developer Links
    private var aboutAndSocialSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("COMMUNITY & ABOUT", systemImage: "info.circle.fill")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.45))
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                // Suggest a feature
                Link(destination: URL(string: "https://spendy.featurebase.app/")!) {
                    linkRow(
                        icon: "lightbulb.fill",
                        iconColor: SpendyColors.warningOrange,
                        title: "Suggest a Feature",
                        subtitle: "Featurebase board"
                    )
                }
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Instagram
                Link(destination: URL(string: "https://www.instagram.com/pav6n?igsh=ZWg1aW1saW83NzZm&utm_source=qr")!) {
                    linkRow(
                        icon: "camera.fill",
                        iconColor: Color(hex: "#E1306C"),
                        title: "Instagram",
                        subtitle: "@pav6n"
                    )
                }
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Developer Website
                Link(destination: URL(string: "https://studiopavan.netlify.app")!) {
                    linkRow(
                        icon: "globe",
                        iconColor: SpendyColors.accentCyan,
                        title: "Developer Website",
                        subtitle: "studiopavan.netlify.app"
                    )
                }
                
                Divider().overlay(Color.white.opacity(0.06))
                
                // Buy Me a Coffee
                Link(destination: URL(string: "https://www.buymeacoffee.com/spendy")!) {
                    linkRow(
                        icon: "cup.and.saucer.fill",
                        iconColor: Color(hex: "#FFDD00"),
                        title: "Support Spendy",
                        subtitle: "Buy me a coffee"
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            }
        }
    }
    
    // MARK: - App Footer
    private var appFooter: some View {
        VStack(spacing: 4) {
            Text("Spendy for iOS")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("Version 1.0.0 • Liquid Glass Edition")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
    
    // MARK: - Row Helpers
    private func settingRow(icon: String, iconColor: Color, title: String, detail: String, showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            CategoryIconBadge(sfSymbol: icon, tintColor: iconColor, size: .small)
            
            Text(title)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(detail)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            
            if showChevron {
                Image(systemName: SFIcons.chevronRight)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(SpendyColors.cardBackground)
    }
    
    private func linkRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            CategoryIconBadge(sfSymbol: icon, tintColor: iconColor, size: .small)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(14)
        .background(SpendyColors.cardBackground)
    }
    
    // MARK: - Sheets
    private var editNameSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Enter your name", text: $tempName)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .padding(16)
                        .background(SpendyColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Update Display Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNameEdit = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setUserName(tempName.trimmingCharacters(in: .whitespacesAndNewlines))
                        showNameEdit = false
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }
    
    private func renameAccountSheet(for acc: Account) -> some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Account Name", text: $tempAccountName)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .padding(16)
                        .background(SpendyColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Rename Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingAccountForName = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = tempAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty {
                            store.updateAccountName(id: acc.id, newName: name)
                        }
                        editingAccountForName = nil
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }
    
    private func editBalanceSheet(for acc: Account) -> some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Balance")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        TextField("0.00", text: $tempAccountBalance)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .padding(16)
                            .background(SpendyColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Edit Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingAccountForBalance = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let val = Double(tempAccountBalance) {
                            store.updateAccountBalance(id: acc.id, newBalance: val)
                        }
                        editingAccountForBalance = nil
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }
    
    private var currencyPickerSheet: some View {
        let currencies: [(symbol: String, code: String, name: String)] = [
            ("$", "USD", "US Dollar"),
            ("₹", "INR", "Indian Rupee"),
            ("€", "EUR", "Euro"),
            ("£", "GBP", "British Pound"),
            ("¥", "JPY", "Japanese Yen"),
            ("C$", "CAD", "Canadian Dollar"),
            ("A$", "AUD", "Australian Dollar"),
            ("CHF", "CHF", "Swiss Franc"),
            ("AED", "AED", "UAE Dirham"),
            ("SGD", "SGD", "Singapore Dollar")
        ]
        
        return NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                List(currencies, id: \.code) { item in
                    Button(action: {
                        store.updateCurrency(symbol: item.symbol, code: item.code)
                        showCurrencyPicker = false
                    }) {
                        HStack {
                            Text("\(item.symbol)  \(item.code)")
                                .font(.system(.body, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("• \(item.name)")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Spacer()
                            
                            if store.currencyCode == item.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(SpendyColors.primaryBlue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(SpendyColors.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showCurrencyPicker = false }
                }
            }
        }
    }
    
    // MARK: - Export Logic
    private func exportData() {
        guard let data = store.exportJSONData() else { return }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("spendy_backup.json")
        do {
            try data.write(to: tempURL)
            let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(av, animated: true, completion: nil)
            }
        } catch {
            print("Failed to export backup: \(error.localizedDescription)")
        }
    }
}
