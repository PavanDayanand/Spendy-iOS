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
    var transactionType: TransactionType = .expense
    @Environment(\.colorSchemeContrast) private var contrast

    private var axisIDs: [String] {
        let step = max(1, Int(ceil(Double(buckets.count) / 6)))
        return buckets.enumerated().filter { $0.offset % step == 0 || $0.offset == buckets.count - 1 }.map(\.element.id)
    }

    var body: some View {
        Chart {
            ForEach(buckets) { bucket in
                if showsLine {
                    LineMark(x: .value("Period", bucket.id), y: .value(transactionType == .income ? "Income" : "Spending", bucket.amount))
                        .interpolationMethod(.linear)
                        .foregroundStyle(SpendyColors.textPrimary)
                    PointMark(x: .value("Period", bucket.id), y: .value(transactionType == .income ? "Income" : "Spending", bucket.amount))
                        .symbolSize(selectedID == bucket.id ? 45 : 14)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .accessibilityLabel(bucket.start.formatted(.dateTime.month(.wide).day().year()))
                        .accessibilityValue(accessibleValue(bucket))
                } else {
                    BarMark(x: .value("Period", bucket.id), y: .value(transactionType == .income ? "Income" : "Spending", bucket.amount), width: .ratio(0.68))
                        .cornerRadius(5)
                        .foregroundStyle(LinearGradient(colors: [SpendyColors.textPrimary, SpendyColors.textPrimary.opacity(0.55)], startPoint: .top, endPoint: .bottom))
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
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
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
        .spendyHoldPreview(selection: $selectedID)
        // Keep dense axis ticks legible without collisions. Full values remain
        // available through selection and the accessible chart descriptor.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityChartDescriptor(SpendingChartAccessibility(buckets: buckets, currencySymbol: currencySymbol, transactionType: transactionType))
        .chartOverlay { proxy in
            if selectedID != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedID = nil
                        HapticsManager.shared.trigger(.selection)
                    }
            }
        }
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
    var insightsOnly = false
    var onSelectInsight: ((InsightDestination) -> Void)? = nil
    var onViewSpending: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !insights.isEmpty {
                    let priority = insights.filter { $0.attentionPriority > 0 }
                    let remaining = insights.filter { $0.attentionPriority == 0 }
                    if !priority.isEmpty {
                        Section("Needs your attention") {
                            insightRows(priority)
                        }
                        .accessibilityIdentifier("spending-info-priority")
                    }
                    if !remaining.isEmpty {
                        Section {
                            insightRows(remaining)
                        } header: {
                            SpendyInsightBrandMark(style: .kicker)
                                .textCase(nil)
                                .padding(.vertical, 6)
                        }
                        .accessibilityIdentifier("spending-info-insights")
                    }
                }
                if insightsOnly && insights.isEmpty {
                    Section {
                        Text("Keep recording expenses to discover personalized insights from your activity.")
                    }
                }
                if insightsOnly, let onViewSpending {
                    Section { Button("View spending details", action: onViewSpending) }
                }
                if !insightsOnly {
                Section("Reading the charts") {
                    Text("Bars and points show recorded expense totals. Taller bars or higher points mean more spending. Hold a chart to preview a period, then slide to explore. Release to return to the full total.")
                    Text("Category rows show recorded expense counts and totals for the selected account and period.")
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
            }
            .navigationTitle(insightsOnly ? "Spendy insights" : "About spending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .tint(SpendyColors.textPrimary)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func insightRows(_ moments: [InsightMoment]) -> some View {
        ForEach(moments) { moment in
            VStack(alignment: .leading, spacing: 6) {
                ShinyHeadlineText(headline: amountsHidden ? InsightMoment.concealedText(moment.headline) : moment.headline, emphasis: amountsHidden ? [] : moment.emphasis, font: .headline, emphasisFont: .headline.bold())
                if let supporting = moment.supportingText {
                    InsightSupportingText(text: amountsHidden ? InsightMoment.concealedText(supporting) : supporting, emphasis: amountsHidden ? [] : moment.emphasis, font: .subheadline)
                }
                if let destination = moment.destination, let onSelectInsight {
                    Button(amountsHidden ? InsightMoment.concealedText(moment.actionTitle ?? "Explore insight") : (moment.actionTitle ?? "Explore insight")) { onSelectInsight(destination) }
                }
            }
            .padding(.vertical, 4)
        }
    }

}

private struct SpendingChartAccessibility: AXChartDescriptorRepresentable {
    let transactionType: TransactionType

    init(buckets: [SpendingChartBucket], currencySymbol: String, transactionType: TransactionType) {
        self.buckets = buckets
        self.currencySymbol = currencySymbol
        self.transactionType = transactionType
    }
    let buckets: [SpendingChartBucket]
    let currencySymbol: String

    func makeChartDescriptor() -> AXChartDescriptor {
        let labels = buckets.map { $0.start.formatted(.dateTime.day().month(.wide).year().hour().minute()) }
        let xAxis = AXCategoricalDataAxisDescriptor(title: "Period starting", categoryOrder: labels)
        let maximum = max(1, buckets.map(\.amount).max() ?? 0)
        let symbol = currencySymbol
        let yAxis = AXNumericDataAxisDescriptor(title: transactionType == .income ? "Recorded income" : "Recorded spending", range: 0...maximum, gridlinePositions: []) {
            $0.formattedCurrency(symbol: symbol, decimals: 2)
        }
        let points = zip(labels, buckets).map { label, bucket in
            AXDataPoint(x: label, y: bucket.amount,
                label: "\(bucket.transactionCount) transactions\(bucket.isInProgress ? ", to date" : "")")
        }
        return AXChartDescriptor(title: transactionType == .income ? "Recorded income" : "Recorded spending",
            summary: "\(transactionType == .income ? "Income" : "Expense") totals by period, recorded to date.",
            xAxis: xAxis, yAxis: yAxis,
            series: [AXDataSeriesDescriptor(name: transactionType == .income ? "Income" : "Expenses", isContinuous: false, dataPoints: points)])
    }
}


/// Chart previews last only while holding; release or cancellation restores the overview.
private struct SpendyHoldPreviewModifier: ViewModifier {
    @Binding var selection: String?
    @GestureState private var isHolding = false

    func body(content: Content) -> some View {
        content
            .chartGesture { proxy in
                LongPressGesture(minimumDuration: 0.2, maximumDistance: 12)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .updating($isHolding) { value, state, _ in
                        if case .second(true, _) = value { state = true }
                    }
                    .onChanged { value in
                        if case .second(true, let drag?) = value {
                            proxy.selectXValue(at: drag.location.x)
                        }
                    }
                    .onEnded { _ in selection = nil }
            }
            .onChange(of: isHolding) { _, holding in
                if !holding { selection = nil }
            }
            .accessibilityHint("Hold and slide to preview a period. Release to return to the total.")
    }
}

extension View {
    func spendyHoldPreview(selection: Binding<String?>) -> some View {
        modifier(SpendyHoldPreviewModifier(selection: selection))
    }
}
