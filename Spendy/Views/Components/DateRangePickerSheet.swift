//
//  DateRangePickerSheet.swift
//  Spendy
//
//  Apple Native Modal Sheet for selecting Custom Start Date & End Date Ranges
//

import SwiftUI

struct DateRangePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var startDate: Date
    @Binding var endDate: Date
    var onApply: ((Date, Date) -> Void)? = nil
    
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    
    init(
        startDate: Binding<Date>,
        endDate: Binding<Date>,
        onApply: ((Date, Date) -> Void)? = nil
    ) {
        self._startDate = startDate
        self._endDate = endDate
        self.onApply = onApply
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Start Date",
                        selection: $tempStartDate,
                        in: ...tempEndDate,
                        displayedComponents: .date
                    )
                    
                    DatePicker(
                        "End Date",
                        selection: $tempEndDate,
                        in: tempStartDate...Date(),
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        HapticsManager.shared.trigger(.selection)
                        startDate = tempStartDate
                        endDate = tempEndDate
                        onApply?(tempStartDate, tempEndDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(260), .medium])
        .presentationDragIndicator(.visible)
    }
}
