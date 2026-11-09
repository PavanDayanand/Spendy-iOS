//
//  DateRangePickerSheet.swift
//  Spendy
//
//  Apple Native Modal Sheet for selecting Custom Start Date & End Date Ranges
//

import SwiftUI

struct DateRangePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
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
            ScrollView {
            VStack(spacing: 0) {
                // Date Pickers inside Currency Converter matching card
                VStack(spacing: 0) {
                    HStack {
                        Text("Start Date")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textPrimary)
                        Spacer()
                        DatePicker(
                            "Start Date",
                            selection: $tempStartDate,
                            in: ...tempEndDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .tint(SpendyColors.primaryBlue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    Divider()
                        .background(SpendyColors.separator)
                        .padding(.leading, 16)
                    
                    HStack {
                        Text("End Date")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textPrimary)
                        Spacer()
                        DatePicker(
                            "End Date",
                            selection: $tempEndDate,
                            in: tempStartDate...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .tint(SpendyColors.primaryBlue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(SpendyColors.separator, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
                .padding(.horizontal, 20)
                
            }
            .padding(.vertical, 12)
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        HapticsManager.shared.trigger(.success)
                        startDate = tempStartDate
                        endDate = tempEndDate
                        onApply?(tempStartDate, tempEndDate)
                        dismiss()
                    }
                }
            }
        }
        .tint(SpendyColors.textPrimary)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(230)])
        .presentationDragIndicator(.visible)
    }
}
