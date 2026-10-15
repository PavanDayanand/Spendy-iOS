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
    var topControlsNamespace: Namespace.ID? = nil
    var sharedNavigationHeader: AnalyticsNavigationHeaderState? = nil
    var backButtonMorphID: String = "topControl_left"
    var editButtonMorphID: String = "topControl_right"
    var periodControlMorphID: String = "periodNavCapsule"
    var calendarControlMorphID: String = "calendarMenu"
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        SharedEntityAnalyticsSheet(
            entity: .account(account),
            isSettingsPage: isSettingsPage,
            initialType: .expense,
            spendingScope: spendingScope,
            topControlsNamespace: topControlsNamespace,
            sharedNavigationHeader: sharedNavigationHeader,
            backButtonMorphID: backButtonMorphID,
            editButtonMorphID: editButtonMorphID,
            periodControlMorphID: periodControlMorphID,
            calendarControlMorphID: calendarControlMorphID,
            onDismiss: onDismiss
        )
    }
}
