import ActivityKit

@MainActor
final class SpendyLiveActivityManager {
    static let shared = SpendyLiveActivityManager()
    private init() {}

    /// Remove activities created before the feature was retired.
    func endAllLiveActivities() {
        Task {
            for activity in Activity<BudgetPacingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
