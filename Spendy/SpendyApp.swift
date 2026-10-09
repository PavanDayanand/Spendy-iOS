//
//  SpendyApp.swift
//  Spendy
//

import AppIntents
import CoreSpotlight
import SwiftUI

final class SpendyAppDelegate: NSObject, UIApplicationDelegate {
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
        #if DEBUG
        Task { @MainActor in
            SmartInsightsUnitTests.runAllTests()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(quickActionManager)
                .environment(\.isMonoIconMode, store.isMonoIconMode)
                .preferredColorScheme(store.colorScheme)
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
            }
        }
    }

    @MainActor
    private func activateSpendySystemIntegrations() {
        store.ingestPendingWidgetTransactions()
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
