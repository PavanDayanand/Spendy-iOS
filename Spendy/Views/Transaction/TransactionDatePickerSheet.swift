import SwiftUI

/// Transaction and receipt date selection using the system calendar control.
struct TransactionDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var selectedDate: Date

    var body: some View {
        NavigationStack {
            ScrollView {
                DatePicker("Transaction date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accessibilityIdentifier("transaction-date-picker")
                    .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Today") { selectedDate = .now }
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(460), .large])
        .presentationDragIndicator(.visible)
        .onChange(of: selectedDate) { _, _ in dismiss() }
    }
}
