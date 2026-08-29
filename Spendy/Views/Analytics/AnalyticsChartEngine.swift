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
        case .week: return "1w"
        case .month: return "1m"
        case .threeMonths: return "3m"
        case .sixMonths: return "6m"
        case .year: return "1y"
        }
    }
}

// MARK: - Chart Data Point
struct CategoryChartPoint: Identifiable, Equatable {
    let id: String
    let date: Date
    let label: String
    let amount: Double
    let isPredicted: Bool
    
    init(id: String = UUID().uuidString, date: Date, label: String, amount: Double, isPredicted: Bool = false) {
        self.id = id
        self.date = date
        self.label = label
        self.amount = amount
        self.isPredicted = isPredicted
    }
}

// MARK: - Shared Engine
enum AnalyticsChartEngine {
    
    /// Calculate period bounds for a given ChartPeriod
    static func periodBounds(for period: ChartPeriod) -> (start: Date, end: Date) {
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
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = period == .week ? "EEE" : "d"
            
            let daysElapsed = max(1, calendar.dateComponents([.day], from: bounds.start, to: min(today, bounds.end)).day ?? 1)
            let actualTxs = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }
            let totalValueSoFar = extractor(actualTxs)
            let dailyRate = daysElapsed > 0 ? (totalValueSoFar / Double(daysElapsed)) : 0
            
            var cumulativeValue: Double = 0
            
            while current <= endDay {
                let isActual = current <= today
                
                if isActual {
                    let dayStart = current
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: current)!
                    let dayTxs = txs.filter { $0.date >= dayStart && $0.date < dayEnd }
                    
                    cumulativeValue += extractor(dayTxs)
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: cumulativeValue,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let dayOffset = max(1, calendar.dateComponents([.day], from: today, to: current).day ?? 1)
                    let predictedAmount = cumulativeValue + (dailyRate * Double(dayOffset))
                    points.append(CategoryChartPoint(
                        id: "pred_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: predictedAmount,
                        isPredicted: true
                    ))
                }
                current = calendar.date(byAdding: .day, value: 1, to: current)!
            }
            return points
            
        case .threeMonths, .sixMonths, .year:
            var points: [CategoryChartPoint] = []
            var current = calendar.date(from: calendar.dateComponents([.year, .month], from: bounds.start))!
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: bounds.end))!
            
            let monthsElapsed = max(1, calendar.dateComponents([.month], from: bounds.start, to: min(now, bounds.end)).month ?? 1)
            let actualTxs = txs.filter { $0.date >= bounds.start && $0.date <= min(now, bounds.end) }
            let totalValueSoFar = extractor(actualTxs)
            let monthlyRate = monthsElapsed > 0 ? (totalValueSoFar / Double(monthsElapsed)) : 0
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM"
            
            var cumulativeValue: Double = 0
            
            while current <= endMonth {
                let monthStart = current
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: current)!
                let isActual = current <= now
                
                if isActual {
                    let monthTxs = txs.filter { $0.date >= monthStart && $0.date < monthEnd }
                    cumulativeValue += extractor(monthTxs)
                    points.append(CategoryChartPoint(
                        id: "actual_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: cumulativeValue,
                        isPredicted: false
                    ))
                } else if hasEnoughTxs {
                    let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                    let monthOffset = max(1, calendar.dateComponents([.month], from: currentMonthStart, to: current).month ?? 1)
                    let predictedAmount = cumulativeValue + (monthlyRate * Double(monthOffset))
                    points.append(CategoryChartPoint(
                        id: "pred_\(current.timeIntervalSince1970)",
                        date: current,
                        label: dateFormatter.string(from: current),
                        amount: predictedAmount,
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
        
        let dateFormatter = DateFormatter()
        
        return groups.keys.sorted(by: >).map { day -> (label: String, dayTotal: Double, transactions: [Transaction]) in
            let dayTxs = groups[day]!.sorted { $0.date > $1.date }
            let dayTotal = dayTxs.reduce(0) { $0 + $1.amount }
            
            let label: String
            if calendar.isDateInToday(day) {
                label = "Today"
            } else if calendar.isDateInYesterday(day) {
                label = "Yesterday"
            } else {
                dateFormatter.dateFormat = "d MMM yyyy"
                label = dateFormatter.string(from: day)
            }
            return (label, dayTotal, dayTxs)
        }
    }
    
    /// Format axis label for date based on period
    static func axisLabel(for date: Date, period: ChartPeriod) -> String {
        let fmt = DateFormatter()
        switch period {
        case .week: fmt.dateFormat = "EEE"
        case .month: fmt.dateFormat = "d MMM"
        case .threeMonths, .sixMonths: fmt.dateFormat = "MMM"
        case .year: fmt.dateFormat = "MMM yy"
        }
        return fmt.string(from: date)
    }
    
    /// Format time for transaction row
    static func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date)
    }
    
    static func formattedPointDate(_ date: Date, period: ChartPeriod) -> String {
        let fmt = DateFormatter()
        if period == .week || period == .month {
            fmt.dateFormat = "d MMM"
        } else {
            fmt.dateFormat = "MMM yyyy"
        }
        return fmt.string(from: date)
    }
}
