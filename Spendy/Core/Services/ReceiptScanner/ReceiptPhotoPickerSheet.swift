import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// The native Photos/Albums browser inside a camera-sized floating panel.
struct ReceiptPhotoPickerSheet: View {
    let onSelect: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDetent: PresentationDetent = .fraction(0.72)
    @State private var loading = false
    @State private var loadProgress: Progress?
    @State private var importError: String?
    @State private var isActive = false

    var body: some View {
        ZStack(alignment: .top) {
            ReceiptPhotoGrid(onPick: loadPhoto, onCancel: { dismiss() })
                .disabled(loading)
                .overlay {
                    if loading {
                        ZStack {
                            Color.black.opacity(0.55)
                            ProgressView("Opening photo…").tint(.white).foregroundStyle(.white)
                        }
                    }
                }
            // Let the system sheet pan from the header around the native tabs.
            // The remote Photos controller otherwise consumes these touches.
            VStack(spacing: 0) {
                Color.black.opacity(0.001).frame(height: 18)
                HStack(spacing: 0) {
                    Color.black.opacity(0.001)
                    Color.clear.frame(width: 200).allowsHitTesting(false)
                    Color.black.opacity(0.001)
                }
                .frame(height: 56)
            }
            .accessibilityHidden(true)
        }
        .overlay(alignment: .topLeading) {
            GlassCircleButton(size: 44, accessibilityLabel: "Cancel", action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.leading, 12)
            .padding(.top, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("receipt-photo-panel")

        .ignoresSafeArea(.container, edges: .bottom)
        .presentationDetents([.fraction(0.72), .large], selection: $selectedDetent)
        .presentationContentInteraction(.resizes)
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(uiColor: .systemBackground))
        .onAppear { isActive = true }
        .onDisappear {
            isActive = false
            loadProgress?.cancel()
        }
        .alert("Receipt image", isPresented: Binding(
            get: { importError != nil }, set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: { Text(importError ?? "") }
    }

    private func loadPhoto(_ provider: NSItemProvider) {
        guard !loading else { return }
        loading = true
        loadProgress = provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            Task { @MainActor in
                guard isActive else { return }
                loading = false
                guard let data, let image = UIImage(data: data) else {
                    importError = "That photo could not be opened. Choose another receipt or screenshot."
                    return
                }
                onSelect(image)
                dismiss()
            }
        }
    }
}
