//
//  SpendyPillGroupCard.swift
//  Spendy
//
//  Recreated Capsule / Pill Group Card Component matching Apple HIG & Spendy Design Language.
//  Features:
//  - Elevated container surface with rounded corners (24pt)
//  - Header with leading SF icon, title, subtitle & trailing circular action button (arrow.up.right)
//  - Inner list of individual pill/capsule rows with circular icon badges, segmented metadata,
//    monospaced numbers, and disclosure chevrons.
//  - Full Dark Mode, Light Mode & Monochrome Mode support.
//  - Tactile spring press interactions with native haptic feedback.
//

import SwiftUI

// MARK: - Pill Item Model
struct SpendyPillItem: Identifiable, Hashable {
    let id: String
    var title: String
    var subtitle: String?
    var icon: String
    var iconColor: Color?
    var iconContainerColor: Color?
    var trailingValue: String?
    var trailingValueColor: Color?
    var showChevron: Bool
    var action: (() -> Void)?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color? = nil,
        iconContainerColor: Color? = nil,
        trailingValue: String? = nil,
        trailingValueColor: Color? = nil,
        showChevron: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.iconContainerColor = iconContainerColor
        self.trailingValue = trailingValue
        self.trailingValueColor = trailingValueColor
        self.showChevron = showChevron
        self.action = action
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(icon)
        hasher.combine(trailingValue)
        hasher.combine(showChevron)
    }
    
    static func == (lhs: SpendyPillItem, rhs: SpendyPillItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.icon == rhs.icon &&
        lhs.trailingValue == rhs.trailingValue &&
        lhs.showChevron == rhs.showChevron
    }
}

// MARK: - Pill Row Press Style
private struct PillRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - Header Action Press Style
private struct HeaderActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Spendy Pill Group Card (Master Component)
struct SpendyPillGroupCard<HeaderLeading: View, Content: View>: View {
    var title: String
    var subtitle: String?
    var headerActionIcon: String
    var onHeaderAction: (() -> Void)?
    var cornerRadius: CGFloat
    var cardPadding: CGFloat
    var rowSpacing: CGFloat
    
    @ViewBuilder var headerLeading: () -> HeaderLeading
    @ViewBuilder var content: () -> Content
    
    init(
        title: String,
        subtitle: String? = nil,
        headerActionIcon: String = "arrow.up.right",
        cornerRadius: CGFloat = 24,
        cardPadding: CGFloat = 18,
        rowSpacing: CGFloat = 10,
        onHeaderAction: (() -> Void)? = nil,
        @ViewBuilder headerLeading: @escaping () -> HeaderLeading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.headerActionIcon = headerActionIcon
        self.cornerRadius = cornerRadius
        self.cardPadding = cardPadding
        self.rowSpacing = rowSpacing
        self.onHeaderAction = onHeaderAction
        self.headerLeading = headerLeading
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - 1. Card Header
            HStack(alignment: .center, spacing: 10) {
                // Leading Header Visual / Icon
                headerLeading()
                
                // Header Titles
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .default))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12.5, weight: .medium, design: .default))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Trailing Elevated Circular Button (arrow.up.right)
                if let onHeaderAction = onHeaderAction {
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        onHeaderAction()
                    }) {
                        ZStack {
                            Circle()
                                .fill(SpendyColors.elevatedControlFill)
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                            
                            Image(systemName: headerActionIcon)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(SpendyColors.elevatedControlForeground)
                        }
                    }
                    .buttonStyle(HeaderActionPressStyle())
                    .accessibilityLabel("Open \(title) details")
                }
            }
            
            // MARK: - 2. Capsule / Pill Rows Content
            VStack(spacing: rowSpacing) {
                content()
            }
        }
        .padding(cardPadding)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
}

