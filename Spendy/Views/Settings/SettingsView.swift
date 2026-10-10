//
//  SettingsView.swift
//  Spendy
//
//  Organized settings: profile, display, money, alerts, data, about.
//  Monochrome row icons. Home gradient lives here, not in profile.
//

import SwiftUI

enum SettingsDestination: Hashable {
    case accounts
    case categories
    case dataBackup
    case insightCardsGallery
    case appIcon
    case widgets
}

struct SettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var initialDestination: SettingsDestination? = nil
    @State private var navigationPath: NavigationPath

    init(initialDestination: SettingsDestination? = nil) {
        self.initialDestination = initialDestination
        var path = NavigationPath()
        if let initial = initialDestination {
            path.append(initial)
        }
        _navigationPath = State(initialValue: path)
    }

    @State private var showProfileEdit: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var showReceiptPrinter: Bool = false
    @State private var showCoffeeSheet: Bool = false
    @State private var showOnboardingTour: Bool = false

    private let feedbackURL = URL(string: "https://spendy.featurebase.app/")
    private let instagramURL = URL(string: "https://www.instagram.com/pav6n")
    private let websiteURL = URL(string: "https://studiopavan.netlify.app")
    private let coffeeURL = URL(string: "https://www.buymeacoffee.com/spendy")

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                SpendyColors.settingsBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        profileCard

                        settingsGroup(title: "Money") {
                            NavigationLink(value: SettingsDestination.accounts) {
                                linkRow(icon: "creditcard", title: "Accounts", value: "\(store.accounts.count)")
                            }
                            groupDivider
                            NavigationLink(value: SettingsDestination.categories) {
                                linkRow(icon: "square.grid.2x2", title: "Categories", value: "\(store.categories.count)")
                            }
                            groupDivider
                            Button {
                                HapticsManager.shared.trigger(.light)
                                showCurrencyPicker = true
                            } label: {
                                linkRow(
                                    icon: "coloncurrencysign",
                                    title: "Currency",
                                    value: "\(store.currencyCode) \(store.currencySymbol)"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        settingsGroup(title: "Display") {
                            appearanceRow
                            groupDivider
                            toggleRow(
                                icon: "sparkles",
                                title: "Home gradient",
                                isOn: Binding(
                                    get: { store.isGradientBackgroundEnabled },
                                    set: {
                                        store.isGradientBackgroundEnabled = $0
                                        HapticsManager.shared.trigger(.selection)
                                    }
                                )
                            )
                            groupDivider
                            NavigationLink(value: SettingsDestination.appIcon) {
                                appIconRow
                            }
                            .buttonStyle(.plain)
                            groupDivider
                            NavigationLink(value: SettingsDestination.widgets) {
                                linkRow(icon: "square.grid.2x2", title: "Home Screen widgets", value: nil)
                            }
                        }

                        settingsGroup(title: "Alerts") {
                            toggleRow(
                                icon: "iphone.radiowaves.left.and.right",
                                title: "Haptics",
                                isOn: Binding(
                                    get: { store.hapticsEnabled },
                                    set: {
                                        store.hapticsEnabled = $0
                                        HapticsManager.shared.trigger(.selection)
                                    }
                                )
                            )
                            groupDivider
                            toggleRow(
                                icon: "bell",
                                title: "Bill reminders",
                                isOn: Binding(
                                    get: { store.notificationsEnabled },
                                    set: { newValue in
                                        store.notificationsEnabled = newValue
                                        HapticsManager.shared.trigger(.selection)
                                        if newValue {
                                            Task {
                                                let granted = await NotificationManager.shared.requestAuthorization()
                                                if granted {
                                                    NotificationManager.shared.syncAllSubscriptionReminders(subscriptions: store.subscriptions)
                                                }
                                            }
                                        }
                                    }
                                )
                            )
                        }

                        settingsGroup(title: "Data") {
                            NavigationLink(value: SettingsDestination.dataBackup) {
                                linkRow(icon: "externaldrive", title: "Backup & Restore", value: "JSON")
                            }
                            groupDivider
                            Button {
                                HapticsManager.shared.trigger(.selection)
                                showReceiptPrinter = true
                            } label: {
                                linkRow(icon: "printer", title: "Monthly receipt", value: nil)
                            }
                            .buttonStyle(.plain)
                        }

                        settingsGroup(title: "About") {
                            if let feedbackURL {
                                Link(destination: feedbackURL) {
                                    externalRow(icon: "envelope", title: "Send feedback")
                                }
                            }
                            groupDivider
                            Button {
                                showOnboardingTour = true
                            } label: {
                                linkRow(icon: "hand.wave", title: "Replay welcome", value: nil)
                            }
                            .buttonStyle(.plain)
                            if let instagramURL {
                                groupDivider
                                Link(destination: instagramURL) {
                                    externalRow(icon: "camera", title: "Instagram", value: "@pav6n")
                                }
                            }
                            if let websiteURL {
                                groupDivider
                                Link(destination: websiteURL) {
                                    externalRow(icon: "safari", title: "Website", value: "studiopavan")
                                }
                            }
                            groupDivider
                            Button {
                                showCoffeeSheet = true
                            } label: {
                                linkRow(icon: "cup.and.saucer", title: "Support Spendy", value: nil)
                            }
                            .buttonStyle(.plain)
                        }

                        footerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
            }
            .navigationDestination(for: SettingsDestination.self) { dest in
                switch dest {
                case .accounts:
                    AccountsView()
                case .categories:
                    CategoriesSettingsView()
                case .dataBackup:
                    DataManagementView()
                case .insightCardsGallery:
                    InsightCardsGalleryView()
                case .appIcon:
                    AppIconPickerView()
                case .widgets:
                    WidgetShowcaseView()
                }
            }
            .onAppear {
                if let initial = initialDestination, navigationPath.isEmpty {
                    navigationPath.append(initial)
                }
            }
            .sheet(isPresented: $showProfileEdit) {
                EditProfileSheet()
            }
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerSheet()
            }
            .sheet(isPresented: $showReceiptPrinter) {
                ReceiptPrinterSheet()
            }
            .sheet(isPresented: $showCoffeeSheet) {
                coffeeSheet
            }
            .fullScreenCover(isPresented: $showOnboardingTour) {
                OnboardingView()
            }
        }
        .preferredColorScheme(store.colorScheme)
    }

    // MARK: - Profile
    private var profileCard: some View {
        Button {
            HapticsManager.shared.trigger(.light)
            showProfileEdit = true
        } label: {
            HStack(spacing: 14) {
                profileAvatar

                VStack(alignment: .leading, spacing: 3) {
                    Text(store.userName.isEmpty ? "Your name" : store.userName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    Text("Name, photo, accent")
                        .font(AppTypography.footnoteMedium)
                        .foregroundStyle(SpendyColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .padding(16)
            .background { groupedCardBackground }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit profile")
    }

    private var profileAvatar: some View {
        ZStack {
            if let imgData = store.profileImageData, let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(SpendyColors.separator, lineWidth: 1))
            } else if let symbol = store.profileIconSymbol, !symbol.isEmpty {
                Circle()
                    .fill(store.topGradientColor)
                    .frame(width: 52, height: 52)
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .frame(width: 52, height: 52)
                Text(store.userName.isEmpty ? "S" : String(store.userName.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
        }
        .frame(width: 52, height: 52)
    }

    // MARK: - Appearance picker
    private var appearanceRow: some View {
        HStack(spacing: 14) {
            rowIcon("circle.lefthalf.filled")
            Text("Appearance")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            Spacer()
            Menu {
                Picker("Appearance", selection: Binding(
                    get: { store.appearanceMode },
                    set: { newValue in
                        store.appearanceMode = newValue
                        HapticsManager.shared.trigger(.selection)
                    }
                )) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(store.appearanceMode.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }

    private var appIconRow: some View {
        HStack(spacing: 14) {
            rowIcon("app")
            Text("App icon")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            Spacer()
            Image(SpendyAppIcon.current.assetImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(SpendyAppIcon.current.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 8) {
            Image("SpendyLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text("Spendy")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
                .font(AppTypography.captionMedium)
                .foregroundStyle(SpendyColors.textTertiary)
            Text("Made by Pavan")
                .font(AppTypography.captionMedium)
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Layout helpers
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content()
            }
            .background { groupedCardBackground }
        }
    }

    private var groupedCardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(SpendyColors.sheetCardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
    }

    private var groupDivider: some View {
        Divider()
            .overlay(SpendyColors.separator)
            .padding(.leading, 54)
    }

    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(SpendyColors.textPrimary)
            .frame(width: 28, height: 28)
            .accessibilityHidden(true)
    }

    private func linkRow(icon: String, title: String, value: String?) -> some View {
        HStack(spacing: 14) {
            rowIcon(icon)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private func externalRow(icon: String, title: String, value: String? = nil) -> some View {
        HStack(spacing: 14) {
            rowIcon(icon)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            rowIcon(icon)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(SpendyColors.incomeGreen)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }

    private var coffeeSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "cup.and.saucer")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .padding(.top, 24)
                    Text("Support Spendy")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    Text("Keep Spendy independent, ad-free, and on-device.")
                        .font(.system(.body))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    if let coffeeURL {
                        Link(destination: coffeeURL) {
                            Text("Buy me a coffee")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(SpendyColors.inverseText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SpendyColors.textPrimary, in: Capsule())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
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
}
