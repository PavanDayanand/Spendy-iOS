import SwiftUI

struct ReceiptNoteEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var note: String
    @FocusState private var isFocused: Bool
    let onSave: (String) -> Void

    init(note: String, onSave: @escaping (String) -> Void) {
        _note = State(initialValue: note)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
        VStack(spacing: 20) {
            TextField("Add a note", text: $note, axis: .vertical)
                .font(.body)
                .lineLimit(2...5)
                .focused($isFocused)
                .padding(16)
                .background(SpendyColors.cardBackground, in: .rect(cornerRadius: 18))
                .accessibilityIdentifier("receipt-note-input")
            Spacer(minLength: 0)
        }
        .foregroundStyle(SpendyColors.textPrimary)
        .padding(20)
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityLabel("Cancel note changes")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    HapticsManager.shared.trigger(.success)
                    onSave(note.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .accessibilityIdentifier("receipt-note-done")
            }
        }
        }
        .tint(SpendyColors.textPrimary)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(260), .large])
        .presentationDragIndicator(.visible)
        .onAppear { isFocused = true }
    }
}