// MARK: - Convenience Initializer with Items Array
extension SpendyPillGroupCard where HeaderLeading == AnyView, Content == ForEach<[SpendyPillItem], String, SpendyPillRow> {
    init(
        title: String,
        subtitle: String? = nil,
        headerIcon: String? = "bolt.fill",
        headerIconColor: Color? = nil,
        headerActionIcon: String = "arrow.up.right",
        items: [SpendyPillItem],
        cornerRadius: CGFloat = 24,
        cardPadding: CGFloat = 18,
        rowSpacing: CGFloat = 10,
        onHeaderAction: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            headerActionIcon: headerActionIcon,
            cornerRadius: cornerRadius,
            cardPadding: cardPadding,
            rowSpacing: rowSpacing,
            onHeaderAction: onHeaderAction,
            headerLeading: {
                if let icon = headerIcon, !icon.isEmpty {
                    return AnyView(
                        Image(systemName: icon)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(headerIconColor ?? SpendyColors.textPrimary)
                            .frame(width: 28, height: 28)
                    )
                } else {
                    return AnyView(EmptyView())
                }
            },
            content: {
                ForEach(items, id: \.id) { item in
                    SpendyPillRow(item: item)
                }
            }
        )
    }
}

// MARK: - Single Pill / Capsule Row Component
struct SpendyPillRow: View {
    let item: SpendyPillItem
    var cornerRadius: CGFloat = 20
    var height: CGFloat = 56
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(item: SpendyPillItem, cornerRadius: CGFloat = 20, height: CGFloat = 56) {
        self.item = item
        self.cornerRadius = cornerRadius
        self.height = height
    }
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            item.action?()
        }) {
            HStack(spacing: 12) {
                // Leading Circular Icon Badge Container
                SpendyIconBadge(
                    sfSymbol: item.icon,
                    color: item.iconColor ?? SpendyColors.textPrimary,
                    size: .small,
                    style: .circle,
                    showCutoutBorder: false
                )
                
                // Middle Titles & Subtitles
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    
                    if let subtitle = item.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 6)
                
                // Trailing Optional Value
                if let trailingValue = item.trailingValue, !trailingValue.isEmpty {
                    Text(trailingValue)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(item.trailingValueColor ?? SpendyColors.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                
                // Trailing Chevron
                if item.showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary.opacity(0.6))
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: height)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(SpendyColors.separator.opacity(0.6), lineWidth: 0.6)
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(PillRowPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.subtitle ?? ""), \(item.trailingValue ?? "")")
    }
}

// MARK: - Concrete Specialized Presets for Spendy

// MARK: 1. AI Spending Insights Pill Card (Direct Recreation of Screenshot for Financial Usage)
struct SpendyAIInsightPillCard: View {
    var title: String = "AI Power Analytics"
    var subtitle: String = "Daily usage"
    var items: [SpendyPillItem]
    var onOpenAnalytics: (() -> Void)? = nil
    
    init(
        title: String = "AI Power Analytics",
        subtitle: String = "Daily usage",
        items: [SpendyPillItem]? = nil,
        onOpenAnalytics: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onOpenAnalytics = onOpenAnalytics
        
        if let customItems = items {
            self.items = customItems
        } else {
            // Default sample items directly inspired by the screenshot
            self.items = [
                SpendyPillItem(
                    title: "Air Conditioner",
                    subtitle: "2 unit  |  18kWh",
                    icon: "air.conditioner.horizontal",
                    iconColor: Color(hex: "#007AFF")
                ),
                SpendyPillItem(
                    title: "Wi-Fi Router",
                    subtitle: "1 unit  |  8kWh",
                    icon: "wifi.router",
                    iconColor: Color(hex: "#34C759")
                ),
                SpendyPillItem(
                    title: "Smart TV",
                    subtitle: "2 unit  |  12kWh",
                    icon: "tv",
                    iconColor: Color(hex: "#FF9500")
                ),
                SpendyPillItem(
                    title: "Humidifier",
                    subtitle: "1 unit  |  2kWh",
                    icon: "humidity",
                    iconColor: Color(hex: "#5856D6")
                )
            ]
        }
    }
    
    var body: some View {
        SpendyPillGroupCard(
            title: title,
            subtitle: subtitle,
            headerIcon: "bolt.fill",
            headerActionIcon: "arrow.up.right",
            items: items,
            onHeaderAction: onOpenAnalytics
        )
    }
}

// MARK: 2. Top Spending Categories Breakdown Pill Card
struct SpendyCategoryPillCard: View {
    @Environment(ExpenseStore.self) private var store
    
