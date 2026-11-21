import SwiftUI

/// A monthly report printed onto a shareable strip of paper.
struct ReceiptPrinterSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var showsMonthPicker = false
    @State private var printSequence = 0
    @State private var shareImage: Image?
    @State private var sharedReport: MonthlyReceiptSnapshot?

    private var snapshot: MonthlyReceiptSnapshot {
        MonthlyReceiptSnapshot(month: selectedMonth, transactions: store.transactions,
            categories: store.categories, currencySymbol: store.currencySymbol)
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
    }

    var body: some View {
        let report = snapshot
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 14) {
                        MonthlyReceiptPrinter(snapshot: report, printSequence: printSequence)
                            .id("monthly-printer")

                    }
                    .frame(maxWidth: 380)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .accessibilityIdentifier("monthly-receipt-scroll")
                .safeAreaBar(edge: .top, spacing: 0) {
                    monthControls
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                }
                .onChange(of: printSequence) { _, _ in
                    if !reduceMotion { proxy.scrollTo("monthly-printer", anchor: .top) }
                }
            }
            .navigationTitle("Monthly Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let shareImage, sharedReport == report {
                        ShareLink(item: shareImage,
                            preview: SharePreview("Monthly Receipt — \(report.title)", image: shareImage)) {
                            Label("Share receipt", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("monthly-receipt-share")
                    }
                }
            }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showsMonthPicker) {
            SpendingPeriodFilterSheet(month: selectedMonth, referenceDate: .now) { period in
                selectedMonth = Calendar.current.dateInterval(of: .month, for: period.month)?.start ?? period.month
            }
        }
        .task(id: report) {
            guard !Task.isCancelled else { return }
            renderShareImage(report)

        }
    }

    private var monthControls: some View {
        HStack(spacing: 12) {
            Button {
                showsMonthPicker = true
            } label: {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        Text(selectedMonth.formatted(.dateTime.month(.abbreviated).year()))
                    } else {
                        Label(snapshot.title, systemImage: "calendar")
                    }
                }
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .buttonSizing(.flexible)
            .controlSize(.large)
            .accessibilityLabel("Choose receipt month, \(snapshot.title)")
            .accessibilityIdentifier("monthly-receipt-month-picker")


        }
        .frame(maxWidth: 240)
        .frame(maxWidth: .infinity)
    }

    private func changeMonth(by offset: Int) {
        guard let month = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonth) else { return }
        selectedMonth = month
        HapticsManager.shared.trigger(.selection)
    }

    @MainActor private func renderShareImage(_ report: MonthlyReceiptSnapshot) {
        let renderer = ImageRenderer(content: MonthlyReceiptPaper(snapshot: report)
            .frame(width: 360).dynamicTypeSize(.medium))
        renderer.scale = 3
        shareImage = renderer.uiImage.map { Image(uiImage: $0) }
        sharedReport = report
    }
}
