//
//  SpendyWidgetViews.swift
//  Spendy
//
//  Glanceable Home Screen widgets with a quiet monochrome visual language.
//

import AppIntents
import SwiftUI
import UIKit
import WidgetKit

enum SpendyWidgetPalette {
    static let canvas = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 18 / 255, green: 18 / 255, blue: 20 / 255, alpha: 1)
            : UIColor.white
    })
    static let text = Color(uiColor: .label)
    static let secondary = Color(uiColor: .secondaryLabel)
    static let tertiary = Color(uiColor: .tertiaryLabel)
    static let fill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.10)
            : UIColor(white: 0, alpha: 0.06)
    })
    static let line = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.13)
            : UIColor(white: 0, alpha: 0.10)
    })
    static let inverse = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? .black : .white
    })
    static let expense = Color(uiColor: .systemRed)
    static let income = Color(uiColor: .systemGreen)
}

struct WidgetCategoryBadge: View {
    let symbol: String
    let colorHex: String
    var name: String = ""
    var size: CGFloat = 44

    var body: some View {
        SpendyIconBadge(sfSymbol: symbol, color: SpendyHexColor.color(from: colorHex),
            size: .medium, style: .circle, monogramName: name)
            .modifier(SpendyWidgetBadgeAppearance())
            .scaleEffect(size / 44)
            .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct SpendyWidgetAmount: View {
    let amount: Double
    let symbol: String
    var size: CGFloat = 28
    var color: Color = SpendyWidgetPalette.text

    var body: some View {
        Text(SpendyWidgetFormat.amount(amount, symbol: symbol, decimals: amount == 0 || abs(amount) >= 100 ? 0 : 2))
            .spendyNumberFont(size: size, weight: .heavy)
        .contentTransition(.numericText())
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.58)
    }
}

struct SpendyWidgetAddButton: View {
    var body: some View {
        Button(intent: QuickAddExpenseIntent()) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SpendyWidgetPalette.text)
                .frame(width: 28, height: 28)
                .background(Circle().fill(SpendyWidgetPalette.text.opacity(0.10)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick add")
    }
}

struct SpendyWeekBars: View {
    let days: [WidgetDaySpending]
    let accentHex: String
    var height: CGFloat = 52

    var body: some View {
        let maxVal = max(days.map(\.amount).max() ?? 0, 1)
        let highlightedIndex = days.lastIndex(where: { $0.isToday && $0.amount > 0 })
            ?? days.firstIndex(where: { $0.amount == maxVal && $0.amount > 0 })
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let highlighted = index == highlightedIndex
                VStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(highlighted ? SpendyWidgetPalette.text : day.amount > 0 ? SpendyWidgetPalette.text.opacity(0.38) : SpendyWidgetPalette.fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: max(3, (day.amount / maxVal) * height))
                        .frame(height: height, alignment: .bottom)
                        .widgetAccentable(highlighted)
                    Text(day.dayLabel)
                        .font(.system(size: 11, weight: day.isToday || highlighted ? .bold : .medium))
                        .foregroundStyle(day.isToday || highlighted ? SpendyWidgetPalette.text : SpendyWidgetPalette.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.dayLabel), \(SpendyWidgetFormat.amount(day.amount, symbol: "", decimals: 0)) spent\(day.isToday ? ", today" : "")")
            }
        }
        .frame(height: height + 16)
    }
}

struct SpendyMiniRing: View {
    let progress: Double
    var size: CGFloat = 86
    var lineWidth: CGFloat = 9
    var color: Color = SpendyWidgetPalette.income

    var body: some View {
        ZStack {
            Circle()
                .stroke(SpendyWidgetPalette.fill, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                .stroke(
                    progress > 0.9 ? SpendyWidgetPalette.expense : color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

extension View {
    // Only the container owns the canvas. WidgetKit removes it in Clear,
    // tinted and StandBy appearances; an ordinary background becomes a block.
    func spendyWidgetChrome(transparent: Bool = false) -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(for: .widget) {
                if !transparent { SpendyWidgetPalette.canvas }
            }
    }
}

private struct WidgetSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .default))
            .foregroundStyle(SpendyWidgetPalette.secondary)
            .lineLimit(1)
    }
}

private struct WidgetActionLink: View {
    let title: String
    let symbol: String
    let destination: String

