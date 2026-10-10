import SwiftUI
import UserNotifications

struct NotificationPreferencesView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Group {
            Form {
                Section {
                    Toggle("Bill reminders", isOn: preference(\.notificationsEnabled))
                } footer: { Text("At 9 AM the day before, on the due day, and once three days later if the payment is still unrecorded. Logging, pausing, or cancelling updates the reminders.") }
                Section {
                    Toggle("Weekly summary", isOn: preference(\.weeklySummaryEnabled))
                } footer: {
                    Text("Sunday at 8 PM. A quiet spending check-in. Any amount shown is a dated snapshot of your recorded expenses; open Spendy for the latest totals. The next eight weeks are scheduled and refreshed when you use the app.")
                }
                Section {
                    Toggle("Logging reminders", isOn: preference(\.loggingRemindersEnabled))
                } footer: { Text("Tuesday and Friday at 8 PM. A gentle prompt to record anything you missed. All times are local.") }
                if status == .denied {
                    Section {
                        Button("Open Notification Settings") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    } footer: { Text("Notifications are blocked by iOS. Enable them in Settings to receive your chosen reminders.") }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SpendyColors.settingsBackground)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .task { status = await NotificationManager.shared.checkAuthorizationStatus() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { status = await NotificationManager.shared.checkAuthorizationStatus() } }
            }
        }
        .tint(SpendyColors.controlAccent)
    }

    private func preference(_ key: ReferenceWritableKeyPath<ExpenseStore, Bool>) -> Binding<Bool> {
        Binding(get: { store[keyPath: key] }, set: { enabled in
            store[keyPath: key] = enabled
            HapticsManager.shared.trigger(.selection)
            Task {
                if enabled { _ = await NotificationManager.shared.requestAuthorization() }
                status = await NotificationManager.shared.checkAuthorizationStatus()
                NotificationManager.shared.refresh(from: store)
            }
        })
    }
}
