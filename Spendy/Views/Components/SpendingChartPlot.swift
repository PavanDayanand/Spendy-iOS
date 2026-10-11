import SwiftUI
import Charts
import Accessibility

/// One scale and selection system for the Home overview and spending detail.
struct SpendingChartPlot: View {
    let buckets: [SpendingChartBucket]
    let currencySymbol: String
    @Binding var selectedID: String?
    var showsLine = false
    var height: CGFloat = 150
    @Environment(\.colorSchemeContrast) private var contrast

    private var axisIDs: [String] {
        let step = max(1, Int(ceil(Double(buckets.count) / 6)))
        return buckets.enumerated().filter { $0.offset % step == 0 || $0.offset == buckets.count - 1 }.map(\.element.id)
    }

    var body: some View {
        Chart {
            ForEach(buckets) { bucket in
                if showsLine {
                    LineMark(x: .value("Period", bucket.id), y: .value("Spending", bucket.amount))
                        .interpolationMethod(.linear)
                        .foregroundStyle(SpendyColors.textPrimary)
                    PointMark(x: .value("Period", bucket.id), y: .value("Spending", bucket.amount))
                        .symbolSize(selectedID == bucket.id ? 45 : 14)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .accessibilityLabel(bucket.start.formatted(.dateTime.month(.wide).day().year()))
                        .accessibilityValue(accessibleValue(bucket))
                } else {
                    BarMark(x: .value("Period", bucket.id), y: .value("Spending", bucket.amount), width: .ratio(0.55))
                        .cornerRadius(3)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .opacity(selectedID == nil || selectedID == bucket.id ? 1 : (contrast == .increased ? 0.65 : 0.35))
                        .accessibilityLabel(bucket.start.formatted(.dateTime.month(.wide).day().year()))
                        .accessibilityValue(accessibleValue(bucket))
                }
            }
            if let selectedID, buckets.contains(where: { $0.id == selectedID }) {
                RuleMark(x: .value("Selected period", selectedID))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .accessibilityHidden(true)
            }
        }
        .chartXScale(domain: buckets.map(\.id))
        .chartYScale(domain: 0...max(1, (buckets.map(\.amount).max() ?? 0) * 1.12))
        .chartXAxis {
            AxisMarks(values: axisIDs) { value in
                AxisValueLabel {
                    if let id = value.as(String.self), let bucket = buckets.first(where: { $0.id == id }) {
                        Text(bucket.label)
                            .font(.caption2)
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(SpendyColors.separator)
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(currencySymbol + amount.formatted(.number.notation(.compactName).precision(.fractionLength(0...1))))
                            .font(.caption2)
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedID)
        .chartGesture { proxy in
            SpatialTapGesture().onEnded { value in
                proxy.selectXValue(at: value.location.x)
            }
            .simultaneously(with: DragGesture(minimumDistance: 8).onChanged { value in
                guard abs(value.translation.width) >= abs(value.translation.height) else { return }
                proxy.selectXValue(at: value.location.x)
            })
        }
        // Keep dense axis ticks legible without collisions. Full values remain
        // available through selection and the accessible chart descriptor.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityChartDescriptor(SpendingChartAccessibility(buckets: buckets, currencySymbol: currencySymbol))
        .frame(height: height)
        .accessibilityIdentifier("spending-chart")
        .onChange(of: selectedID) { old, new in
            if old != new, new != nil { HapticsManager.shared.trigger(.selection) }
        }
    }

    private func accessibleValue(_ bucket: SpendingChartBucket) -> String {
        "\(bucket.amount.formattedCurrency(symbol: currencySymbol, decimals: 2)), \(bucket.transactionCount) transactions\(bucket.isInProgress ? ", to date" : "")"
    }
}

struct SpendingChartInfoSheet: View {
    let snapshot: SpendingChartSnapshot
    let accountLabel: String
    let currencySymbol: String
    var amountsHidden = false
    var insights: [InsightMoment] = []
    var onSelectInsight: ((InsightDestination) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !amountsHidden && !insights.isEmpty {
                    Section("Spendy insights") {
                        ForEach(insights) { moment in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(moment.headline).font(.headline)
                                if let supporting = moment.supportingText {
                                    Text(supporting).font(.subheadline).foregroundStyle(.secondary)
                                }
                                if let destination = moment.destination, let onSelectInsight {
                                    Button(moment.actionTitle ?? "Explore insight") { onSelectInsight(destination) }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .accessibilityIdentifier("spending-info-insights")
                }
                Section("Reading the charts") {
                    Text("Bars and points show recorded expense totals. Taller bars or higher points mean more spending. A dashed line marks your selected period; tap Reset to return to the full total.")
                    Text("Category bar lengths compare amounts. Each percentage is that category’s share of spending for the selected account and period.")
                }
                Section("Recorded spending") {
                    Text("Expense transactions in \(accountLabel), using your app currency. Income and transfers are excluded. Future-dated transactions are included only when their date arrives.")
                    Text("The chart reflects what you’ve recorded in Spendy. A day without an entry may not mean you spent nothing.")
                }
                Section("Period") {
                    Text(snapshot.start.formatted(.dateTime.day().month(.wide).year()) + " – " + snapshot.recordedEnd.formatted(.dateTime.day().month(.wide).year()))
                    if !amountsHidden {
                        LabeledContent("Recorded total", value: snapshot.total.formattedCurrency(symbol: currencySymbol, decimals: 2))
                    }
                    Text("A period marked ‘To date’ is still in progress. Earlier periods are complete.")
                }
                Section("Comparison") {
                    Text(snapshot.isInProgress
                        ? "Compared with the same elapsed days and time in the previous \(snapshot.period.rawValue). If that period is shorter, the comparison ends at its last moment."
                        : "Compared with the complete previous \(snapshot.period.rawValue).")
                    Text(snapshot.baselineStart.formatted(.dateTime.day().month().year()) + " – " + snapshot.baselineCutoff.formatted(.dateTime.day().month().year().hour().minute()))
                    if !amountsHidden {
                        LabeledContent("Previous spending", value: snapshot.baselineTotal.formattedCurrency(symbol: currencySymbol, decimals: 2))
                    }
                    Text("‘Less spent’ describes recorded expenses, not money saved. Refunds recorded as income do not reduce this expense total.")
                }
            }
            .navigationTitle("About spending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .tint(SpendyColors.textPrimary)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct SpendingChartAccessibility: AXChartDescriptorRepresentable {
    let buckets: [SpendingChartBucket]
    let currencySymbol: String

    func makeChartDescriptor() -> AXChartDescriptor {
        let labels = buckets.map { $0.start.formatted(.dateTime.day().month(.wide).year().hour().minute()) }
        let xAxis = AXCategoricalDataAxisDescriptor(title: "Period starting", categoryOrder: labels)
        let maximum = max(1, buckets.map(\.amount).max() ?? 0)
        let symbol = currencySymbol
        let yAxis = AXNumericDataAxisDescriptor(title: "Recorded spending", range: 0...maximum, gridlinePositions: []) {
            $0.formattedCurrency(symbol: symbol, decimals: 2)
        }
        let points = zip(labels, buckets).map { label, bucket in
            AXDataPoint(x: label, y: bucket.amount,
                label: "\(bucket.transactionCount) transactions\(bucket.isInProgress ? ", to date" : "")")
        }
        return AXChartDescriptor(title: "Recorded spending",
            summary: "Expense totals by period. Any current period includes only spending recorded to date.",
            xAxis: xAxis, yAxis: yAxis,
            series: [AXDataSeriesDescriptor(name: "Expenses", isContinuous: false, dataPoints: points)])
    }
}
