import SwiftUI
import UIKit

/// Apple's date picker in its month and year mode.
struct SpendingMonthPicker: UIViewRepresentable {
    @Binding var month: Date
    let latestDate: Date

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .wheels
        picker.datePickerMode = .yearAndMonth
        picker.accessibilityIdentifier = "spending-month-picker"
        picker.addTarget(context.coordinator, action: #selector(Coordinator.selectMonth(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        context.coordinator.month = $month
        picker.maximumDate = latestDate
        let date = min(month, latestDate)
        if !Calendar.current.isDate(picker.date, equalTo: date, toGranularity: .month) {
            picker.setDate(date, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(month: $month)
    }

    final class Coordinator: NSObject {
        var month: Binding<Date>

        init(month: Binding<Date>) {
            self.month = month
        }

        @objc func selectMonth(_ picker: UIDatePicker) {
            month.wrappedValue = SpendingPeriodFilter(month: picker.date).month
        }
    }
}

struct SpendingPeriodFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var month: Date
    let referenceDate: Date
    let onApply: (SpendingPeriodFilter) -> Void

    init(month: Date, referenceDate: Date, onApply: @escaping (SpendingPeriodFilter) -> Void) {
        _month = State(initialValue: min(month, referenceDate))
        self.referenceDate = referenceDate
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            SpendingMonthPicker(month: $month, latestDate: referenceDate)
                .frame(height: 168)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .navigationTitle("Select Month")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            onApply(SpendingPeriodFilter(month: month))
                            dismiss()
                        }
                    }
                }
        }
        .tint(SpendyColors.textPrimary)
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    }
}
