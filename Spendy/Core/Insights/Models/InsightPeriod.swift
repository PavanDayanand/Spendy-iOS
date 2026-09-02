//
//  InsightPeriod.swift
//  Spendy
//
//  First-class temporal range driving period-aware facts, comparison baselines, and rule eligibility.
//

import Foundation

enum InsightPeriod: String, Codable, Sendable, CaseIterable, Identifiable {
    case week = "1w"          // 1 Week (rolling 7 days)
    case month = "1m"         // Current Month / 1 Month
    case threeMonths = "3m"   // 3 Months (quarterly / sustained trend)
    case sixMonths = "6m"     // 6 Months (half-year trend)
    case year = "1y"          // 1 Year (annual / seasonal)
    case all = "all"          // Lifetime / All-time
    case custom = "custom"    // Arbitrary date window
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .threeMonths: return "Last 3 Months"
        case .sixMonths: return "Last 6 Months"
        case .year: return "This Year"
        case .all: return "All Time"
        case .custom: return "Custom Period"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        case .all: return "All"
        case .custom: return "Custom"
        }
    }
    
    var currentPeriodPhrase: String {
        switch self {
        case .week: return "this week"
        case .month: return "this month"
        case .threeMonths: return "over the last 3 months"
        case .sixMonths: return "over the last 6 months"
        case .year: return "this year"
        case .all: return "overall"
        case .custom: return "over this period"
        }
    }
    
    var baselinePeriodPhrase: String {
        switch self {
        case .week: return "last week"
        case .month: return "last month"
        case .threeMonths: return "previous 3 months"
        case .sixMonths: return "previous 6 months"
        case .year: return "last year"
        case .all: return "lifetime average"
        case .custom: return "previous period"
        }
    }
    
    /// Calculate current period bounds and baseline comparison bounds relative to reference date
    func resolveBounds(now: Date = Date(), calendar: Calendar = Calendar.current) -> (periodStart: Date, periodEnd: Date, baselineStart: Date, baselineEnd: Date) {
        let currentDayStart = calendar.startOfDay(for: now)
        let currentDayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        
        switch self {
        case .week:
            let periodStart = calendar.date(byAdding: .day, value: -6, to: currentDayStart) ?? currentDayStart
            let periodEnd = currentDayEnd
            let baselineStart = calendar.date(byAdding: .day, value: -7, to: periodStart) ?? periodStart
            let baselineEnd = calendar.date(byAdding: .second, value: -1, to: periodStart) ?? periodStart
            return (periodStart, periodEnd, baselineStart, baselineEnd)
            
        case .month:
            let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? currentDayStart
            let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: periodStart) ?? currentDayEnd
            let baselineStart = calendar.date(byAdding: .month, value: -1, to: periodStart) ?? periodStart
            let baselineEnd = calendar.date(byAdding: .second, value: -1, to: periodStart) ?? periodStart
            return (periodStart, periodEnd, baselineStart, baselineEnd)
            
        case .threeMonths:
            let startOfCurMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? currentDayStart
            let periodStart = calendar.date(byAdding: .month, value: -2, to: startOfCurMonth) ?? startOfCurMonth
            let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfCurMonth) ?? currentDayEnd
            let baselineStart = calendar.date(byAdding: .month, value: -3, to: periodStart) ?? periodStart
            let baselineEnd = calendar.date(byAdding: .second, value: -1, to: periodStart) ?? periodStart
            return (periodStart, periodEnd, baselineStart, baselineEnd)
            
        case .sixMonths:
            let startOfCurMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? currentDayStart
            let periodStart = calendar.date(byAdding: .month, value: -5, to: startOfCurMonth) ?? startOfCurMonth
            let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfCurMonth) ?? currentDayEnd
            let baselineStart = calendar.date(byAdding: .month, value: -6, to: periodStart) ?? periodStart
            let baselineEnd = calendar.date(byAdding: .second, value: -1, to: periodStart) ?? periodStart
            return (periodStart, periodEnd, baselineStart, baselineEnd)
            
        case .year:
            let periodStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? currentDayStart
            let periodEnd = calendar.date(byAdding: DateComponents(year: 1, day: -1, hour: 23, minute: 59, second: 59), to: periodStart) ?? currentDayEnd
            let baselineStart = calendar.date(byAdding: .year, value: -1, to: periodStart) ?? periodStart
            let baselineEnd = calendar.date(byAdding: .second, value: -1, to: periodStart) ?? periodStart
            return (periodStart, periodEnd, baselineStart, baselineEnd)
            
        case .all:
            let periodStart = calendar.date(byAdding: .year, value: -10, to: currentDayStart) ?? currentDayStart
            let periodEnd = currentDayEnd
            let baselineStart = periodStart
            let baselineEnd = periodEnd
            return (periodStart, periodEnd, baselineStart, baselineEnd)
            
        case .custom:
            return (currentDayStart, currentDayEnd, currentDayStart, currentDayEnd)
        }
    }
}