    var body: some View {
        Link(destination: URL(string: destination)!) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .medium))
                    .widgetAccentable()
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .lineLimit(1)
            }
            .foregroundStyle(SpendyWidgetPalette.text)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .accessibilityLabel(title)
    }
}

struct SpendyQuickActionsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot
    var previewFamily: WidgetFamily? = nil

    private var isSmall: Bool { (previewFamily ?? family) == .systemSmall }

    private var actions: some View {
        HStack(spacing: 0) {
            WidgetActionLink(title: "Add", symbol: "plus", destination: "spendy://quick-add")
            WidgetActionLink(title: "Scan", symbol: "camera", destination: "spendy://scan")
            WidgetActionLink(title: "Trends", symbol: "arrow.up.right", destination: "spendy://analytics")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetSectionLabel(text: "Quick actions")
            Spacer(minLength: 8)
            if isSmall {
                actions
            } else {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        WidgetSectionLabel(text: "Spent today")
                        SpendyWidgetAmount(amount: snapshot.todayTotal, symbol: snapshot.currencySymbol, size: 28)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    actions.frame(maxWidth: .infinity)
                }
            }
            Spacer(minLength: 8)
        }
        .spendyWidgetChrome(transparent: glassPreview)
    }
}

private struct WidgetBudgetRail: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(SpendyWidgetPalette.fill)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(SpendyWidgetPalette.text)
                        .frame(width: geometry.size.width * min(1, max(0, progress)))
                        .widgetAccentable()
                }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}

private struct WidgetComparisonLine: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        if let prior = snapshot.previousMonthToDateTotal {
            let difference = snapshot.monthTotal - prior
            HStack(spacing: 4) {
                Image(systemName: difference > 0 ? "arrow.up.right" : difference < 0 ? "arrow.down.right" : "equal")
                    .font(.system(size: 11, weight: .bold))
                Text(difference == 0
                     ? "Same as last month"
                     : "\(SpendyWidgetFormat.compactAmount(abs(difference), symbol: snapshot.currencySymbol)) \(difference > 0 ? "more" : "less") vs last month")
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(SpendyWidgetPalette.secondary)
            .accessibilityLabel("\(SpendyWidgetFormat.amount(abs(difference), symbol: snapshot.currencySymbol, decimals: 0)) \(difference > 0 ? "more" : difference < 0 ? "less" : "difference") than the same point last month")
        }
    }
}

// MARK: - Small · Today
// Today’s amount with a compact seven-day context.

private struct SpendyWidgetGlassPreviewKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var spendyWidgetGlassPreview: Bool {
        get { self[SpendyWidgetGlassPreviewKey.self] }
        set { self[SpendyWidgetGlassPreviewKey.self] = newValue }
    }
}

struct SpendySmallWidgetView: View {
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetSectionLabel(text: "Today")
            SpendyWidgetAmount(amount: snapshot.todayTotal, symbol: snapshot.currencySymbol, size: 28)
                .padding(.top, 6)
            Spacer(minLength: 8)
            SpendyWeekBars(days: snapshot.weeklySpending, accentHex: "", height: 33)
                .accessibilityLabel("Spending over the last seven days")
        }
        .spendyWidgetChrome(transparent: glassPreview)
        .widgetURL(URL(string: "spendy://home"))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Budget arc (same capsule-segment language as BudgetGaugeView)

struct SpendyBudgetArc: View {
    let progress: Double?
    var radius: CGFloat = 58
    var showsPercentage = true

