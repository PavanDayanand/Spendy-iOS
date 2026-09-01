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
        ZStack {
            VStack(spacing: 0) {
                // Header (Cancel | Select Date Range | Apply)
                HStack {
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(SpendyColors.separator, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Select Date Range")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticsManager.shared.trigger(.success)
                        startDate = tempStartDate
                        endDate = tempEndDate
                        onApply?(tempStartDate, tempEndDate)
                        dismiss()
                    }) {
                        Text("Apply")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(SpendyColors.primaryBlue, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Date Pickers inside Currency Converter matching card
                VStack(spacing: 0) {
                    HStack {
                        Text("Start Date")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textPrimary)
                        Spacer()
                        DatePicker(
                            "",
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
                            "",
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
                
                Spacer()
            }
        }
        .presentationDetents([.height(230)])
        .presentationDragIndicator(.visible)
    }
}
