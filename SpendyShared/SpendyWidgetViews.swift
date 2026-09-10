//
//  SpendyWidgetViews.swift
//  Spendy
//
//  Glanceable widgets: big category icons, one number, padding on every side.
//

import AppIntents
import SwiftUI
import UIKit
import WidgetKit

enum SpendyWidgetPalette {
    static let canvas = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 26 / 255, green: 26 / 255, blue: 26 / 255, alpha: 1)
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
    static let inverse = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? .black : .white
    })
    static let expense = Color(uiColor: .systemRed)
    static let income = Color(uiColor: .systemGreen)
}

struct WidgetCategoryBadge: View {
    let symbol: String
    let colorHex: String
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(SpendyHexColor.color(from: colorHex))
            Image(systemName: symbol.isEmpty ? "tag.fill" : symbol)
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundStyle(SpendyHexColor.glyphColor(from: colorHex))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct SpendyWidgetAmount: View {
    let amount: Double
    let symbol: String
    var size: CGFloat = 32
    var color: Color = SpendyWidgetPalette.text

    private var parts: (integer: String, decimal: String) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = abs(amount) >= 100 ? 0 : 2
        let raw = formatter.string(from: NSNumber(value: abs(amount))) ?? "0"
        let bits = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let decimals = bits.count > 1 ? ".\(bits[1])" : ""
        return (String(bits.first ?? "0"), decimals)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(symbol)
                .font(.system(size: size * 0.58, weight: .bold, design: .monospaced))
            Text(parts.integer)
                .font(.system(size: size, weight: .heavy, design: .monospaced))
                .monospacedDigit()
            if !parts.decimal.isEmpty {
                Text(parts.decimal)
                    .font(.system(size: max(13, size * 0.46), weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(color.opacity(0.55))
            }
        }
        .foregroundStyle(color)
        .tracking(-1.0)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

struct SpendyWidgetAddButton: View {
    var body: some View {
        Button(intent: QuickAddExpenseIntent()) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SpendyWidgetPalette.inverse)
                .frame(width: 28, height: 28)
                .background(Circle().fill(SpendyWidgetPalette.text))
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
        let maxVal = max(days.map(\.amount).max() ?? 1, 1)
        let accent = SpendyHexColor.color(from: accentHex)
        HStack(alignment: .bottom, spacing: 7) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(day.isToday ? accent : accent.opacity(0.22))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(8, (day.amount / maxVal) * height))
                    Text(day.dayLabel)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(day.isToday ? SpendyWidgetPalette.text : SpendyWidgetPalette.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height + 18)
        .accessibilityHidden(true)
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

private extension View {
    func spendyWidgetChrome() -> some View {
        self
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(SpendyWidgetPalette.canvas)
            .containerBackground(for: .widget) {
                SpendyWidgetPalette.canvas
            }
    }
}

// MARK: - Small · Today
// One icon, one number. Same structure as the airy reference cards.

struct SpendySmallWidgetView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetCategoryBadge(
                symbol: snapshot.topCategorySymbol,
                colorHex: snapshot.topCategoryColorHex,
                size: 44
            )

            Spacer(minLength: 12)

            Text("Today")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SpendyWidgetPalette.secondary)

            SpendyWidgetAmount(
                amount: snapshot.todayTotal,
                symbol: snapshot.currencySymbol,
                size: 34
            )
            .padding(.top, 2)

            Text(budgetLine)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SpendyWidgetPalette.secondary)
                .padding(.top, 4)
        }
        .spendyWidgetChrome()
        .widgetURL(URL(string: "spendy://home"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Today \(SpendyWidgetFormat.amount(snapshot.todayTotal, symbol: snapshot.currencySymbol)). \(budgetLine)."
        )
    }

    private var budgetLine: String {
        if snapshot.budgetTotal <= 0 {
            return snapshot.topCategoryName
        }
        return "\(SpendyWidgetFormat.compactAmount(snapshot.remainingBudget, symbol: snapshot.currencySymbol)) left"
    }
}

// MARK: - Budget arc (same capsule-segment language as BudgetGaugeView)

struct SpendyBudgetArc: View {
    let progress: Double
    var radius: CGFloat = 58
    var segments: Int = 13

    var body: some View {
        let filled = Int(round(min(1, max(0, progress)) * Double(segments)))
        ZStack {
            ForEach(0..<segments, id: \.self) { index in
                let angleDegrees = 210.0 - Double(index) * (240.0 / Double(max(1, segments - 1)))
                let angleRadians = angleDegrees * .pi / 180.0
                let x = radius * cos(angleRadians)
                let y = -radius * sin(angleRadians)
                let isFilled = index < filled
                Capsule()
                    .fill(isFilled ? segmentColor(index) : SpendyWidgetPalette.fill)
                    .frame(width: 7, height: 18)
                    .rotationEffect(.degrees(90.0 - angleDegrees))
                    .offset(x: x, y: y + radius * 0.22)
            }
        }
        .frame(width: radius * 2 + 16, height: radius * 1.15 + 8)
        .accessibilityHidden(true)
    }

