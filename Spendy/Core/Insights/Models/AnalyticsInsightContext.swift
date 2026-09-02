//
//  AnalyticsInsightContext.swift
//  Spendy
//
//  Canonical single source of truth for analytical context:
//  Encapsulates exact date boundaries, comparison baseline boundaries,
//  scope (global, specific category, or specific account), and period metadata.
//

import Foundation

struct AnalyticsInsightContext: Equatable, Sendable {
    
    enum Scope: Equatable, Sendable {
        case global
        case category(id: String)
        case account(id: String)
        
        var key: String {
            switch self {
            case .global: return "global"
            case .category(let id): return "cat_\(id)"
            case .account(let id): return "acc_\(id)"
            }
        }
    }
    
    let scope: Scope
    let period: InsightPeriod
    let startDate: Date
    let endDate: Date
    let baselineStartDate: Date
    let baselineEndDate: Date
    let isCustomRange: Bool
    let customRangeLabel: String?
    let referenceDate: Date
    
    init(
        scope: Scope = .global,
        period: InsightPeriod,
        startDate: Date,
        endDate: Date,
        baselineStartDate: Date,
        baselineEndDate: Date,
        isCustomRange: Bool = false,
        customRangeLabel: String? = nil,
        referenceDate: Date = Date()
    ) {
        self.scope = scope
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.baselineStartDate = baselineStartDate
        self.baselineEndDate = baselineEndDate
        self.isCustomRange = isCustomRange
        self.customRangeLabel = customRangeLabel
        self.referenceDate = referenceDate
    }
    
    /// Create context from a standard InsightPeriod relative to a reference date
    static func standard(
        period: InsightPeriod,
        scope: Scope = .global,
        referenceDate: Date = Date(),
        calendar: Calendar = Calendar.current
    ) -> AnalyticsInsightContext {
        let bounds = period.resolveBounds(now: referenceDate, calendar: calendar)
        return AnalyticsInsightContext(
            scope: scope,
            period: period,
            startDate: bounds.periodStart,
            endDate: bounds.periodEnd,
            baselineStartDate: bounds.baselineStart,
            baselineEndDate: bounds.baselineEnd,
            isCustomRange: false,
            customRangeLabel: nil,
            referenceDate: referenceDate
        )
    }
    
    /// Create context from explicit start and end dates (e.g. from Custom Date Picker)
    static func custom(
        startDate: Date,
        endDate: Date,
        scope: Scope = .global,
        referenceDate: Date = Date(),
        calendar: Calendar = Calendar.current
    ) -> AnalyticsInsightContext {
        let startOfDayStart = calendar.startOfDay(for: startDate)
        let endOfDayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        
        let duration = endOfDayEnd.timeIntervalSince(startOfDayStart)
        let baselineEnd = startOfDayStart.addingTimeInterval(-1)
        let baselineStart = baselineEnd.addingTimeInterval(-duration)
        
        let startBaseline = calendar.startOfDay(for: baselineStart)
        let endBaseline = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: baselineEnd) ?? baselineEnd
        
        // Format human label e.g. "Jun 12 - Aug 17"
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        let label = "\(df.string(from: startOfDayStart)) - \(df.string(from: endOfDayEnd))"
        
        return AnalyticsInsightContext(
            scope: scope,
            period: .custom,
            startDate: startOfDayStart,
            endDate: endOfDayEnd,
            baselineStartDate: startBaseline,
            baselineEndDate: endBaseline,
            isCustomRange: true,
            customRangeLabel: label,
            referenceDate: referenceDate
        )
    }
    
    /// Whether the period is still actively in progress today
    var isPeriodInProgress: Bool {
        referenceDate <= endDate && referenceDate >= startDate
    }
    
    /// Whether the period is entirely in the past (historical)
    var isHistorical: Bool {
        referenceDate > endDate
    }
    
    /// Total calendar days represented in this analytical window
    var totalDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, days + 1)
    }
}
