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
        VStack(spacing: 20) {
            HStack {
                GlassCircleButton(icon: "xmark", size: 44, iconSize: 14,
                    accessibilityLabel: "Cancel note changes") { dismiss() }
                Spacer()
                Text("Note").font(.headline)
                Spacer()
                Button("Done") {
                    onSave(note.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .font(.body.weight(.semibold))
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityIdentifier("receipt-note-done")
            }
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
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(260), .large])
        .presentationDragIndicator(.visible)
        .onAppear { isFocused = true }
    }
}