    private func segmentColor(_ index: Int) -> Color {
        let fraction = Double(index) / Double(max(1, segments - 1))
        if fraction < 0.5 {
            return mix(SpendyHexColor.color(from: "#FFA07A"), SpendyHexColor.color(from: "#FF9500"), fraction * 2)
        }
        return mix(SpendyHexColor.color(from: "#FF9500"), SpendyHexColor.color(from: "#FF3B30"), (fraction - 0.5) * 2)
    }

    private func mix(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let u1 = UIColor(a)
        let u2 = UIColor(b)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        u1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        u2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = CGFloat(min(1, max(0, t)))
        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t)
        )
    }
}

struct SpendyBudgetWidgetView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(spacing: 4) {
            Text("Spent this month")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SpendyWidgetPalette.tertiary)

            SpendyWidgetAmount(
                amount: snapshot.monthTotal,
                symbol: snapshot.currencySymbol,
                size: 26
            )

            ZStack {
                SpendyBudgetArc(progress: snapshot.budgetProgress, radius: 54, segments: 13)
                VStack(spacing: 1) {
                    Text("\(snapshot.daysLeft)")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(SpendyWidgetPalette.text)
                    Text(snapshot.daysLeft == 1 ? "day left" : "days left")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(SpendyWidgetPalette.tertiary)
                        .textCase(.uppercase)
                }
                .offset(y: 10)
            }

            if !snapshot.pacingCaption.isEmpty {
                Text(snapshot.pacingCaption)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background(SpendyWidgetPalette.canvas)
        .containerBackground(for: .widget) { SpendyWidgetPalette.canvas }
        .widgetURL(URL(string: "spendy://home"))
    }
}

struct SpendyCategoryFocusView: View {
    let snapshot: SpendyWidgetSnapshot
    let category: CategoryAppEntity?

