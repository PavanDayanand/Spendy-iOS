import Foundation

enum InsightComparison {
    static func baselineEnd(context: AnalyticsInsightContext, calendar: Calendar = .current) -> Date {
        guard context.isPeriodInProgress else { return context.baselineEndDate }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: context.startDate),
                                          to: calendar.startOfDay(for: context.referenceDate)).day ?? 0
        let day = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: context.baselineStartDate)) ?? context.baselineStartDate
        let time = calendar.dateComponents([.hour, .minute, .second], from: context.referenceDate)
        let end = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0,
                                second: time.second ?? 0, of: day) ?? day
        let fractionalSecond = context.referenceDate.timeIntervalSince1970 - floor(context.referenceDate.timeIntervalSince1970)
        return min(end.addingTimeInterval(fractionalSecond), context.baselineEndDate)
    }

    static func baselineSpending(facts: InsightFacts, categoryID: String? = nil) -> Double {
        let end = baselineEnd(context: facts.context)
        return facts.transactions.filter {
            $0.type == .expense && $0.date >= facts.baselineStart && $0.date <= end
                && (categoryID == nil || $0.categoryId == categoryID)
        }.reduce(0) { $0 + $1.amount }
    }
}
