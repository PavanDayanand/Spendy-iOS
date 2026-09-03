//
//  SpendyApp.swift
//  Spendy
//
//  Created by Pavan D on 19/8/26.
//

import SwiftUI

@main
struct SpendyApp: App {
    @State private var store = ExpenseStore()
    
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
                .environment(\.isMonoIconMode, store.isMonoIconMode)
                .preferredColorScheme(store.colorScheme)
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
        return viewControllers.count > 1
    }
}
