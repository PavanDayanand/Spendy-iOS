import SwiftUI
import TipKit

// Each hint is retired after its first display or after the feature is used.
protocol SpendyFeatureTip: Tip {}
extension SpendyFeatureTip {
    var options: [any TipOption] { [MaxDisplayCount(1)] }
}

struct HomeAnalyticsTip: SpendyFeatureTip {
    @Parameter(.transient) static var hasSpending: Bool = false
    var title: Text { Text("Explore your spending") }
    var message: Text? { Text("See your spending by category and time period.") }
    var rules: [Rule] { #Rule(Self.$hasSpending) { $0 } }
}

struct HomeInsightTip: SpendyFeatureTip {
    var title: Text { Text("Look closer") }
    var message: Text? { Text("Tap a spending insight to see more detail.") }
}

struct CategoryChartTip: SpendyFeatureTip {
    @Parameter(.transient) static var hasChartData: Bool = false
    var title: Text { Text("Inspect your spending") }
    var message: Text? { Text("Touch and drag across the chart to inspect each date.") }
    var rules: [Rule] { #Rule(Self.$hasChartData) { $0 } }
}

struct CategoryNextInsightTip: SpendyFeatureTip {
    var title: Text { Text("See another insight") }
    var message: Text? { Text("Tap here to see another insight for this category.") }
}

struct SubscriptionActionsTip: SpendyFeatureTip {
    var title: Text { Text("Manage your subscription") }
    var message: Text? { Text("Touch and hold a subscription to edit, pause, or cancel tracking.") }
}

private struct SpendyTipsAllowedKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var spendyTipsAllowed: Bool {
        get { self[SpendyTipsAllowedKey.self] }
        set { self[SpendyTipsAllowedKey.self] = newValue }
    }
}
