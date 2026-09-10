//
//  SpendyControlWidgets.swift
//  SpendyWidgets
//
//  Control Center, Lock Screen, and Action Button controls.
//

import AppIntents
import SwiftUI
import WidgetKit

struct SpendyLogControl: ControlWidget {
    static let kind = "com.Spendy.control.logTransaction"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: LogTransactionIntent()) {
                Label("Log Transaction", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Log Transaction")
        .description("Choose expense or income, then category, then amount.")
    }
}

struct SpendyQuickAddControl: ControlWidget {
    static let kind = "com.Spendy.control.quickAdd"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: QuickAddExpenseIntent()) {
                Label("Quick Add", systemImage: "plus")
            }
        }
        .displayName("Quick Add")
        .description("Open Spendy’s keypad to log a transaction.")
    }
}
