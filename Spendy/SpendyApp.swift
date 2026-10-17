//
//  SpendyApp.swift
//  Spendy
//

import AppIntents
import CoreSpotlight
import SwiftUI
import TipKit
import UserNotifications

final class SpendyAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            Task { @MainActor in
                QuickActionManager.shared.handleShortcutItem(shortcutItem)
            }
        }
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SpendySceneDelegate.self
        return config
    }
}

final class SpendySceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Task { @MainActor in
            QuickActionManager.shared.handleShortcutItem(shortcutItem)
            completionHandler(true)
        }
    }
}

@main
struct SpendyApp: App {
    @UIApplicationDelegateAdaptor(SpendyAppDelegate.self) private var appDelegate
    @State private var store = ExpenseStore.shared
    @State private var quickActionManager = QuickActionManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            #if DEBUG
            let environment = ProcessInfo.processInfo.environment
            if let tip = environment["SPENDY_UI_TEST_TIP"] {
                // Dedicated tip tests use an isolated store, never the user's tip history.
                let location = FileManager.default.temporaryDirectory.appendingPathComponent("tip-test-\(UUID().uuidString)")
                try Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.url(location))])
                let tips: [String: any Tip.Type] = [
                    "analytics": HomeAnalyticsTip.self,
                    "home-insight": HomeInsightTip.self,
                    "category-chart": CategoryChartTip.self,
                    "category-insight": CategoryNextInsightTip.self,
                    "subscription": SubscriptionActionsTip.self
                ]
                let selected: [any Tip.Type] = switch tip {
                case "home-sequence": [HomeAnalyticsTip.self, HomeInsightTip.self]
                case "category-sequence": [CategoryChartTip.self, CategoryNextInsightTip.self]
                default: tips[tip].map { [$0] } ?? []
                }
                Tips.hideTipsForTesting(tips.values.filter { candidate in
                    !selected.contains { ObjectIdentifier($0) == ObjectIdentifier(candidate) }
                })
                Tips.showTipsForTesting(selected)
            } else {
                try Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
                if environment["SPENDY_UI_TEST_MODE"] != nil { Tips.hideAllTipsForTesting() }
            }
            #else
            try Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
            #endif
        } catch {
            #if DEBUG
            print("TipKit configuration failed: \(error)")
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(quickActionManager)
                .environment(\.isMonoIconMode, store.isMonoIconMode)
                .preferredColorScheme(store.colorScheme)
                .toggleStyle(SpendySwitchStyle())
                .onOpenURL { url in
                    quickActionManager.handleURL(url)
                }
                .onAppear {
                    activateSpendySystemIntegrations()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                activateSpendySystemIntegrations()
            } else {
                store.flushPendingSave()
            }
        }
    }

    @MainActor
    private func activateSpendySystemIntegrations() {
        SpendyLiveActivityManager.shared.endAllLiveActivities()
        guard store.systemIntegrationsEnabled else { return }
        store.ingestPendingWidgetTransactions()
        store.ingestSharedReceipts()
        WidgetDataManager.shared.publish(from: store)
        SpendyShortcutsProvider.updateAppShortcutParameters()
        indexCategoriesForSiri()
        quickActionManager.registerDynamicShortcuts()
        if WidgetDataManager.shared.consumePendingQuickAdd() {
            quickActionManager.triggerQuickAdd()
        }
    }

    @MainActor
    private func indexCategoriesForSiri() {
        let categories = WidgetDataManager.shared.loadCategories()
            .filter { !$0.isHidden }
            .map {
                CategoryAppEntity(
                    id: $0.id,
                    name: $0.name,
                    sfSymbol: $0.sfSymbol,
                    colorHex: $0.colorHex,
                    isExpense: $0.isExpense
                )
            }
        Task {
            let index = CSSearchableIndex(name: "SpendyCategories")
            do {
                try await index.deleteAppEntities(ofType: CategoryAppEntity.self)
                try await index.indexAppEntities(categories)
            } catch {
                #if DEBUG
                print("Category indexing for Siri failed: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Re-enable Apple Native Interactive Left-Edge Swipe Back Gesture for Custom Back Buttons
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
        return viewControllers.count > 1
    }
}
