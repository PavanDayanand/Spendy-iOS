//
//  InsightsEngine.swift
//  Spendy
//
//  Intelligent spending analytics and behavioral insights engine
//

import SwiftUI

struct InsightItem: Identifiable, Hashable {
    var id: String
    var family: String
    var scope: String
    var personaFit: [String]
    var confidence: Double
    var severity: Double
    var eligibility: Bool
    
    // UI details
    var title: String
    var value: String
    var desc: String
    var icon: String
    var colorHex: String
    var categoryId: String? = nil
    
    var color: Color {
        Color(hex: colorHex)
    }
}

// Facts generated from data
struct InsightFacts {
    let periodStart: Date
    let periodEnd: Date
    let currentTotal: Double
    let prevTotal: Double
    let txCount: Int
    let catTotals: [String: Double]
    let prevCatTotals: [String: Double]
    let dayCount: [Int: Int]
    let weekendTotal: Double
    let weekdayTotal: Double
    let weekendCount: Int
    let weekdayCount: Int
    let maxStreak: Int
    let budgetPacing: BudgetPacing?
    let dataDensity: Double
    let elapsedDays: Int
    let transactions: [Transaction]
}

struct BudgetPacing {
    let percentSpent: Double
    let safePace: Double
    let overPace: Double
    let remaining: Double
    let limit: Double
    let daysInMonth: Int
    let currentDay: Int
    let remainingDays: Int
    let avgDailySpend: Double
    let projectedTotal: Double
    let daysToExhaustion: Double
    let safeDailyRemaining: Double
}

struct InsightsEngine {
    
