//
//  CategoryAnalyticsSheet.swift
//  Spendy
//
//  Apple HIG Category Analytics Sheet.
//  Unified shared analytics architecture with live-scrubbing chart and 3 full-width sections.
//

import SwiftUI

struct CategoryAnalyticsSheet: View {
    let category: Category
    var initialType: TransactionType = .expense
    var topControlsNamespace: Namespace.ID? = nil
    var backButtonMorphID: String = "topControl_left"
    var editButtonMorphID: String = "topControl_right"
    var periodControlMorphID: String = "periodNavCapsule"
    var calendarControlMorphID: String = "calendarMenu"
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        SharedEntityAnalyticsSheet(
            entity: .category(category),
            initialType: initialType,
            topControlsNamespace: topControlsNamespace,
            backButtonMorphID: backButtonMorphID,
            editButtonMorphID: editButtonMorphID,
            periodControlMorphID: periodControlMorphID,
            calendarControlMorphID: calendarControlMorphID,
            onDismiss: onDismiss
        )
    }
}
