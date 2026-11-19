import SwiftUI
import TipKit

/// Home actions use the navigation bar's system glass and interaction behavior.
struct HomeNavigationHeader: ToolbarContent {
    @Environment(ExpenseStore.self) private var store
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

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: onSettings) {
                HStack(spacing: 8) {
                    avatar
                    Text(profileName).lineLimit(1)
                }
            }
            .accessibilityLabel("Profile, \(profileName). Opens settings.")
            .accessibilityIdentifier("home-profile")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Analytics and statistics", systemImage: SFIcons.tabAnalytics, action: onAnalytics)
                .popoverTip(analyticsTip)
            Menu("More actions", systemImage: "ellipsis") {
                Button("Budget", systemImage: "target", action: onBudget)
                Button("Select Spending Month", systemImage: "calendar", action: onSelectSpendingMonth)
                Button("Currency Converter", systemImage: "arrow.left.arrow.right", action: onConverter)
                Divider()
                Button(hideBalance ? "Show Amounts" : "Hide Amounts",
                       systemImage: hideBalance ? SFIcons.eyeSlash : SFIcons.eye) {
                    hideBalance.toggle()
                }
            }
            .accessibilityHint("Budget, currency converter, and amount visibility")
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