    // MARK: - 1. Facts Layer
    static func buildInsightFacts(
        transactions: [Transaction],
        budget: Budget,
        periodStart: Date,
        periodEnd: Date,
        prevStart: Date,
        prevEnd: Date,
        dataType: TransactionType
    ) -> InsightFacts {
        let calendar = Calendar.current
        let now = Date()
        
        let currentTxs = transactions.filter {
            $0.type == dataType && $0.date >= periodStart && $0.date <= periodEnd
        }
        
        let prevTxs = transactions.filter {
            $0.type == dataType && $0.date >= prevStart && $0.date <= prevEnd
        }
        
        let currentTotal = currentTxs.reduce(0) { $0 + $1.amount }
        let prevTotal = prevTxs.reduce(0) { $0 + $1.amount }
        
        var catTotals: [String: Double] = [:]
        for t in currentTxs {
            catTotals[t.categoryId, default: 0] += t.amount
        }
        
        var prevCatTotals: [String: Double] = [:]
        for t in prevTxs {
            prevCatTotals[t.categoryId, default: 0] += t.amount
        }
        
        var dayCount: [Int: Int] = [:]
        var weekendTotal = 0.0
        var weekdayTotal = 0.0
        var weekendCount = 0
        var weekdayCount = 0
        
        for t in currentTxs {
            let weekday = calendar.component(.weekday, from: t.date) // 1 = Sunday, 7 = Saturday
            dayCount[weekday, default: 0] += 1
            if weekday == 1 || weekday == 7 {
                weekendTotal += t.amount
                weekendCount += 1
            } else {
                weekdayTotal += t.amount
                weekdayCount += 1
            }
        }
        
        // Streaks
        var daySet: Set<String> = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for t in currentTxs {
            daySet.insert(formatter.string(from: t.date))
        }
        
        let elapsed = max(1, calendar.dateComponents([.day], from: periodStart, to: now).day ?? 1)
        var maxStreak = 0
        var currentStreak = 0
        for i in 0...elapsed {
            guard let d = calendar.date(byAdding: .day, value: i, to: periodStart) else { continue }
            let dStr = formatter.string(from: d)
            if !daySet.contains(dStr) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        // Budget
        var budgetPacing: BudgetPacing? = nil
        let daysInMonth = calendar.range(of: .day, in: .month, for: periodStart)?.count ?? 30
        // Determine if period is roughly a month (checking if periodStart and periodEnd are a month apart)
        let isMonthPeriod = (calendar.dateComponents([.day], from: periodStart, to: periodEnd).day ?? 0) >= 28
        
        if budget.isActive && budget.amount > 0 && isMonthPeriod && dataType == .expense {
            let limit = budget.period == .weekly ? budget.amount * 4.3333 : budget.amount
            let percentSpent = (currentTotal / limit) * 100
            let currentDay = min(daysInMonth, max(1, (calendar.dateComponents([.day], from: periodStart, to: now).day ?? 0) + 1))
            let safePace = (Double(currentDay) / Double(daysInMonth)) * 100
            let remainingDays = max(0, daysInMonth - currentDay)
            let avgDailySpend = currentTotal / Double(currentDay)
            let projectedTotal = avgDailySpend * Double(daysInMonth)
            let daysToExhaustion = avgDailySpend > 0 ? (limit / avgDailySpend) : Double(daysInMonth)
            let safeDailyRemaining = remainingDays > 0 ? max(0, limit - currentTotal) / Double(remainingDays) : 0
            
            budgetPacing = BudgetPacing(
                percentSpent: percentSpent,
                safePace: safePace,
                overPace: percentSpent - safePace,
                remaining: limit - currentTotal,
                limit: limit,
                daysInMonth: daysInMonth,
                currentDay: currentDay,
                remainingDays: remainingDays,
                avgDailySpend: avgDailySpend,
                projectedTotal: projectedTotal,
                daysToExhaustion: daysToExhaustion,
                safeDailyRemaining: safeDailyRemaining
            )
        }
        
        return InsightFacts(
            periodStart: periodStart,
            periodEnd: periodEnd,
            currentTotal: currentTotal,
            prevTotal: prevTotal,
            txCount: currentTxs.count,
            catTotals: catTotals,
            prevCatTotals: prevCatTotals,
            dayCount: dayCount,
            weekendTotal: weekendTotal,
            weekdayTotal: weekdayTotal,
            weekendCount: weekendCount,
            weekdayCount: weekdayCount,
            maxStreak: maxStreak,
            budgetPacing: budgetPacing,
            dataDensity: min(Double(currentTxs.count) / 10.0, 1.0),
            elapsedDays: elapsed,
            transactions: currentTxs
        )
    }
    
    // MARK: - 2. Mindset Layer
    static func inferUserMindset(facts: InsightFacts, budget: Budget) -> String {
        if facts.txCount < 5 || facts.dataDensity < 0.3 {
            return "beginner"
        }
        
        if budget.isActive && budget.amount > 0 && facts.budgetPacing != nil {
            return "guardian"
        }
        
        let wAvg = facts.weekendCount > 0 ? facts.weekendTotal / Double(facts.weekendCount) : 0
        let dAvg = facts.weekdayCount > 0 ? facts.weekdayTotal / Double(facts.weekdayCount) : 0
        let ratio = wAvg / max(dAvg, 1)
        if ratio > 1.5 || facts.maxStreak >= 3 {
            return "habit-focused"
        }
        
        return "reflector"
    }
    
    static func generateVelocityInsights(facts: InsightFacts, currencySymbol: String) -> [InsightItem] {
        var insights: [InsightItem] = []
        guard facts.elapsedDays >= 3 && facts.currentTotal > 0 else { return insights }
        
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: facts.periodStart)?.count ?? 30
        let dailyRate = facts.currentTotal / Double(facts.elapsedDays)
        let projectedTotal = dailyRate * Double(daysInMonth)
        
        if facts.prevTotal > 0 && projectedTotal > facts.prevTotal * 1.2 {
            insights.append(InsightItem(
                id: "velocity_high", family: "behavior", scope: "global",
                personaFit: ["guardian", "reflector", "optimizer"],
                confidence: 0.85, severity: 0.7, eligibility: true,
                title: "Spending Velocity",
                value: "\(currencySymbol)\(projectedTotal.safeInt)",
                desc: "On pace to spend \(Int(((projectedTotal / facts.prevTotal) - 1) * 100))% more than last month.",
                icon: "gauge.open.with.lines.needle.67percent.and.arrowtriangle",
                colorHex: "#FF9500"
            ))
        } else if facts.prevTotal > 0 && projectedTotal < facts.prevTotal * 0.8 {
            insights.append(InsightItem(
                id: "velocity_low", family: "behavior", scope: "global",
                personaFit: ["optimizer", "reflector"],
                confidence: 0.85, severity: 0.1, eligibility: true,
                title: "Under Budget Pace",
                value: "\(currencySymbol)\(projectedTotal.safeInt)",
                desc: "Projected to spend \(Int((1 - projectedTotal / facts.prevTotal) * 100))% less this month.",
                icon: "leaf.fill",
                colorHex: "#30d158"
            ))
        }
        
        return insights
    }
    
