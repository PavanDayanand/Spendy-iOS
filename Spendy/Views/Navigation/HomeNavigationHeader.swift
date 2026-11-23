import SwiftUI
import TipKit

/// Home actions use the navigation bar's system glass and interaction behavior.
struct HomeNavigationHeader: ToolbarContent {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.spendyUsesSystemNavigation) private var usesSystemNavigation
    @Binding var hideBalance: Bool
    var analyticsTip: HomeAnalyticsTip? = nil
    let onSettings: () -> Void
    let onAnalytics: () -> Void
    let onBudget: () -> Void
    let onConverter: () -> Void
    let onSelectSpendingMonth: () -> Void

    private var profileName: String {
        let name = store.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Personal" : name
    }

    private var profilePillName: String {
        let words = profileName.split(maxSplits: 8, whereSeparator: \.isWhitespace)
        return words.count > 8 ? words.prefix(8).joined(separator: " ") + "…" : profileName
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if usesSystemNavigation {
                Button("Settings", systemImage: "person.crop.circle", action: onSettings)
                    .accessibilityLabel("Profile, \(profileName). Opens settings.")
                    .accessibilityIdentifier("home-profile")
            } else {
                Button(action: onSettings) {
                    HStack(spacing: 8) {
                        avatar
                        Text(profilePillName)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 112, alignment: .leading)
                    }
                }
                .accessibilityLabel("Profile, \(profileName). Opens settings.")
                .accessibilityIdentifier("home-profile")
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Analytics and statistics", systemImage: SFIcons.tabAnalytics, action: onAnalytics)
                .popoverTip(analyticsTip)
            if !usesSystemNavigation {
                Menu("More actions", systemImage: "ellipsis") { moreActions }
                    .accessibilityHint("Budget, currency converter, and amount visibility")
            }

        }
        if usesSystemNavigation {
            if #available(iOS 27.0, *) {
                ToolbarOverflowMenu { moreActions }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("More actions", systemImage: "ellipsis") { moreActions }
                }
            }
        }
    }

    @ViewBuilder private var moreActions: some View {
                Button("Budget", systemImage: "target", action: onBudget)
                Button("Select Spending Month", systemImage: "calendar", action: onSelectSpendingMonth)
                Button("Currency Converter", systemImage: "arrow.left.arrow.right", action: onConverter)
                Divider()
                Button(hideBalance ? "Show Amounts" : "Hide Amounts",
                       systemImage: hideBalance ? SFIcons.eyeSlash : SFIcons.eye) {
                    hideBalance.toggle()
                }
    }

    private var avatar: some View {
        ZStack {
            if let data = store.profileImageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            } else {
                Circle().fill(SpendyColors.textPrimary)
                if let symbol = store.profileIconSymbol, !symbol.isEmpty {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.inverseText)
                } else {
                    Text(String(profileName.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(SpendyColors.inverseText)
                }
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }

}
