import SwiftUI

/// One staged selection for Analytics: cancelling never changes the visible data.
struct AnalyticsPeriodSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var period: TimeGranularity
    @State private var date: Date
    let referenceDate: Date
    let onApply: (TimeGranularity, Date) -> Void

    init(period: TimeGranularity, date: Date, referenceDate: Date,
         onApply: @escaping (TimeGranularity, Date) -> Void) {
        _period = State(initialValue: period)
        _date = State(initialValue: min(date, referenceDate))
        self.referenceDate = referenceDate
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if period == .month {
                        SpendingMonthPicker(month: $date, latestDate: referenceDate)
                            .frame(height: 168)
                    } else {
                        DatePicker("Choose date", selection: $date, in: ...referenceDate,
                                   displayedComponents: .date)
                            .datePickerStyle(.graphical)
                        if period == .week {
                            Text("Select any date in the week you want to view.")
                                .font(.footnote).foregroundStyle(.secondary)
                        } else if period == .year {
                            Text("Select any date in the year you want to view.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Select Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(period, date)
                        dismiss()
                    }
                }
            }
        }
        .tint(SpendyColors.textPrimary)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(period == .month ? 260 : 460)])
        .presentationDragIndicator(.visible)
    }
}