    static func generateRatioShiftInsights(facts: InsightFacts, categories: [Category], currencySymbol: String) -> [InsightItem] {
        var insights: [InsightItem] = []
        guard facts.currentTotal > 0 && facts.prevTotal > 0 else { return insights }
        
        for cat in categories.filter({ $0.type == .expense }) {
            let currentAmount = facts.catTotals[cat.id] ?? 0
            let prevAmount = facts.prevCatTotals[cat.id] ?? 0
            
            let currentRatio = currentAmount / facts.currentTotal
            let prevRatio = prevAmount / facts.prevTotal
            let ratioShift = currentRatio - prevRatio
            
            // Flag if a category's share shifted by 15+ percentage points
            if ratioShift >= 0.15 && currentAmount > 0 {
                insights.append(InsightItem(
                    id: "ratio_shift_\(cat.id)", family: "category", scope: "category",
                    personaFit: ["reflector", "optimizer"],
                    confidence: 0.8, severity: 0.5, eligibility: true,
                    title: "Share Shift",
                    value: "\(Int(prevRatio * 100))% → \(Int(currentRatio * 100))%",
                    desc: "\(cat.label) grew from \(Int(prevRatio * 100))% to \(Int(currentRatio * 100))% of total spend.",
                    icon: cat.sfSymbol.isEmpty ? "chart.pie.fill" : cat.sfSymbol,
                    colorHex: cat.colorHex.isEmpty ? "#BF5AF2" : cat.colorHex,
                    categoryId: cat.id
                ))
            }
        }
        
        return insights
    }
    