    var title: String = "Top Categories"
    var subtitle: String = "This month"
    var limit: Int = 4
    var onOpenAllCategories: (() -> Void)? = nil
    var onSelectCategory: ((Category) -> Void)? = nil
    
    init(
        title: String = "Top Categories",
        subtitle: String = "This month",
        limit: Int = 4,
        onOpenAllCategories: (() -> Void)? = nil,
        onSelectCategory: ((Category) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.limit = limit
        self.onOpenAllCategories = onOpenAllCategories
        self.onSelectCategory = onSelectCategory
    }
    
    private var categoryItems: [SpendyPillItem] {
        let calendar = Calendar.current
        let now = Date()
        
        let monthExpenses = store.transactions.filter { tx in
            tx.type == .expense &&
            calendar.isDate(tx.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate(tx.date, equalTo: now, toGranularity: .year)
        }
        
        let totalMonthSpend = monthExpenses.reduce(0) { $0 + $1.amount }
        
        // Group by category
        var catTotals: [String: (amount: Double, count: Int)] = [:]
        for tx in monthExpenses {
            var current = catTotals[tx.categoryId] ?? (amount: 0, count: 0)
            current.amount += tx.amount
            current.count += 1
            catTotals[tx.categoryId] = current
        }
        
        let sorted = catTotals.sorted { $0.value.amount > $1.value.amount }.prefix(limit)
        
        return sorted.compactMap { catId, data in
            guard let cat = store.categories.first(where: { $0.id == catId }) else { return nil }
            let percent = totalMonthSpend > 0 ? Int(round((data.amount / totalMonthSpend) * 100)) : 0
            let formattedAmount = data.amount.formattedCurrency(symbol: store.currencySymbol)
            
            return SpendyPillItem(
                id: cat.id,
                title: cat.label,
                subtitle: "\(data.count) \(data.count == 1 ? "expense" : "expenses")  •  \(percent)% of total",
                icon: cat.sfSymbol,
                iconColor: cat.color,
                trailingValue: formattedAmount,
                showChevron: true,
                action: {
                    onSelectCategory?(cat)
                }
            )
        }
    }
    
    var body: some View {
        if !categoryItems.isEmpty {
            SpendyPillGroupCard(
                title: title,
                subtitle: subtitle,
                headerIcon: "chart.bar.fill",
                headerActionIcon: "arrow.up.right",
                items: categoryItems,
                onHeaderAction: onOpenAllCategories
            )
        }
    }
}

// MARK: 3. Active Subscriptions & Bills Pill Card
struct SpendySubscriptionPillCard: View {
    @Environment(ExpenseStore.self) private var store
    
    var title: String = "Active Subscriptions"
    var subtitle: String = "Monthly commitments"
    var limit: Int = 4
    var onOpenSubscriptions: (() -> Void)? = nil
    var onSelectSubscription: ((Subscription) -> Void)? = nil
    
    init(
        title: String = "Active Subscriptions",
        subtitle: String = "Monthly commitments",
        limit: Int = 4,
        onOpenSubscriptions: (() -> Void)? = nil,
        onSelectSubscription: ((Subscription) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.limit = limit
        self.onOpenSubscriptions = onOpenSubscriptions
        self.onSelectSubscription = onSelectSubscription
    }
    
    private var subscriptionItems: [SpendyPillItem] {
        let activeSubs = store.subscriptions
            .filter { !$0.isCancelled && !$0.isPaused }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .prefix(limit)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return activeSubs.map { sub in
            let billingDay = calendar.startOfDay(for: sub.nextBillingDate)
            let daysLeft = calendar.dateComponents([.day], from: today, to: billingDay).day ?? 0
            
            let timingText: String = {
                if daysLeft == 0 { return "Due today" }
                if daysLeft == 1 { return "Due tomorrow" }
                if daysLeft < 0 { return "Overdue" }
                return "Renews in \(daysLeft)d"
            }()
            
            let formattedAmount = sub.amount.formattedCurrency(symbol: store.currencySymbol)
            
            return SpendyPillItem(
                id: sub.id.uuidString,
                title: sub.name,
                subtitle: "\(sub.cycle.rawValue.capitalized)  •  \(timingText)",
                icon: sub.sfSymbol.isEmpty ? "repeat" : sub.sfSymbol,
                iconColor: sub.color,
                trailingValue: formattedAmount,
                showChevron: true,
                action: {
                    onSelectSubscription?(sub)
                }
            )
        }
    }
    
    var body: some View {
        if !subscriptionItems.isEmpty {
            SpendyPillGroupCard(
                title: title,
                subtitle: subtitle,
                headerIcon: "repeat.circle.fill",
                headerActionIcon: "arrow.up.right",
                items: subscriptionItems,
                onHeaderAction: onOpenSubscriptions
            )
        }
    }
}

// MARK: 4. Multi-Account Assets Pill Card
struct SpendyAccountPillCard: View {
    @Environment(ExpenseStore.self) private var store
    
    var title: String = "Accounts & Assets"
    var subtitle: String = "Liquid balances"
    var hideBalance: Bool = false
    var onOpenAccounts: (() -> Void)? = nil
    var onSelectAccount: ((Account) -> Void)? = nil
    
    init(
        title: String = "Accounts & Assets",
        subtitle: String = "Liquid balances",
        hideBalance: Bool = false,
        onOpenAccounts: (() -> Void)? = nil,
        onSelectAccount: ((Account) -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.hideBalance = hideBalance
        self.onOpenAccounts = onOpenAccounts
        self.onSelectAccount = onSelectAccount
    }
    
    private var accountItems: [SpendyPillItem] {
        store.accounts.map { account in
            let balance = store.balance(for: account.id)
            let formattedBalance = hideBalance ? "••••" : balance.formattedCurrency(symbol: store.currencySymbol)
            let txCount = store.transactions.filter { $0.accountId == account.id }.count
            
            return SpendyPillItem(
                id: account.id,
                title: account.label,
                subtitle: "\(account.type.rawValue.capitalized)  •  \(txCount) \(txCount == 1 ? "txn" : "txns")",
                icon: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                iconColor: account.color,
                trailingValue: formattedBalance,
                showChevron: true,
                action: {
                    onSelectAccount?(account)
                }
            )
        }
    }
    
    var body: some View {
        if !accountItems.isEmpty {
            SpendyPillGroupCard(
                title: title,
                subtitle: subtitle,
                headerIcon: "creditcard.fill",
                headerActionIcon: "arrow.up.right",
                items: accountItems,
                onHeaderAction: onOpenAccounts
            )
        }
    }
}

// MARK: - Previews
#Preview("Spendy Pill Cards") {
    ZStack {
        SpendyColors.appBackground
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 20) {
                // Exact recreation of image
                SpendyAIInsightPillCard(
                    title: "AI Power Analytics",
                    subtitle: "Daily usage"
                )
                
                // Spendy Financial Adaptation: Subscriptions
                SpendyPillGroupCard(
                    title: "Active Subscriptions",
                    subtitle: "4 recurring plans",
                    headerIcon: "repeat.circle.fill",
                    headerActionIcon: "arrow.up.right",
                    items: [
                        SpendyPillItem(
                            title: "Netflix",
                            subtitle: "Premium 4K  •  Renews in 2d",
                            icon: "play.tv.fill",
                            iconColor: Color(hex: "#FF3B30"),
                            trailingValue: "$19.99"
                        ),
                        SpendyPillItem(
                            title: "Spotify",
                            subtitle: "Family Plan  •  Renews in 5d",
                            icon: "music.note.house.fill",
                            iconColor: Color(hex: "#34C759"),
                            trailingValue: "$16.99"
                        ),
                        SpendyPillItem(
                            title: "iCloud+ Storage",
                            subtitle: "2 TB Cloud  •  Renews in 12d",
                            icon: "icloud.fill",
                            iconColor: Color(hex: "#007AFF"),
                            trailingValue: "$9.99"
                        ),
                        SpendyPillItem(
                            title: "Gym Membership",
                            subtitle: "Equinox All-Access  •  Due today",
                            icon: "figure.run",
                            iconColor: Color(hex: "#AF52DE"),
                            trailingValue: "$45.00"
                        )
                    ]
                ) {
                    print("Tapped header action")
                }
            }
            .padding(20)
        }
    }
}