    var body: some View {
        ZStack {
            SpendyBudgetArcDrawing(progress: progress, lineWidth: 8,
                tint: SpendyWidgetPalette.text, track: SpendyWidgetPalette.text.opacity(0.09))
                .widgetAccentable()
            if showsPercentage {
                Text(progress.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "—")
                    .spendyNumberFont(size: radius * 0.40, weight: .semibold)
                    .foregroundStyle(SpendyWidgetPalette.text)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .accessibilityLabel(progress.map { "Budget used, \($0.formatted(.percent.precision(.fractionLength(0))))" } ?? "No active budget")
    }
}

struct SpendyBudgetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot
    var previewFamily: WidgetFamily? = nil

    private var resolvedFamily: WidgetFamily { previewFamily ?? family }
    private var isSmall: Bool { resolvedFamily == .systemSmall }
    private var amount: Double { snapshot.budgetOverage > 0 ? snapshot.budgetOverage : snapshot.remainingBudget }

    private var balance: some View {
        VStack(alignment: isSmall ? .center : .leading, spacing: 3) {
            SpendyWidgetAmount(amount: amount, symbol: snapshot.currencySymbol, size: isSmall ? 24 : 32)
            WidgetSectionLabel(text: snapshot.budgetOverage > 0 ? "over budget" : "left to spend")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetSectionLabel(text: "Budget")
            if snapshot.budgetTotal > 0 {
                Spacer(minLength: 0)
                if isSmall {
                    ZStack {
                        SpendyBudgetArc(progress: snapshot.budgetProgress, radius: 54, showsPercentage: false)
                        balance
                            .padding(.horizontal, 22)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100, alignment: .top)
                } else {
                    HStack(spacing: 16) {
                        balance.frame(maxWidth: .infinity, alignment: .leading)
                        SpendyBudgetArc(progress: snapshot.budgetProgress, radius: 39)
                    }
                }
                Spacer(minLength: 0)
                HStack {
                    WidgetSectionLabel(text: "\(snapshot.daysLeft) \(snapshot.daysLeft == 1 ? "day" : "days") left")
                    if !isSmall {
                        Spacer(minLength: 4)
                        WidgetSectionLabel(text: "of \(SpendyWidgetFormat.compactAmount(snapshot.budgetTotal, symbol: snapshot.currencySymbol))")
                    }
                }
            } else {
                Spacer(minLength: 8)
                Image(systemName: "circle.dashed")
                    .font(.system(size: 28))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                    .accessibilityHidden(true)
                Text("Set a budget")
                    .font(.headline)
                    .foregroundStyle(SpendyWidgetPalette.text)
                    .padding(.top, 8)
                WidgetSectionLabel(text: "Tap to get started")
                Spacer(minLength: 0)
            }
        }
        .spendyWidgetChrome(transparent: glassPreview)
        .widgetURL(URL(string: "spendy://budget"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snapshot.budgetTotal > 0
            ? "Budget \(snapshot.budgetOverage > 0 ? "over by" : "remaining") \(SpendyWidgetFormat.amount(amount, symbol: snapshot.currencySymbol)), \(snapshot.daysLeft) days left"
            : "Set a budget in Spendy")
    }
}

struct SpendyCategoryFocusView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot
    let category: CategoryAppEntity?
    var previewFamily: WidgetFamily? = nil

    private var resolvedFamily: WidgetFamily { previewFamily ?? family }
    private var match: WidgetCategorySpend? {
        snapshot.categorySpending.first(where: { $0.id == category?.id })
            ?? (category == nil ? snapshot.topCategories.first : nil)
    }

    var body: some View {
        let name = match?.name ?? category?.name ?? "Category"
        let symbol = match?.sfSymbol ?? category?.sfSymbol ?? "tag"
        let amount = match?.amount ?? 0
        let share = snapshot.monthTotal > 0 ? amount / snapshot.monthTotal : 0
        let expanded = resolvedFamily == .systemLarge || resolvedFamily == .systemExtraLarge
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                WidgetCategoryBadge(symbol: symbol, colorHex: "", name: name, size: 30)
                Text(name).font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpendyWidgetPalette.text).lineLimit(1)
            }
            Spacer(minLength: 0)
            SpendyWidgetAmount(amount: amount, symbol: snapshot.currencySymbol, size: expanded ? 44 : 28)
            WidgetSectionLabel(text: "This month")
            Spacer(minLength: 0)
            WidgetBudgetRail(progress: share)
            WidgetSectionLabel(text: "\(share.formatted(.percent.precision(.fractionLength(0)))) of spending")
            if expanded {
                Divider().padding(.vertical, 12)
                WidgetSectionLabel(text: "All spending this month")
                SpendyWidgetAmount(amount: snapshot.monthTotal, symbol: snapshot.currencySymbol, size: 24)
            }
        }
        .spendyWidgetChrome(transparent: glassPreview)
        .widgetURL((match?.id ?? category?.id).flatMap { URL(string: "spendy://category/\($0)") } ?? URL(string: "spendy://analytics"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(SpendyWidgetFormat.amount(amount, symbol: snapshot.currencySymbol)) this month, \(share.formatted(.percent.precision(.fractionLength(0)))) of spending")
    }
}