    static func generateBudgetInsights(facts: InsightFacts, currencySymbol: String) -> [InsightItem] {
        var insights: [InsightItem] = []
        guard let pacing = facts.budgetPacing else { return insights }
        
        if pacing.percentSpent >= 100 {
            insights.append(InsightItem(
                id: "budget_exceeded", family: "budget", scope: "global", personaFit: ["guardian", "planner", "reflector"],
                confidence: 1.0, severity: 1.0, eligibility: true,
                title: "Budget Exceeded", value: "\(pacing.percentSpent.safeInt)%", desc: "Monthly limit exceeded.",
                icon: "exclamationmark.octagon.fill", colorHex: "#ff453a"
            ))
        } else if pacing.projectedTotal > pacing.limit {
            let daysToExhaust = min(365, max(0, pacing.daysToExhaustion.safeInt))
            let exhaustionDate = Calendar.current.date(byAdding: .day, value: daysToExhaust, to: facts.periodStart) ?? facts.periodStart
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let formattedDate = formatter.string(from: exhaustionDate)
            
            insights.append(InsightItem(
                id: "budget_exhaustion_risk", family: "budget", scope: "global", personaFit: ["guardian", "planner", "reflector"],
                confidence: 0.9, severity: 0.85, eligibility: true,
                title: "Exhaustion Risk", value: formattedDate, desc: "Budget runs out on \(formattedDate) at this pace.",
                icon: "exclamationmark.triangle.fill", colorHex: "#ff9500"
            ))
            
            if pacing.remainingDays > 0 {
                insights.append(InsightItem(
                    id: "budget_recovery_allowance", family: "budget", scope: "global", personaFit: ["guardian", "optimizer"],
                    confidence: 0.85, severity: 0.5, eligibility: true,
                    title: "Daily Limit", value: "\(currencySymbol)\(max(0, pacing.safeDailyRemaining).safeInt)",
                    desc: "Safe daily spend for next \(pacing.remainingDays) days.",
                    icon: "pills.fill", colorHex: "#ffd60a" // Close enough to piggy bank
                ))
            }
        } else if pacing.overPace > 15 {
            insights.append(InsightItem(
                id: "budget_burn_rate", family: "budget", scope: "global", personaFit: ["guardian", "planner"],
                confidence: 0.9, severity: 0.8, eligibility: true,
                title: "High Burn Rate", value: "+\(pacing.overPace.safeInt)%", desc: "Spending is faster than cycle pace.",
                icon: "waveform.path.ecg", colorHex: "#ff9500"
            ))
        } else if pacing.overPace <= 0 && pacing.percentSpent > 20 {
            insights.append(InsightItem(
                id: "budget_pacing_good", family: "budget", scope: "global", personaFit: ["guardian", "optimizer"],
                confidence: 0.8, severity: 0.2, eligibility: true,
                title: "On Track", value: "\(pacing.percentSpent.safeInt)%", desc: "Pacing is safely within budget.",
                icon: "checkmark.shield.fill", colorHex: "#30d158"
            ))
        }
        
        return insights
    }
    
    static func generateBehaviorInsights(facts: InsightFacts, dataType: TransactionType) -> [InsightItem] {
        var insights: [InsightItem] = []
        let wAvg = facts.weekendCount > 0 ? facts.weekendTotal / Double(facts.weekendCount) : 0
        let dAvg = facts.weekdayCount > 0 ? facts.weekdayTotal / Double(facts.weekdayCount) : 0
        
        if dataType == .income {
            if facts.weekendCount >= 1 && wAvg > dAvg {
                insights.append(InsightItem(
                    id: "weekend_hustle", family: "behavior", scope: "global", personaFit: ["optimizer", "habit-focused"],
                    confidence: max(0.6, facts.dataDensity), severity: 0.1, eligibility: true,
                    title: "Weekend Hustler", value: "Higher", desc: "Higher income earned on weekends.",
                    icon: "flame.fill", colorHex: "#ff9500"
                ))
            }
            return insights
        }
        
        if facts.weekendCount >= 2 && facts.weekdayCount >= 3 {
            let ratio = wAvg / max(dAvg, 1.0)
            if ratio > 1.4 {
                insights.append(InsightItem(
                    id: "weekend_bias", family: "behavior", scope: "global", personaFit: ["reflector", "habit-focused"],
                    confidence: facts.dataDensity, severity: 0.4, eligibility: true,
                    title: "Weekend Bias", value: "Higher", desc: "\(((ratio - 1) * 100).safeInt)% higher spend on weekends.",
                    icon: "calendar.badge.clock", colorHex: "#5856d6"
                ))
            }
        }
        
        if facts.maxStreak >= 2 {
            insights.append(InsightItem(
                id: "no_spend_streak", family: "behavior", scope: "global", personaFit: ["habit-focused", "reflector", "guardian"],
                confidence: 0.9, severity: 0.1, eligibility: true,
                title: "Zero Spend Streak", value: "\(facts.maxStreak) days", desc: "Longest streak with zero spend.",
                icon: "flame.fill", colorHex: "#30d158"
            ))
        }
        
        // Zero-spend day celebration (weekly)
        let calendar = Calendar.current
        let now = Date()
        if let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) {
            let weekTxDays = Set(facts.transactions.filter { $0.date >= weekStart }.map { calendar.startOfDay(for: $0.date) })
            let zeroDaysThisWeek = 7 - weekTxDays.count
            if zeroDaysThisWeek >= 3 {
                insights.append(InsightItem(
                    id: "zero_day_week", family: "behavior", scope: "global",
                    personaFit: ["habit-focused", "reflector", "guardian"],
                    confidence: 0.9, severity: 0.15, eligibility: true,
                    title: "Zero-Spend Days",
                    value: "\(zeroDaysThisWeek) this week",
                    desc: "\(zeroDaysThisWeek) days with no spending — great discipline!",
                    icon: "star.fill",
                    colorHex: "#FFD60A"
                ))
            }
        }
        
