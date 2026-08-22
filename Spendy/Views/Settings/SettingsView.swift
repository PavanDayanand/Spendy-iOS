//
//  SettingsView.swift
//  Spendy
//
//  Settings & Preferences matching the Spendy React App with Liquid Glass Design
//

import SwiftUI

struct SettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    // Sheets & Dialogs
    @State private var showNameEdit: Bool = false
    @State private var tempName: String = ""
    @State private var showCurrencyPicker: Bool = false
    @State private var showWhatsNewSheet: Bool = false
    @State private var showCoffeeSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Top Header Bar with Circular Glass Close Button
                        headerBar
                        
                        // Suggest a Feature Banner (from React app)
                        featureSuggestionBanner
                        
                        // User Profile Card
                        userProfileCard
                        
                        // 1. Manage Section (Accounts & Categories)
                        manageSection
                        
                        // 2. Preferences Section (Currency & Sound Effects)
                        preferencesSection
                        
                        // 3. Data & Backup Section (Export, Import, Reset)
                        dataBackupSection
                        
                        // 4. About & Community Section (Instagram, Web, Buy Me Coffee, Changelog)
                        aboutSection
                        
                        // 5. Footer App Branding
                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            // MARK: - Modals & Sheets
            .sheet(isPresented: $showNameEdit) {
                editNameSheet
            }
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerSheet()
            }
            .sheet(isPresented: $showWhatsNewSheet) {
                whatsNewSheet
            }
            .sheet(isPresented: $showCoffeeSheet) {
                coffeeSheet
            }
        }
    }
    
    // MARK: - Top Header Bar
    private var headerBar: some View {
        HStack {
            // Circular Glass Close Button
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
            
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
    }
    
    // MARK: - Feature Suggestion Banner
    private var featureSuggestionBanner: some View {
        Link(destination: URL(string: "https://spendy.featurebase.app/")!) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Suggest a Feature")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("or report bugs & feedback")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                
                Spacer()
                
                GlassCircleIcon(
                    icon: "arrow.up.right",
                    size: 36,
                    iconSize: 14,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary
                )
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - User Profile Card
    private var userProfileCard: some View {
        HStack(spacing: 16) {
            // Profile Photo Circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SpendyColors.primaryBlue, SpendyColors.accentCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: SpendyColors.primaryBlue.opacity(0.35), radius: 8, y: 2)
                
                if !store.userName.isEmpty {
                    Text(String(store.userName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(store.userName.isEmpty ? "Your Name" : store.userName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Text("Local-First & Offline Ready")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            
            Spacer()
            
            GlassCircleButton(
                icon: SFIcons.edit,
                size: 38,
                iconSize: 13,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .light,
                accessibilityLabel: "Edit Name"
            ) {
                tempName = store.userName
                showNameEdit = true
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - 1. Manage Section (Accounts & Categories)
    private var manageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MANAGE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Accounts Hub Link
                NavigationLink(destination: AccountsSettingsView()) {
                    rowItem(
                        icon: "building.columns.fill",
                        iconColor: SpendyColors.primaryBlue,
                        title: "Accounts & Wallets",
                        badgeText: "\(store.accounts.count)"
                    )
                }
                
                Divider().overlay(SpendyColors.separator).padding(.leading, 56)
                
                // Categories Link
                NavigationLink(destination: CategoriesSettingsView()) {
                    rowItem(
                        icon: "square.grid.2x2.fill",
                        iconColor: SpendyColors.incomeGreen,
                        title: "Categories",
                        badgeText: "\(store.categories.count)"
                    )
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - 2. Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PREFERENCES")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.horizontal, 4)
            
            // Custom Image 2 Style Color Picker & Gradient Background Card
            CustomColorSliderPickerView()
            
            VStack(spacing: 0) {
                // Currency Selector
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showCurrencyPicker = true
                }) {
                    rowItem(
                        icon: "globe",
                        iconColor: SpendyColors.textPrimary,
                        title: "Currency",
                        badgeText: "\(CurrencyInfo.flag(for: store.currencyCode)) \(store.currencySymbol)"
                    )
                }
                .buttonStyle(.plain)
                
                Divider().overlay(SpendyColors.separator).padding(.leading, 56)
                
                // Sound Effects & Haptics Toggle
                HStack(spacing: 14) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .frame(width: 28, height: 28)
                    
                    Text("Sound Effects")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { store.soundEnabled },
                        set: { store.soundEnabled = $0 }
                    ))
                    .labelsHidden()
                    .toggleStyle(.liquidGlass(tint: SpendyColors.textPrimary))
                }
                .padding(14)
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - 3. Data & Backup Section
    private var dataBackupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DATA & BACKUP")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                NavigationLink(destination: DataManagementView()) {
                    rowItem(
                        icon: "cylinder.split.1x2.fill",
                        iconColor: SpendyColors.incomeGreen,
                        title: "Backup & Restore",
                        badgeText: "JSON"
                    )
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - 4. About & Community Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ABOUT")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                Button(action: { showWhatsNewSheet = true }) {
                    rowItem(icon: "sparkles", iconColor: Color(hex: "#FFD60A"), title: "What's New in Spendy", badgeText: "v2.0.0")
                }
                .buttonStyle(.plain)
                
                Divider().overlay(SpendyColors.separator).padding(.leading, 56)
                
                Button(action: { showCoffeeSheet = true }) {
                    rowItem(icon: "cup.and.saucer.fill", iconColor: SpendyColors.warningOrange, title: "Buy Me a Coffee", badgeText: "Support")
                }
                .buttonStyle(.plain)
                
                Divider().overlay(SpendyColors.separator).padding(.leading, 56)
                
                Link(destination: URL(string: "https://www.instagram.com/pav6n?igsh=ZWg1aW1saW83NzZm&utm_source=qr")!) {
                    rowExternalItem(icon: "camera.fill", iconColor: Color(hex: "#FF375F"), title: "Instagram", value: "@pav6n")
                }
                
                Divider().overlay(SpendyColors.separator).padding(.leading, 56)
                
                Link(destination: URL(string: "https://studiopavan.netlify.app")!) {
                    rowExternalItem(icon: "globe", iconColor: SpendyColors.primaryBlue, title: "Developer Website", value: "studiopavan")
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - 5. Footer App Branding
    private var footerSection: some View {
        VStack(spacing: 12) {
            Text("made with ❤️ by Pavan")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Image("SpendyLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: SpendyColors.primaryBlue.opacity(0.35), radius: 8, y: 2)
            
            VStack(spacing: 2) {
                Text("Spendy")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Text("Version 2.0.0 • Liquid Glass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Row Items
    private func rowItem(icon: String, iconColor: Color, title: String, badgeText: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            if let badge = badgeText {
                Text(badge)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(14)
    }
    
    private func rowExternalItem(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(14)
    }

    
    // MARK: - Edit Name Sheet
    private var editNameSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Enter your name", text: $tempName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(SpendyColors.cardBackground)
                        }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Your Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNameEdit = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.userName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                        showNameEdit = false
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }
    
    // MARK: - What's New Sheet
    private var whatsNewSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("What's New in Spendy 2.0")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        featureBullet(title: "Liquid Glass Bottom Bar", desc: "True native iOS floating glass navigation bar.")
                        featureBullet(title: "Real-Time Accounts Hub", desc: "Net worth calculation with sparkline curves and balance adjustment.")
                        featureBullet(title: "Category Management", desc: "Expense and income category groups with quick search.")
                        featureBullet(title: "Data Backup & Restore", desc: "One-tap export and import of your transactions JSON.")
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showWhatsNewSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Buy Me A Coffee Sheet
    private var coffeeSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(SpendyColors.warningOrange)
                        .padding(.top, 24)
                    
                    Text("Buy Me a Coffee")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("Support Spendy independent development and help keep it ad-free and privacy-first!")
                        .font(.system(.body))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Link(destination: URL(string: "https://www.buymeacoffee.com/spendy")!) {
                        Text("Open Buy Me a Coffee ☕")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#FFDD00"), in: Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showCoffeeSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func featureBullet(title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SpendyColors.incomeGreen)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                Text(desc)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
        }
    }
}
