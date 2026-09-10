//
//  SpendyWidgetsBundle.swift
//  SpendyWidgets
//

import SwiftUI
import WidgetKit

@main
struct SpendyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SpendyTodayWidget()
        SpendyBudgetWidget()
        SpendyWeekWidget()
        SpendyLockWidget()
        SpendyLogControl()
        SpendyQuickAddControl()
    }
}