        return insights
    }
    
    static func generateCategoryInsights(facts: InsightFacts, categories: [Category], currencySymbol: String, dataType: TransactionType) -> [InsightItem] {
        var insights: [InsightItem] = []
        
        for cat in categories.filter({ $0.type == dataType }) {
            let total = facts.catTotals[cat.id] ?? 0
            let prevTotal = facts.prevCatTotals[cat.id] ?? 0
            let catSymbol = cat.sfSymbol.isEmpty ? "tag.fill" : cat.sfSymbol
            let catColor = cat.colorHex.isEmpty ? "#bf5af2" : cat.colorHex
            
            if total > 0 && facts.currentTotal > 0 && (total / facts.currentTotal) > 0.4 {
                let pct = (total / facts.currentTotal) * 100
                insights.append(InsightItem(
                    id: "top_cat_\(cat.id)", family: "category", scope: "category", personaFit: ["reflector", "beginner"],
                    confidence: facts.dataDensity, severity: 0.3, eligibility: true,
                    title: "Top Category", value: cat.label, desc: "Makes up \(pct.safeInt)% of your total.",
                    icon: catSymbol, colorHex: catColor, categoryId: cat.id
                ))
            }
            
            if prevTotal > 50 {
                let diff = total - prevTotal
                let pctChange = (diff / prevTotal) * 100
                
                if pctChange >= 25 {
                    insights.append(InsightItem(
                        id: "trend_up_\(cat.id)", family: "category", scope: "category", personaFit: ["guardian", "optimizer"],
                        confidence: 0.8, severity: 0.6, eligibility: true,
                        title: dataType == .income ? "Income Spike" : "Spend Spike", value: "+\(pctChange.safeInt)%",
                        desc: "+\(currencySymbol)\(diff.safeInt) higher than last cycle.",
                        icon: catSymbol, colorHex: catColor, categoryId: cat.id
                    ))
                } else if pctChange <= -25 {
                    insights.append(InsightItem(
                        id: "trend_down_\(cat.id)", family: "category", scope: "category", personaFit: ["guardian", "optimizer"],
                        confidence: 0.8, severity: 0.1, eligibility: true,
                        title: dataType == .income ? "Income Drop" : "Spend Reduced", value: "\(pctChange.safeInt)%",
                        desc: "Saved \(currencySymbol)\(abs(diff).safeInt) on \(cat.label).",
                        icon: catSymbol, colorHex: catColor, categoryId: cat.id
                    ))
                }
            }
            
            let allCatTxs = facts.transactions.filter { $0.categoryId == cat.id }
            if allCatTxs.count >= 5 {
                let mean = allCatTxs.reduce(0) { $0 + $1.amount } / Double(allCatTxs.count)
                let threshold = mean * 3
                
                let spikes = allCatTxs.filter { $0.amount > threshold && $0.amount > 100 }
                for (i, t) in spikes.enumerated() {
                    insights.append(InsightItem(
                        id: "cat_anomaly_\(cat.id)_\(i)", family: "category", scope: "category", personaFit: ["optimizer", "reflector", "guardian"],
                        confidence: 0.9, severity: 0.75, eligibility: true,
                        title: "Unusual Spend", value: "\(currencySymbol)\(t.amount.safeInt)", desc: "3x higher than average for \(cat.label).",
                        icon: catSymbol, colorHex: catColor, categoryId: cat.id
                    ))
                }
                
                // Dynamic Predictive Forecast (Unlocked at 5+ transactions)
                if facts.elapsedDays >= 3 && total > 0 && dataType == .expense {
                    let calendar = Calendar.current
                    let daysInMonth = calendar.range(of: .day, in: .month, for: facts.periodStart)?.count ?? 30
                    let dailyRunRate = total / Double(max(1, facts.elapsedDays))
                    let projectedTotal = dailyRunRate * Double(daysInMonth)
                    
                    let isTrendingHigher = prevTotal > 0 ? (projectedTotal > prevTotal * 1.15) : false
                    
                    insights.append(InsightItem(
                        id: "cat_predictive_\(cat.id)",
                        family: "category",
                        scope: "category",
                        personaFit: ["optimizer", "guardian", "planner"],
                        confidence: 0.88,
                        severity: isTrendingHigher ? 0.65 : 0.35,
                        eligibility: true,
                        title: "Forecast Pace",
                        value: "\(currencySymbol)\(projectedTotal.safeInt)",
                        desc: "Projected to reach \(currencySymbol)\(projectedTotal.safeInt) this month based on \(allCatTxs.count) transactions.",
                        icon: isTrendingHigher ? "chart.line.uptrend.xyaxis" : "sparkles",
                        colorHex: catColor,
                        categoryId: cat.id
                    ))
                }
            }
        }
        
        return insights
    }
    
    static func generateSubscriptionInsights(facts: InsightFacts, subscriptions: [Subscription], currencySymbol: String) -> [InsightItem] {
        var insights: [InsightItem] = []
        let now = Date()
        
        for sub in subscriptions {
            let subTxs = facts.transactions.filter { $0.subscriptionId == sub.id.uuidString && $0.type == .expense }
            let subColor = sub.colorHex.isEmpty ? "#5856d6" : sub.colorHex
            let subIcon = sub.sfSymbol.isEmpty ? "creditcard.fill" : sub.sfSymbol
            
            if subTxs.count > 1 {
                insights.append(InsightItem(
                    id: "sub_double_charge_\(sub.id)", family: "subscription", scope: "global", personaFit: ["optimizer", "guardian", "planner"],
                    confidence: 1.0, severity: 0.75, eligibility: true,
                    title: "Double Billing", value: sub.name, desc: "\(subTxs.count) charges detected this cycle.",
                    icon: "exclamationmark.octagon.fill", colorHex: subColor
                ))
            }
            
            for (i, t) in subTxs.enumerated() {
                if sub.amount > 0 && abs(t.amount - sub.amount) > 0.01 {
                    let pctDiff = ((t.amount - sub.amount) / sub.amount) * 100
                    insights.append(InsightItem(
                        id: "sub_price_change_\(sub.id)_\(i)", family: "subscription", scope: "global", personaFit: ["optimizer", "guardian"],
                        confidence: 1.0, severity: 0.65, eligibility: true,
                        title: "Price Changed", value: "\(pctDiff > 0 ? "+" : "")\(pctDiff.safeInt)%",
                        desc: "Charged \(currencySymbol)\(t.amount.safeInt) instead of \(currencySymbol)\(sub.amount.safeInt).",
                        icon: "arrow.triangle.2.circlepath", colorHex: subColor
                    ))
                }
            }
            
            let daysUntil = Calendar.current.dateComponents([.day], from: now, to: sub.nextBillingDate).day ?? 0
            if daysUntil > 0 && daysUntil <= 3 {
                insights.append(InsightItem(
                    id: "sub_due_\(sub.id)", family: "subscription", scope: "global", personaFit: ["planner", "guardian", "reflector", "beginner"],
                    confidence: 1.0, severity: 0.5, eligibility: true,
                    title: "Upcoming Bill", value: sub.name, desc: "\(currencySymbol)\(sub.amount.safeInt) due \(daysUntil == 1 ? "tomorrow" : "in \(daysUntil) days").",
                    icon: subIcon, colorHex: subColor
                ))
            }
            
            if daysUntil <= 0 && daysUntil >= -7 {
                insights.append(InsightItem(
                    id: "sub_overdue_\(sub.id)", family: "subscription", scope: "global", personaFit: ["planner", "guardian", "reflector", "beginner"],
                    confidence: 1.0, severity: 0.9, eligibility: true,
                    title: daysUntil == 0 ? "Due Today" : "Overdue Bill", value: sub.name,
                    desc: "\(currencySymbol)\(sub.amount.safeInt) \(daysUntil == 0 ? "due today" : "due \(abs(daysUntil))d ago").",
                    icon: subIcon, colorHex: subColor
                ))
            }
        }
        
        return insights
    }
    
    static func generateIncomeInsights(facts: InsightFacts) -> [InsightItem] {
        var insights: [InsightItem] = []
        if facts.prevTotal > 0 {
            let pctChange = ((facts.currentTotal - facts.prevTotal) / facts.prevTotal) * 100
            if pctChange >= 20 {
                insights.append(InsightItem(
                    id: "income_spike", family: "behavior", scope: "global", personaFit: ["optimizer", "reflector"],
                    confidence: 0.8, severity: 0.1, eligibility: true,
                    title: "Income Spike", value: "+\(pctChange.safeInt)%", desc: "Income increased significantly this period.",
                    icon: "chart.line.uptrend.xyaxis", colorHex: "#30d158"
                ))
            } else if pctChange <= -20 {
                insights.append(InsightItem(
                    id: "income_drop", family: "behavior", scope: "global", personaFit: ["guardian", "planner"],
                    confidence: 0.8, severity: 0.7, eligibility: true,
                    title: "Income Drop", value: "\(pctChange.safeInt)%", desc: "Income decreased compared to previous period.",
                    icon: "chart.line.downtrend.xyaxis", colorHex: "#ff9500"
                ))
            }
        }
        
        let activeSources = facts.catTotals.values.filter { $0 > 0 }.count
        if activeSources >= 3 {
            insights.append(InsightItem(
                id: "diversified_income", family: "behavior", scope: "global", personaFit: ["optimizer", "habit-focused"],
                confidence: 0.9, severity: 0.1, eligibility: true,
                title: "Income Streams", value: "\(activeSources) sources", desc: "Earnings across \(activeSources) separate sources.",
                icon: "shield.fill", colorHex: "#5856d6"
            ))
        }
        
        return insights
    }
    
    // MARK: - 4. Ranking
    static func rankInsights(candidates: [InsightItem], mindset: String, surface: String) -> [InsightItem] {
        var valid = candidates.filter { $0.eligibility && $0.confidence >= 0.3 }
        if mindset == "beginner" {
            valid = valid.filter { $0.personaFit.contains("beginner") }
        }
        
        valid.sort { a, b in
            let aFitBoost = a.personaFit.contains(mindset) ? 0.2 : 0
            let bFitBoost = b.personaFit.contains(mindset) ? 0.2 : 0
            let aScore = a.severity * 0.6 + a.confidence * 0.4 + aFitBoost
            let bScore = b.severity * 0.6 + b.confidence * 0.4 + bFitBoost
            return aScore > bScore
        }
        
        var deduped: [InsightItem] = []
        var seenFamilies = Set<String>()
        for insight in valid {
            if insight.family == "category" {
                deduped.append(insight)
            } else if !seenFamilies.contains(insight.family) {
                deduped.append(insight)
                seenFamilies.insert(insight.family)
            }
        }
        
        if surface == "dashboard" {
            return Array(deduped.prefix(5))
        } else if surface == "analytics" {
            return Array(deduped.filter { $0.family != "subscription" }.prefix(3))
        }
        
        return deduped
    }
    
    // MARK: - 5. Public API
    static func getAnalyticsInsights(
        transactions: [Transaction],
        budget: Budget,
        categories: [Category],
        subscriptions: [Subscription],
        periodStart: Date,
        periodEnd: Date,
        prevStart: Date,
        prevEnd: Date,
        dataType: TransactionType,
        currencySymbol: String
    ) -> [InsightItem] {
        let facts = buildInsightFacts(
            transactions: transactions, budget: budget,
            periodStart: periodStart, periodEnd: periodEnd,
            prevStart: prevStart, prevEnd: prevEnd,
            dataType: dataType
        )
        let mindset = inferUserMindset(facts: facts, budget: budget)
        
        var candidates: [InsightItem] = []
        candidates.append(contentsOf: generateCategoryInsights(facts: facts, categories: categories, currencySymbol: currencySymbol, dataType: dataType))
        
        if dataType == .expense {
            candidates.append(contentsOf: generateVelocityInsights(facts: facts, currencySymbol: currencySymbol))
            candidates.append(contentsOf: generateRatioShiftInsights(facts: facts, categories: categories, currencySymbol: currencySymbol))
            candidates.append(contentsOf: generateBudgetInsights(facts: facts, currencySymbol: currencySymbol))
            candidates.append(contentsOf: generateBehaviorInsights(facts: facts, dataType: dataType))
            candidates.append(contentsOf: generateSubscriptionInsights(facts: facts, subscriptions: subscriptions, currencySymbol: currencySymbol))
        } else {
            candidates.append(contentsOf: generateIncomeInsights(facts: facts))
            candidates.append(contentsOf: generateBehaviorInsights(facts: facts, dataType: dataType))
        }
        
        return rankInsights(candidates: candidates, mindset: mindset, surface: "analytics")
    }
    
    static func getDashboardInsights(
        transactions: [Transaction],
        budget: Budget,
        categories: [Category],
        subscriptions: [Subscription],
        currencySymbol: String
    ) -> [InsightItem] {
        let now = Date()
        let calendar = Calendar.current
        
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: periodStart) ?? now
        
        let prevStart = calendar.date(byAdding: .month, value: -1, to: periodStart) ?? now
        let prevEnd = calendar.date(byAdding: .day, value: -1, to: periodStart) ?? now
        
        let facts = buildInsightFacts(
            transactions: transactions, budget: budget,
            periodStart: periodStart, periodEnd: periodEnd,
            prevStart: prevStart, prevEnd: prevEnd,
            dataType: .expense
        )
        let mindset = inferUserMindset(facts: facts, budget: budget)
        
        var candidates: [InsightItem] = []
        candidates.append(contentsOf: generateCategoryInsights(facts: facts, categories: categories, currencySymbol: currencySymbol, dataType: .expense))
        candidates.append(contentsOf: generateVelocityInsights(facts: facts, currencySymbol: currencySymbol))
        candidates.append(contentsOf: generateRatioShiftInsights(facts: facts, categories: categories, currencySymbol: currencySymbol))
        candidates.append(contentsOf: generateBudgetInsights(facts: facts, currencySymbol: currencySymbol))
        candidates.append(contentsOf: generateBehaviorInsights(facts: facts, dataType: .expense))
        candidates.append(contentsOf: generateSubscriptionInsights(facts: facts, subscriptions: subscriptions, currencySymbol: currencySymbol))
        
        return rankInsights(candidates: candidates, mindset: mindset, surface: "dashboard")
    }
    
    static func getSubscriptionInsights(
        transactions: [Transaction],
        subscriptions: [Subscription],
        currencySymbol: String
    ) -> [InsightItem] {
        let now = Date()
        let calendar = Calendar.current
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: periodStart) ?? now
        
        let facts = buildInsightFacts(
            transactions: transactions,
            budget: Budget(),
            periodStart: periodStart,
            periodEnd: periodEnd,
            prevStart: periodStart,
            prevEnd: periodEnd,
            dataType: .expense
        )
        return generateSubscriptionInsights(facts: facts, subscriptions: subscriptions, currencySymbol: currencySymbol)
    }
}