struct SpendyConfiguredWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: SpendyWidgetSnapshot
    let configuration: SpendyHomeWidgetIntent

    var body: some View {
        switch configuration.focus {
        case .budget:
            SpendyBudgetWidgetView(snapshot: snapshot)
        case .week:
            SpendyWeekWidgetView(snapshot: snapshot)
        case .category:
            SpendyCategoryFocusView(snapshot: snapshot, category: configuration.category)
        default:
            if family == .systemMedium {
                SpendyMediumWeekWidgetView(snapshot: snapshot)
            } else if family == .systemLarge || family == .systemExtraLarge {
                SpendyLargeOverviewWidgetView(snapshot: snapshot)
            } else {
                SpendySmallWidgetView(snapshot: snapshot)
            }
        }
    }
}

// MARK: - Medium · Week
// Huge today number. Chunky 7-day bars. Nothing else.

struct SpendyMediumWeekWidgetView: View {
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot

    private var weekTotal: Double { snapshot.weeklySpending.reduce(0) { $0 + $1.amount } }

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                WidgetSectionLabel(text: "Today")
                Spacer(minLength: 8)
                SpendyWidgetAmount(amount: snapshot.todayTotal, symbol: snapshot.currencySymbol, size: 30)
                Spacer(minLength: 8)
                Text("\(SpendyWidgetFormat.compactAmount(weekTotal, symbol: snapshot.currencySymbol)) in 7 days")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 0) {
                WidgetSectionLabel(text: "Last 7 days")
                Spacer(minLength: 7)
                SpendyWeekBars(days: snapshot.weeklySpending, accentHex: "", height: 60)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .spendyWidgetChrome(transparent: glassPreview)
        .widgetURL(URL(string: "spendy://analytics"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Spent today \(SpendyWidgetFormat.amount(snapshot.todayTotal, symbol: snapshot.currencySymbol)). Spent over the last seven days \(SpendyWidgetFormat.amount(weekTotal, symbol: snapshot.currencySymbol)).")
    }
}

// MARK: - Medium · Activity
// Two rows. Big icons. Lots of air.

struct SpendyMediumActivityWidgetView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent")
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                Spacer()
                SpendyWidgetAddButton()
            }

            Spacer(minLength: 14)

            if snapshot.recentTransactions.isEmpty {
                Spacer(minLength: 0)
                Text("Nothing yet")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 16) {
                    ForEach(snapshot.recentTransactions.prefix(2)) { item in
                        HStack(spacing: 14) {
                            WidgetCategoryBadge(
                                symbol: item.categorySymbol,
                                colorHex: item.categoryColorHex,
                                name: item.title,
                                size: 28
                            )
                            Text(item.title)
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundStyle(SpendyWidgetPalette.text)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(item.isExpense ? "−" : "+")\(SpendyWidgetFormat.compactAmount(item.amount, symbol: snapshot.currencySymbol))")
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .monospacedDigit()
                                .foregroundStyle(SpendyWidgetPalette.text)
                                .lineLimit(1)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .spendyWidgetChrome()
    }
}

// MARK: - Medium · Categories
// Three categories, each with one identity and one amount.

struct SpendyMediumCategoriesWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var previewFamily: WidgetFamily? = nil
    @Environment(\.spendyWidgetGlassPreview) private var glassPreview
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                WidgetSectionLabel(text: "Where it went")
                Spacer(minLength: 8)
                Text("This month")
                    .font(.system(size: 11))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
            }
            Spacer(minLength: 9)

            if snapshot.topCategories.isEmpty {
                Text("No spending yet")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                Spacer(minLength: 0)
            } else {
                if (previewFamily ?? family) == .systemLarge || (previewFamily ?? family) == .systemExtraLarge {
                    SpendyCategoryRanking(snapshot: snapshot)
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(snapshot.topCategories.prefix(3)) { category in
                            VStack(spacing: 6) {
                                WidgetCategoryBadge(
                                    symbol: category.sfSymbol,
                                    colorHex: category.colorHex,
                                    name: category.name,
                                    size: 36
                                )

                                Text(category.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(SpendyWidgetPalette.secondary)
                                    .lineLimit(1)

                                Text(SpendyWidgetFormat.compactAmount(category.amount, symbol: snapshot.currencySymbol))
                                    .font(.system(size: 12, weight: .bold, design: .default))
                                    .monospacedDigit()
                                    .foregroundStyle(SpendyWidgetPalette.text)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(category.name), \(SpendyWidgetFormat.amount(category.amount, symbol: snapshot.currencySymbol))")
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .spendyWidgetChrome(transparent: glassPreview)
        .widgetURL(URL(string: "spendy://analytics"))
    }
}

// MARK: - Large · Monthly brief

struct SpendyMonthlyBriefColumn: View {
    let snapshot: SpendyWidgetSnapshot
    private var weekTotal: Double { snapshot.weeklySpending.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetSectionLabel(text: "Monthly brief")
            SpendyWidgetAmount(amount: snapshot.monthTotal, symbol: snapshot.currencySymbol, size: 36)
                .padding(.top, 7)
            WidgetComparisonLine(snapshot: snapshot)
                .padding(.top, 3)

            Rectangle().fill(SpendyWidgetPalette.line).frame(height: 1)
                .padding(.vertical, 13)

            HStack {
                WidgetSectionLabel(text: "Last 7 days")
                Spacer(minLength: 6)
                Text(SpendyWidgetFormat.compactAmount(weekTotal, symbol: snapshot.currencySymbol))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
            }
            SpendyWeekBars(days: snapshot.weeklySpending, accentHex: "", height: 62)
                .padding(.top, 9)

            Rectangle().fill(SpendyWidgetPalette.line).frame(height: 1)
                .padding(.vertical, 13)

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    WidgetSectionLabel(text: "Top category")
                    if let top = snapshot.topCategories.first {
                        HStack(spacing: 8) {
                            WidgetCategoryBadge(
                                symbol: top.sfSymbol,
                                colorHex: top.colorHex,
                                name: top.name,
                                size: 32
                            )
                            Text(top.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SpendyWidgetPalette.text)
                                .lineLimit(1)
                        }
                        Text("\(Int((top.amount / max(snapshot.monthTotal, 1) * 100).rounded()))% of spending")
                            .font(.system(size: 11))
                            .foregroundStyle(SpendyWidgetPalette.secondary)
                    } else {
                        Text("No expenses yet")
                            .font(.system(size: 12))
                            .foregroundStyle(SpendyWidgetPalette.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle().fill(SpendyWidgetPalette.line).frame(width: 1, height: 49)

                VStack(alignment: .leading, spacing: 4) {
                    WidgetSectionLabel(text: "Budget room")
                    if snapshot.budgetTotal > 0 {
                        Text(SpendyWidgetFormat.compactAmount(snapshot.budgetOverage > 0 ? snapshot.budgetOverage : snapshot.remainingBudget, symbol: snapshot.currencySymbol))
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundStyle(SpendyWidgetPalette.text)
                            .lineLimit(1).minimumScaleFactor(0.65)
                        WidgetSectionLabel(text: snapshot.budgetOverage > 0 ? "over budget" : "left to spend")
                    } else {
                        Text("Not set")
                            .font(.system(size: 12))
                            .foregroundStyle(SpendyWidgetPalette.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Lock Screen

struct SpendyAccessoryCircularView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(spacing: 3) {
            Text("Today").font(.system(size: 11, weight: .medium))
            Text(SpendyWidgetFormat.compactAmount(snapshot.todayTotal, symbol: snapshot.currencySymbol))
                .font(.system(size: 14, weight: .bold, design: .default))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
        .widgetURL(URL(string: "spendy://home"))
    }
}

struct SpendyAccessoryRectangularView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.right")
                .font(.title2.weight(.semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Today \(SpendyWidgetFormat.compactAmount(snapshot.todayTotal, symbol: snapshot.currencySymbol))")
                    .font(.headline.monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("Month \(SpendyWidgetFormat.compactAmount(snapshot.monthTotal, symbol: snapshot.currencySymbol))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
        .widgetURL(URL(string: "spendy://home"))
    }
}

struct SpendyAccessoryInlineView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        Text("\(Image(systemName: "arrow.up.right")) \(SpendyWidgetFormat.compactAmount(snapshot.todayTotal, symbol: snapshot.currencySymbol)) today")
            .containerBackground(for: .widget) { Color.clear }
            .widgetURL(URL(string: "spendy://home"))
    }
}
