import SwiftUI
import Charts

// MARK: - Chart Period Enum
enum ChartPeriod: String, CaseIterable, Identifiable {
    case week = "1w"
    case month = "1m"
    case threeMonths = "3m"
    case sixMonths = "6m"
    case year = "1y"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        }
    }
}

// MARK: - Discrete Bar Point (Home-style histograms)
struct AnalyticsBarPoint: Identifiable, Equatable {
    let id: String
    let date: Date
    let endDate: Date
    let label: String
    let amount: Double
    let txCount: Int
}

private enum AnalyticsBarBucket {
    case day
    case week
    case month
}

// MARK: - Chart Data Point
struct CategoryChartPoint: Identifiable, Equatable {
    let id: String
    let date: Date
    let label: String
    let amount: Double
    let dayVolume: Double
    let txCount: Int
    let isPredicted: Bool
    
    init(
        id: String = UUID().uuidString,
        date: Date,
        label: String,
        amount: Double,
        dayVolume: Double = 0,
        txCount: Int = 0,
        isPredicted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.label = label
        self.amount = amount
        self.dayVolume = dayVolume
        self.txCount = txCount
        self.isPredicted = isPredicted
    }
}

// MARK: - Shared Engine
enum AnalyticsChartEngine {
    
    /// Calculate period bounds for a given ChartPeriod
    static func periodBounds(for period: ChartPeriod, transactions: [Transaction] = []) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
            return (start, now)
        case .month:
            return (now.startOfMonth, now.endOfMonth)
        case .threeMonths:
            let start = calendar.date(byAdding: .month, value: -2, to: calendar.startOfDay(for: now)) ?? now
            return (start, now.endOfDay)
        case .sixMonths:
            let start = calendar.date(byAdding: .month, value: -5, to: calendar.startOfDay(for: now)) ?? now
            return (start, now.endOfDay)
        case .year:
            return (now.startOfYear, now.endOfYear)
        }
    }
    
    /// Calculate days in selected period
    static func daysInPeriod(for period: ChartPeriod) -> Int {
        let bounds = periodBounds(for: period)
        let components = Calendar.current.dateComponents([.day], from: bounds.start, to: bounds.end)
        return max(1, (components.day ?? 1) + 1)
    }
    
    /// Generate chart points from transactions (cumulative)
    static func generateChartPoints(
        transactions: [Transaction],
        period: ChartPeriod,
        hasEnoughTxs: Bool,
        valueForDay: (([Transaction]) -> Double)? = nil
    ) -> [CategoryChartPoint] {
        let calendar = Calendar.current
        let bounds = periodBounds(for: period)
        let txs = transactions.filter { $0.date >= bounds.start && $0.date <= bounds.end }
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Default value extractor: sum of amounts
        let defaultExtractor: ([Transaction]) -> Double = { txns in
            txns.reduce(0) { $0 + $1.amount }
        }
        let extractor = valueForDay ?? defaultExtractor
        
        switch period {
        case .week, .month:
            var points: [CategoryChartPoint] = []
            var current = calendar.startOfDay(for: bounds.start)
            let endDay = calendar.startOfDay(for: bounds.end)
            
            let dateLabelFmt = period == .week ? SpendyDateFormatterCache.shortWeekday : SpendyDateFormatterCache.dayNumber
            
            let daysElapsed = max(1, calendar.dateComponents([.day], from: bounds.start, to: min(today, bounds.end)).day ?? 1)
            let actualTxs = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }
            let totalValueSoFar = extractor(actualTxs)
            let dailyRate = daysElapsed > 0 ? (totalValueSoFar / Double(daysElapsed)) : 0
            
            var cumulativeValue: Double = 0
            
            var dayGuard = 0
            while current <= endDay && dayGuard < 400 {
                dayGuard += 1
                let isActual = current <= today
                
                if isActual {
                    let dayStart = current
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86_400)
                    let dayTxs = txs.filter { $0.date >= dayStart && $0.date < dayEnd }
                    let dayVol = extractor(dayTxs)
                    
                    cumulativeValue += dayVol
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateLabelFmt.string(from: current),
                        amount: cumulativeValue,
                        dayVolume: dayVol,
                        txCount: dayTxs.count,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let dayOffset = max(1, calendar.dateComponents([.day], from: today, to: current).day ?? 1)
                    let predictedAmount = cumulativeValue + (dailyRate * Double(dayOffset))
                    points.append(CategoryChartPoint(
                        id: "pred_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateLabelFmt.string(from: current),
                        amount: predictedAmount,
                        dayVolume: dailyRate,
                        txCount: 0,
                        isPredicted: true
                    ))
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: current), next > current else { break }
                current = next
            }
            return points
            
        case .threeMonths, .sixMonths, .year:
            var points: [CategoryChartPoint] = []
            var current = calendar.date(from: calendar.dateComponents([.year, .month], from: bounds.start)) ?? bounds.start
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: bounds.end)) ?? bounds.end
            
            let monthsElapsed = max(1, calendar.dateComponents([.month], from: bounds.start, to: min(now, bounds.end)).month ?? 1)
            let actualTxs = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }
            let totalValueSoFar = extractor(actualTxs)
            let monthlyRate = monthsElapsed > 0 ? (totalValueSoFar / Double(monthsElapsed)) : 0
            
            let dateFormatter = SpendyDateFormatterCache.shortMonth
            
            var cumulativeValue: Double = 0
            
            var monthGuard = 0
            while current <= endMonth && monthGuard < 36 {
                monthGuard += 1
                let monthStart = current
                guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: current), monthEnd > current else { break }
                let isActual = current <= now
                
                if isActual {
                    let monthTxs = txs.filter { $0.date >= monthStart && $0.date < monthEnd }
                    let monthVol = extractor(monthTxs)
                    cumulativeValue += monthVol
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: cumulativeValue,
                        dayVolume: monthVol,
                        txCount: monthTxs.count,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now.startOfMonth
                    let monthOffset = max(1, calendar.dateComponents([.month], from: currentMonthStart, to: current).month ?? 1)
                    let predictedAmount = cumulativeValue + (monthlyRate * Double(monthOffset))
                    points.append(CategoryChartPoint(
                        id: "pred_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: predictedAmount,
                        dayVolume: monthlyRate,
                        txCount: 0,
                        isPredicted: true
                    ))
                }
                current = monthEnd
            }
            return points
        }
    }
    
    /// Extract predictive chart points (last actual + all predicted)
    static func predictiveChartPoints(from chartPoints: [CategoryChartPoint]) -> [CategoryChartPoint] {
        let actuals = chartPoints.filter { !$0.isPredicted }
        guard let lastActual = actuals.last else { return [] }
        let preds = chartPoints.filter { $0.isPredicted }
        guard !preds.isEmpty else { return [] }
        return [lastActual] + preds
    }
    
    /// Group transactions by date
    static func dateGroupedTransactions(
        from transactions: [Transaction]
    ) -> [(label: String, dayTotal: Double, transactions: [Transaction])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: transactions) { tx -> Date in
            calendar.startOfDay(for: tx.date)
        }
        
        return groups.keys.sorted(by: >).map { day -> (label: String, dayTotal: Double, transactions: [Transaction]) in
            let dayTxs = (groups[day] ?? []).sorted { $0.date > $1.date }
            let dayTotal = dayTxs.reduce(0) { $0 + $1.amount }
            
            let label: String
            if calendar.isDateInToday(day) {
                label = "Today"
            } else if calendar.isDateInYesterday(day) {
                label = "Yesterday"
            } else {
                label = SpendyDateFormatterCache.dayMonthYear.string(from: day)
            }
            return (label, dayTotal, dayTxs)
        }
    }
    
    /// Format axis label for date based on period
    static func axisLabel(for date: Date, period: ChartPeriod) -> String {
        switch period {
        case .week:
            return SpendyDateFormatterCache.shortWeekday.string(from: date)
        case .month:
            return SpendyDateFormatterCache.dayMonth.string(from: date)
        case .threeMonths, .sixMonths:
            return SpendyDateFormatterCache.shortMonth.string(from: date)
        case .year:
            return SpendyDateFormatterCache.shortMonthShortYear.string(from: date)
        }
    }
    
    /// Format time for transaction row
    static func formattedTime(_ date: Date) -> String {
        SpendyDateFormatterCache.time.string(from: date)
    }
    
    static func formattedPointDate(_ date: Date, period: ChartPeriod) -> String {
        if period == .week || period == .month {
            return SpendyDateFormatterCache.dayMonth.string(from: date)
        } else {
            return SpendyDateFormatterCache.monthYearShort.string(from: date)
        }
    }
    
    /// Discrete (non-cumulative) bars that match the home spend chart language.
    static func generateDiscreteBarPoints(
        transactions: [Transaction],
        bounds: (start: Date, end: Date),
        period: ChartPeriod,
        isCustomRange: Bool = false,
        valueForBucket: (([Transaction]) -> Double)? = nil
    ) -> [AnalyticsBarPoint] {
        let calendar = Calendar.current
        let extractor = valueForBucket ?? { $0.reduce(0) { $0 + $1.amount } }
        let start = calendar.startOfDay(for: bounds.start)
        let end = calendar.startOfDay(for: bounds.end)
        let rangeEnd = calendar.date(byAdding: .day, value: 1, to: end) ?? bounds.end
        let txs = transactions.filter { $0.date >= start && $0.date < rangeEnd }
        let bucket = barBucket(for: period, bounds: (start, end), isCustomRange: isCustomRange)
        
        var slices: [(start: Date, end: Date, label: String)] = []
        var cursor = start
        var guardCount = 0
        
        switch bucket {
        case .day:
            while cursor <= end && guardCount < 400 {
                guardCount += 1
                let next = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86_400)
                let label = (!isCustomRange && period == .week)
                    ? SpendyDateFormatterCache.shortWeekday.string(from: cursor)
                    : SpendyDateFormatterCache.dayNumber.string(from: cursor)
                slices.append((cursor, next, label))
                guard next > cursor else { break }
                cursor = next
            }
        case .week:
            while cursor <= end && guardCount < 60 {
                guardCount += 1
                let next = calendar.date(byAdding: .day, value: 7, to: cursor) ?? cursor.addingTimeInterval(86_400 * 7)
                let bucketEnd = min(next, rangeEnd)
                slices.append((cursor, bucketEnd, SpendyDateFormatterCache.dayMonth.string(from: cursor)))
                guard next > cursor else { break }
                cursor = next
            }
        case .month:
            cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: end)) ?? end
            while cursor <= endMonth && guardCount < 36 {
                guardCount += 1
                guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: cursor), monthEnd > cursor else { break }
                let bucketStart = max(cursor, start)
                let bucketEnd = min(monthEnd, rangeEnd)
                if bucketStart < bucketEnd {
                    slices.append((bucketStart, bucketEnd, SpendyDateFormatterCache.shortMonth.string(from: cursor)))
                }
                cursor = monthEnd
            }
        }
        
        return slices.map { slice in
            let sliceTxs = txs.filter { $0.date >= slice.start && $0.date < slice.end }
            return AnalyticsBarPoint(
                id: "bar_\(slice.start.timeIntervalSince1970)",
                date: slice.start,
                endDate: slice.end,
                label: slice.label,
                amount: extractor(sliceTxs),
                txCount: sliceTxs.count
            )
        }
    }
    
    private static func barBucket(
        for period: ChartPeriod,
        bounds: (start: Date, end: Date),
        isCustomRange: Bool
    ) -> AnalyticsBarBucket {
        if isCustomRange {
            let days = max(1, (Calendar.current.dateComponents([.day], from: bounds.start, to: bounds.end).day ?? 1) + 1)
            if days <= 14 { return .day }
            if days <= 80 { return .week }
            return .month
        }
        switch period {
        case .week: return .day
        case .month: return .week
        case .threeMonths, .sixMonths, .year: return .month
        }
    }
}
