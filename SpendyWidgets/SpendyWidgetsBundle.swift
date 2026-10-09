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
        SpendyQuickActionsWidget()
        SpendyWeekWidget()
        SpendyCategoriesWidget()
        SpendyOverviewWidget()
        SpendyLockWidget()
        SpendyLogControl()
        SpendyQuickAddControl()
        SpendyBudgetLiveActivity()
    }
}