    var body: some View {
        let match = snapshot.topCategories.first(where: { $0.id == category?.id })
        let name = category?.name ?? snapshot.topCategoryName
        let symbol = category?.sfSymbol ?? snapshot.topCategorySymbol
        let hex = category?.colorHex ?? snapshot.topCategoryColorHex
        let amount = match?.amount ?? (category == nil ? snapshot.topCategoryAmount : 0)

        VStack(alignment: .leading, spacing: 0) {
            WidgetCategoryBadge(symbol: symbol, colorHex: hex, size: 44)
            Spacer(minLength: 10)
            Text(name)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SpendyWidgetPalette.secondary)
                .lineLimit(1)
            SpendyWidgetAmount(amount: amount, symbol: snapshot.currencySymbol, size: 30)
                .padding(.top, 2)
            Spacer(minLength: 12)
            SpendyWeekBars(
                days: snapshot.weeklySpending,
                accentHex: hex,
                height: 36
            )
        }
        .spendyWidgetChrome()
        .widgetURL(URL(string: "spendy://home"))
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
            if family == .systemSmall {
                SpendySmallWidgetView(snapshot: snapshot)
            } else {
                SpendyMediumWeekWidgetView(snapshot: snapshot)
            }
        case .category:
            SpendyCategoryFocusView(snapshot: snapshot, category: configuration.category)
        default:
            if family == .systemMedium {
                SpendyMediumWeekWidgetView(snapshot: snapshot)
            } else if family == .systemLarge {
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
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyWidgetPalette.secondary)
                    SpendyWidgetAmount(
                        amount: snapshot.todayTotal,
                        symbol: snapshot.currencySymbol,
                        size: 36
                    )
                }
                Spacer(minLength: 8)
                WidgetCategoryBadge(
                    symbol: snapshot.topCategorySymbol,
                    colorHex: snapshot.topCategoryColorHex,
                    size: 48
                )
            }

            Spacer(minLength: 16)

            SpendyWeekBars(
                days: snapshot.weeklySpending,
                accentHex: snapshot.topCategoryColorHex,
                height: 54
            )

            if !snapshot.pacingCaption.isEmpty {
                Text(snapshot.pacingCaption)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                    .padding(.top, 8)
            }
        }
        .spendyWidgetChrome()
        .widgetURL(URL(string: "spendy://home"))
        .accessibilityLabel(
            "Today \(SpendyWidgetFormat.amount(snapshot.todayTotal, symbol: snapshot.currencySymbol))"
        )
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
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                Spacer()
                SpendyWidgetAddButton()
            }

            Spacer(minLength: 14)

            if snapshot.recentTransactions.isEmpty {
                Spacer(minLength: 0)
                Text("Nothing yet")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 16) {
                    ForEach(snapshot.recentTransactions.prefix(2)) { item in
                        HStack(spacing: 14) {
                            WidgetCategoryBadge(
                                symbol: item.categorySymbol,
                                colorHex: item.categoryColorHex,
                                size: 40
                            )
                            Text(item.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(SpendyWidgetPalette.text)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(item.isExpense ? "−" : "+")\(SpendyWidgetFormat.compactAmount(item.amount, symbol: snapshot.currencySymbol))")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                                .foregroundStyle(item.isExpense ? SpendyWidgetPalette.text : SpendyWidgetPalette.income)
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
// Three circular gauges, like the reference pack.

struct SpendyMediumCategoriesWidgetView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("This month")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SpendyWidgetPalette.secondary)

            Spacer(minLength: 12)

            if snapshot.topCategories.isEmpty {
                Text("No spending yet")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpendyWidgetPalette.secondary)
                Spacer(minLength: 0)
            } else {
                let maxAmount = max(snapshot.topCategories.map(\.amount).max() ?? 1, 1)
                HStack(spacing: 8) {
                    ForEach(snapshot.topCategories.prefix(3)) { category in
                        VStack(spacing: 8) {
                            ZStack {
                                SpendyMiniRing(
                                    progress: category.amount / maxAmount,
                                    size: 58,
                                    lineWidth: 7,
                                    color: SpendyHexColor.color(from: category.colorHex)
                                )
                                Image(systemName: category.sfSymbol)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(SpendyHexColor.color(from: category.colorHex))
                            }
                            Text(category.name)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(SpendyWidgetPalette.text)
                                .lineLimit(1)
                            Text(SpendyWidgetFormat.compactAmount(category.amount, symbol: snapshot.currencySymbol))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                                .foregroundStyle(SpendyWidgetPalette.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(category.name), \(SpendyWidgetFormat.amount(category.amount, symbol: snapshot.currencySymbol))"
                        )
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .spendyWidgetChrome()
        .widgetURL(URL(string: "spendy://home"))
    }
}

// MARK: - Large · Overview
// Hero + bars + two recents. Still a glance.

struct SpendyLargeOverviewWidgetView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyWidgetPalette.secondary)
                    SpendyWidgetAmount(
                        amount: snapshot.todayTotal,
                        symbol: snapshot.currencySymbol,
                        size: 38
                    )
                }
                Spacer()
                WidgetCategoryBadge(
                    symbol: snapshot.topCategorySymbol,
                    colorHex: snapshot.topCategoryColorHex,
                    size: 52
                )
            }

            Spacer(minLength: 20)

            SpendyWeekBars(
                days: snapshot.weeklySpending,
                accentHex: snapshot.topCategoryColorHex,
                height: 64
            )

            Spacer(minLength: 20)

            VStack(spacing: 14) {
                ForEach(snapshot.recentTransactions.prefix(2)) { item in
                    HStack(spacing: 14) {
                        WidgetCategoryBadge(
                            symbol: item.categorySymbol,
                            colorHex: item.categoryColorHex,
                            size: 36
                        )
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Spacer()
                        Text("\(item.isExpense ? "−" : "+")\(SpendyWidgetFormat.compactAmount(item.amount, symbol: snapshot.currencySymbol))")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(item.isExpense ? SpendyWidgetPalette.text : SpendyWidgetPalette.income)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .spendyWidgetChrome()
        .widgetURL(URL(string: "spendy://home"))
    }
}

// MARK: - Lock Screen

struct SpendyAccessoryCircularView: View {
    let snapshot: SpendyWidgetSnapshot

    var body: some View {
        Gauge(value: min(1, max(0, snapshot.budgetProgress))) {
            Image(systemName: snapshot.topCategorySymbol)
        } currentValueLabel: {
            Text(SpendyWidgetFormat.compactAmount(snapshot.todayTotal, symbol: snapshot.currencySymbol))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .gaugeStyle(.accessoryCircularCapacity)
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
            Image(systemName: snapshot.topCategorySymbol)
                .font(.title2.weight(.semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Today \(SpendyWidgetFormat.compactAmount(snapshot.todayTotal, symbol: snapshot.currencySymbol))")
                    .font(.headline.monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(snapshot.topCategoryName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
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
        Text("\(Image(systemName: snapshot.topCategorySymbol)) \(SpendyWidgetFormat.compactAmount(snapshot.todayTotal, symbol: snapshot.currencySymbol)) today")
            .containerBackground(for: .widget) { Color.clear }
            .widgetURL(URL(string: "spendy://home"))
    }
}
