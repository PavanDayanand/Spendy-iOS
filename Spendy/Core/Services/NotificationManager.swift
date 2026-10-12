import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private var syncTask: Task<Void, Never>?
    private override init() { super.init() }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func refresh(from store: ExpenseStore) {
        let previous = syncTask
        previous?.cancel()
        let plans = SpendyNotificationPlan.build(transactions: store.transactions, subscriptions: store.subscriptions,
            currencyCode: store.currencyCode, bills: store.notificationsEnabled,
            weekly: store.weeklySummaryEnabled, logging: store.loggingRemindersEnabled,
            budget: store.budget, budgetStart: store.budgetCycleStart(), budgetEnd: store.budgetCycleEnd(),
            budgetAlerts: store.budgetAlertsEnabled)
        syncTask = Task {
            await previous?.value
            guard !Task.isCancelled else { return }
            let pending = await center.pendingNotificationRequests()
            guard !Task.isCancelled else { return }
            let ownedIDs = pending.map(\.identifier).filter {
                $0.hasPrefix("spendy.") || $0.hasPrefix("sub_reminder_") || $0.hasPrefix("budget_alert_")
            }
            let validIDs = Set(plans.map(\.id))
            func isAttention(_ id: String) -> Bool { id.hasPrefix("spendy.bill.") || id.hasPrefix("spendy.budget.") }
            let obsolete = ownedIDs.filter { !isAttention($0) || !validIDs.contains($0) }
            // Remove reservations before cancelling pending work so a quick toggle can re-arm it safely.
            let previousHistory = Set(UserDefaults.standard.stringArray(forKey: "spendy.deliveredAttentionIDs") ?? [])
            UserDefaults.standard.set(Array(previousHistory.subtracting(obsolete.filter(isAttention))), forKey: "spendy.deliveredAttentionIDs")
            center.removePendingNotificationRequests(withIdentifiers: obsolete)
            let status = await checkAuthorizationStatus()
            guard !Task.isCancelled else { return }
            guard [.authorized, .provisional, .ephemeral].contains(status) else {
                center.removePendingNotificationRequests(withIdentifiers: ownedIDs)
                let history = Set(UserDefaults.standard.stringArray(forKey: "spendy.deliveredAttentionIDs") ?? [])
                UserDefaults.standard.set(Array(history.subtracting(ownedIDs.filter(isAttention))), forKey: "spendy.deliveredAttentionIDs")
                return
            }
            let deliveredIDs = Set(await center.deliveredNotifications().map { $0.request.identifier })
            var scheduledAttention = Set(UserDefaults.standard.stringArray(forKey: "spendy.deliveredAttentionIDs") ?? [])
            scheduledAttention.formUnion(deliveredIDs.filter(isAttention))
            // A cancelled pending reminder was never delivered and may be enabled again later.
            scheduledAttention.subtract(obsolete.filter(isAttention))
            func saveAttentionHistory() {
                let cutoff = Date().addingTimeInterval(-90 * 86400).timeIntervalSince1970
                scheduledAttention = Set(scheduledAttention.filter { id in
                    let parts = id.split(separator: ".")
                    let index = id.hasPrefix("spendy.bill.") ? 3 : 2
                    return parts.count > index && (Double(parts[index]) ?? 0) >= cutoff
                })
                UserDefaults.standard.set(Array(scheduledAttention), forKey: "spendy.deliveredAttentionIDs")
            }
            saveAttentionHistory()
            for plan in plans {
                let existing = pending.first { $0.identifier == plan.id }
                if isAttention(plan.id) {
                    if AttentionNotificationPolicy.shouldSuppress(id: plan.id, history: scheduledAttention, hasPending: existing != nil) {
                        if existing != nil { center.removePendingNotificationRequests(withIdentifiers: [plan.id]) }
                        continue
                    }
                    if let existing, existing.content.title == plan.title && existing.content.body == plan.body { continue }
                }
                guard !Task.isCancelled else { return }
                let content = UNMutableNotificationContent()
                content.title = plan.title
                content.body = plan.body
                content.sound = .default
                content.threadIdentifier = plan.id.hasPrefix("spendy.bill") ? "spendy.bills" : plan.id.hasPrefix("spendy.budget") ? "spendy.budget" : "spendy.checkins"
                content.userInfo = ["url": plan.url]
                let deliveryDate = isAttention(plan.id) ? AttentionNotificationPolicy.deliveryDate(proposed: plan.date, pending: (existing?.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()) : plan.date
                var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: deliveryDate)
                if let weekday = plan.repeatingWeekday { components = DateComponents(hour: 20, minute: 0, weekday: weekday) }
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: plan.repeatingWeekday != nil)
                do {
                    try await center.add(UNNotificationRequest(identifier: plan.id, content: content, trigger: trigger))
                    if isAttention(plan.id) { scheduledAttention.insert(plan.id); saveAttentionHistory() }
                }
                catch { print("Could not schedule Spendy notification: \(error.localizedDescription)") }
            }
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse) async {
        guard let rawURL = response.notification.request.content.userInfo["url"] as? String,
              let url = URL(string: rawURL) else { return }
        await MainActor.run { QuickActionManager.shared.handleURL(url) }
    }
}
