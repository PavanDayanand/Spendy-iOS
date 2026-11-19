//
//  AccountAnalyticsSheet.swift
//  Spendy
//
//  Apple HIG Bank Account Analytics Sheet.
//  Unified shared analytics architecture with live-scrubbing chart and 3 full-width sections.
//

import SwiftUI

struct AccountAnalyticsSheet: View {
    let account: Account
    var spendingScope: SpendingScope? = nil
    var isSettingsPage: Bool = false
    var periodControlMorphID: String = "periodNavCapsule"
    var calendarControlMorphID: String = "calendarMenu"
    
    var body: some View {
        SharedEntityAnalyticsSheet(
            entity: .account(account),
            isSettingsPage: isSettingsPage,
            initialType: .expense,
            spendingScope: spendingScope,
            periodControlMorphID: periodControlMorphID,
            calendarControlMorphID: calendarControlMorphID)
    }
}
