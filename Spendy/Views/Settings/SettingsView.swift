//
//  SettingsView.swift
//  Spendy
//
//  Profile, money, app preferences, data, and a dedicated help/about page.
//

import SwiftUI

enum SettingsDestination: Hashable {
    case accounts
    case categories
    case dataBackup
    case privacyPolicy
    case widgets
    case appAccent
    case insights
    case notifications
    case about
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
    @State private var showReceiptPrinter: Bool = false
    @State private var showCoffeeSheet: Bool = false
    @State private var showOnboardingTour: Bool = false

    private let feedbackURL = URL(string: "https://spendy.userjot.com/")
    private let instagramURL = URL(string: "https://www.instagram.com/pav6n")
    private let websiteURL = URL(string: "https://studiopavan.netlify.app")
    private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
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

                        }

                        settingsGroup(title: "App preferences") {
                            NavigationLink(value: SettingsDestination.appAccent) {
                                linkRow(icon: "circle.lefthalf.filled", title: "Appearance", value: store.appearanceMode.rawValue)
                            }
                            .accessibilityIdentifier("settings-app-accent")
                            groupDivider
                            NavigationLink(value: SettingsDestination.insights) {
                                linkRow(icon: SpendyInsightBrandMark.symbol, title: "Spendy Insights", value: store.insightsEnabled ? "On" : "Off")
                            }.buttonStyle(.plain)
                            groupDivider
                            NavigationLink(value: SettingsDestination.notifications) {
                                linkRow(icon: "bell", title: "Notifications", value: nil)
                            }.buttonStyle(.plain)
                            groupDivider
                            Toggle(isOn: Binding(
                                get: { store.hapticsEnabled },
                                set: { store.hapticsEnabled = $0 }
                            )) {
                                HStack(spacing: 14) {
                                    rowIcon("waveform")
                                    Text("Haptic feedback").font(.body.weight(.medium))
                                }
                            }
                            .tint(store.accentPreset.switchTint)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(minHeight: 52)
                        }

                        settingsGroup(title: "Data & exports") {
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

                        settingsGroup(title: "Help & information") {
                            NavigationLink(value: SettingsDestination.about) {
                                linkRow(icon: "questionmark.circle", title: "Help & about Spendy", value: nil)
                            }
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
                    AccountsView(isSettingsPage: true)
                case .categories:
                    CategoriesSettingsView()
                case .dataBackup:
                    DataManagementView()
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .appAccent:
                    AppAccentSettingsView()
                case .widgets:
                    WidgetShowcaseView()
                case .insights:
                    InsightsPreferencesView()
                case .notifications:
                    NotificationPreferencesView()
                case .about:
                    aboutSettingsPage
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
        .presentationBackground(SpendyColors.settingsBackground)
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
                        .font(.headline)
                        .foregroundStyle(SpendyColors.textPrimary)
                    Text("Name, photo, currency")
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

    private var aboutSettingsPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                        settingsGroup(title: "Legal") {
                            if let privacyURL = PrivacyPolicyDocument.current?.websiteURL {
                                Link(destination: privacyURL) {
                                    externalRow(icon: "hand.raised", title: "Privacy Policy")
                                }
                                .accessibilityIdentifier("settings-privacy-policy")
                            } else {
                                NavigationLink(value: SettingsDestination.privacyPolicy) {
                                    linkRow(icon: "hand.raised", title: "Privacy Policy", value: nil)
                                }
                                .accessibilityIdentifier("settings-privacy-policy")
                            }
                            if let termsOfUseURL {
                                groupDivider
                                Link(destination: termsOfUseURL) {
                                    externalRow(icon: "doc.text", title: "Terms of Use", value: "Apple EULA")
                                }
                                .accessibilityIdentifier("settings-terms-of-use")
                            }
                        }

                        settingsGroup(title: "About") {
                            if let feedbackURL {
                                Link(destination: feedbackURL) {
                                    externalRow(icon: "envelope", title: "Request a feature")
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


            }
            .padding(20)
        }
        .background(SpendyColors.settingsBackground)
        .navigationTitle("Help & about")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Image("SpendyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Image("SpendyInsightsLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            }
            .accessibilityHidden(true)
            .padding(.bottom, 4)
            Text("Spendy")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
                .font(AppTypography.captionMedium)
                .foregroundStyle(SpendyColors.textTertiary)
            Text("Powered by Spendy Intelligence")
                .font(AppTypography.captionMedium)
                .foregroundStyle(SpendyColors.textSecondary)
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
                .font(.footnote.weight(.semibold))
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
            .fill(SpendyColors.settingsCardBackground)
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
        settingsNavigationRow(icon: icon, title: title, value: value, disclosure: "chevron.right")
    }

    private func externalRow(icon: String, title: String, value: String? = nil) -> some View {
        settingsNavigationRow(icon: icon, title: title, value: value, disclosure: "arrow.up.right")
    }

    private func settingsNavigationRow(icon: String, title: String, value: String?, disclosure: String) -> some View {
        SpendyRowContent(spacing: 14, iconWidth: 28) {
            rowIcon(icon)
        } content: {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        } value: {
            HStack(spacing: 8) {
                if let value {
                    Text(value).font(.subheadline)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Image(systemName: disclosure)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private var coffeeSheet: some View {
        NavigationStack {
            ZStack {
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
