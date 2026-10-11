//
//  CategoryAnalyticsSheet.swift
//  Spendy
//
//  Apple HIG Category Analytics Sheet.
//  Unified shared analytics architecture with live-scrubbing chart and 3 full-width sections.
//

import AppIntents
import SwiftUI

struct CategoryAnalyticsSheet: View {
    let category: Category
    var spendingScope: SpendingScope? = nil
    var initialType: TransactionType = .expense
    var topControlsNamespace: Namespace.ID? = nil
    var backButtonMorphID: String = "topControl_left"
    var editButtonMorphID: String = "topControl_right"
    var periodControlMorphID: String = "periodNavCapsule"
    var calendarControlMorphID: String = "calendarMenu"
    var onDismiss: (() -> Void)? = nil
    
    @ViewBuilder
    var body: some View {
        if #available(iOS 27.0, *) {
            content.appEntityIdentifier(
                EntityIdentifier(for: CategoryAppEntity.self, identifier: category.id)
            )
        } else {
            content
        }
    }

    private var content: some View {
        SharedEntityAnalyticsSheet(
            entity: .category(category),
            initialType: initialType,
            spendingScope: spendingScope,
            topControlsNamespace: topControlsNamespace,
            backButtonMorphID: backButtonMorphID,
            editButtonMorphID: editButtonMorphID,
            periodControlMorphID: periodControlMorphID,
            calendarControlMorphID: calendarControlMorphID,
            onDismiss: onDismiss
        )
    }
}
