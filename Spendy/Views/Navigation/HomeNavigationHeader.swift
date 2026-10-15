import SwiftUI

/// Persistent controls for Home and its transaction browser.
struct HomeNavigationHeader: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isShowingTransactions: Bool
    @Binding var filtersExpanded: Bool
    @Binding var hideBalance: Bool
    let namespace: Namespace.ID
    let onBack: () -> Void
    let onSettings: () -> Void
    let onAnalytics: () -> Void
    let onBudget: () -> Void
    let onConverter: () -> Void

    private var profileName: String {
        let name = store.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Personal" : name
    }

    var body: some View {
        SpendyGlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                if isShowingTransactions {
                    GlassCircleButton(icon: "chevron.left", size: 44, iconSize: 15,
                        accessibilityLabel: "Back", morphID: "topControl_left",
                        namespace: namespace, action: onBack)
                        .accessibilityIdentifier("home-transactions-back")
                } else {
                    profileButton
                }

                Spacer(minLength: 0)

                if isShowingTransactions {
                    Text("All Transactions")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                    Button {
                        HapticsManager.shared.trigger(.selection)
                        filtersExpanded.toggle()
                    } label: {
                        Image(systemName: filtersExpanded ? "xmark" : "line.3.horizontal.decrease")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(GlassCirclePressStyle())
                    .nativeLiquidGlassCircle(isInteractive: true)
                    .glassMorphID("topControl_right", in: namespace)
                    .accessibilityLabel(filtersExpanded ? "Hide transaction filters" : "Show transaction filters")
                    .accessibilityValue(filtersExpanded ? "Expanded" : "Collapsed")
                    .accessibilityIdentifier("home-transactions-filters")
                } else {
                    homeActions
                }
            }
            .frame(height: 44)
            .foregroundStyle(SpendyColors.textPrimary)
            .animation(reduceMotion ? nil : AppMotion.fluidSpring, value: isShowingTransactions)
            .animation(reduceMotion ? nil : AppMotion.fluidSpring, value: filtersExpanded)
        }
    }

    private var profileButton: some View {
        Button {
            HapticsManager.shared.trigger(.light)
            onSettings()
        } label: {
            HStack(spacing: 8) {
                avatar
                Text(profileName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.leading, 5)
            .padding(.trailing, 14)
            .frame(height: 44)
        }
        .buttonStyle(GlassCirclePressStyle())
        .nativeLiquidGlassCapsule(isInteractive: true)
        .glassMorphID("topControl_left", in: namespace)
        .accessibilityLabel("Profile, \(profileName). Opens settings.")
        .accessibilityIdentifier("home-profile")
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

    private var homeActions: some View {
        HStack(spacing: 0) {
            Button {
                HapticsManager.shared.trigger(.selection)
                onAnalytics()
            } label: {
                Image(systemName: SFIcons.tabAnalytics)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(GlassCirclePressStyle())
            .accessibilityLabel("Analytics and statistics")

            Rectangle().fill(SpendyColors.separator)
                .frame(width: 1, height: 18)
                .accessibilityHidden(true)

            Menu {
                Button("Budget", systemImage: "target", action: onBudget)
                Button("Currency Converter", systemImage: "arrow.left.arrow.right", action: onConverter)
                Divider()
                Button(hideBalance ? "Show Amounts" : "Hide Amounts",
                       systemImage: hideBalance ? SFIcons.eyeSlash : SFIcons.eye) {
                    HapticsManager.shared.trigger(.selection)
                    hideBalance.toggle()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("More actions")
            .accessibilityHint("Budget, currency converter, and amount visibility")
        }
        .nativeLiquidGlassCapsule(isInteractive: true)
        .glassMorphID("topControl_right", in: namespace)
    }
}
