//
//  ReceiptScannerSheet.swift
//  Spendy
//
//  A receipt report using the same hero and details layout as View Transaction.
//

import SwiftUI

struct ReceiptScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store

    var images: [UIImage]
    var initialAccountId: String?
    var initialCategoryId: String?
    var onEditResult: (ReceiptScanResult) -> Void
    var onAddResult: (ReceiptScanResult) -> Void

    @State private var isScanning = true
    @State private var isUsingAppleIntelligence = false
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var scanResult: ReceiptScanResult?
    @State private var isFinishing = false
    @Namespace private var sheetNamespace

    private var merchant: String {
        guard let result = scanResult, !result.rawRecognizedText.isEmpty else { return "" }
        let name = result.merchantName.trimmingCharacters(in: .whitespacesAndNewlines)
        return ["Merchant", "Scanned Expense", "Scanned Receipt"].contains(name) ? "" : name
    }

    private var category: Category? {
        let id = scanResult?.suggestedCategoryId ?? initialCategoryId
        return store.categories.first(where: { $0.id == id && $0.type == (scanResult?.transactionType ?? .expense) })
    }

    private var account: Account? {
        let id = scanResult?.suggestedAccountId ?? initialAccountId
        return store.accounts.first(where: { $0.id == id })
    }

    private var canAdd: Bool {
        guard let result = scanResult else { return false }
        return !isFinishing && result.totalAmount > 0 && !merchant.isEmpty && category != nil && account != nil
            && result.currencySymbol == store.currencySymbol && result.hasDetectedDate
            && result.paymentStatus != .pending && result.paymentStatus != .failed
    }

    var body: some View {
        ZStack(alignment: .top) {
            if isScanning {
                loadingView
            } else if let result = scanResult {
                reportView(result)
            }

            topActionBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
        }
        .presentationDetents([.height(570), .large])
        .presentationDragIndicator(.hidden)
        .background(Color.clear)
        .task { await processImages() }
    }

    private var topActionBar: some View {
        GlassEffectContainer(spacing: 10) {
            ZStack {
                Text("Review receipt")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 116)
                    .accessibilityIdentifier("receipt-review-title")

                HStack {
                    GlassCircleButton(icon: SFIcons.close, size: 44, iconSize: 16, iconWeight: .bold,
                        foregroundColor: SpendyColors.textPrimary, haptic: .selection,
                        accessibilityLabel: "Close", morphID: "closeButton", namespace: sheetNamespace) { dismiss() }
                    Spacer(minLength: 0)
                    if scanResult != nil {
                        HStack(spacing: 10) {
                            GlassCircleButton(icon: SFIcons.edit, size: 44, iconSize: 16, iconWeight: .bold,
                                foregroundColor: SpendyColors.textPrimary, haptic: .selection,
                                accessibilityLabel: "Edit receipt", morphID: "editReceipt", namespace: sheetNamespace,
                                action: editResult)
                                .disabled(isFinishing)
                                .accessibilityIdentifier("edit-scanned-receipt")
                            Button(action: addResult) {
                                Label("Add", systemImage: "plus")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                    .frame(width: 62, height: 44)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .disabled(!canAdd)
                            .opacity(canAdd ? 1 : 0.45)
                            .accessibilityLabel("Add scanned transaction")
                            .accessibilityIdentifier("add-scanned-receipt")
                        }
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(SpendyColors.textPrimary)
            if isUsingAppleIntelligence {
                intelligenceLabel("Using Apple Intelligence", animated: true)
                    .accessibilityIdentifier("receipt-intelligence-processing")
            } else {
                Text("Reading receipt")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            Text(isUsingAppleIntelligence ? "Checking the amount on your device" : "Finding the details on your device")
                .font(.subheadline)
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func intelligenceLabel(_ title: String, animated: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles")
                .foregroundStyle(SpendyColors.textPrimary)
                .accessibilityHidden(true)
            ShinyText(text: title, font: .subheadline.weight(.semibold),
                color: SpendyColors.textPrimary.opacity(0.85), shineColor: SpendyColors.textPrimary,
                speed: 1.8, delay: 7, disabled: !animated || contrast == .increased,
                alignment: .center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }

    private func reportView(_ result: ReceiptScanResult) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer().frame(height: 56)

                heroSection(result)
                    .padding(.top, 4)
                    .padding(.bottom, 6)

                detailsCard(result)

                if let guidance = reviewGuidance(result) {
                    Label(guidance, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !result.lineItems.isEmpty && result.receiptType != .paymentScreenshot {
                    recognizedItemsCard(result)
                }
                if let image = result.originalImage {
                    DisclosureGroup("Receipt image") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 12)
                            .accessibilityLabel("Original receipt image")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .padding(16)
                    .background(SpendyColors.cardBackground, in: RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    private func heroSection(_ result: ReceiptScanResult) -> some View {
        VStack(spacing: 14) {
            SpendyIconBadge(
                sfSymbol: category?.sfSymbol ?? "doc.text",
                color: category.map { Color(hex: $0.colorHex) } ?? SpendyColors.primaryBlue,
                size: .large,
                style: .circle,
                monogramName: category?.label ?? "Receipt"
            )

            Text(result.totalAmount > 0
                 ? result.totalAmount.formattedCurrency(symbol: result.currencySymbol)
                 : "Amount not found")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(result.totalAmount > 0 ? SpendyColors.textPrimary : SpendyColors.textSecondary)

            if result.wasAssistedByAppleIntelligence {
                intelligenceLabel("Assisted by Apple Intelligence", animated: false)
                    .accessibilityIdentifier("receipt-intelligence-result")
            } else if isUsingAppleIntelligence && result.totalAmount == 0 {
                Text("Apple Intelligence couldn’t identify the amount. Check it manually.")
                    .font(.footnote)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func detailsCard(_ result: ReceiptScanResult) -> some View {
        VStack(spacing: 0) {
            detailRow(label: "Note") {
                Text(merchant.isEmpty ? "Not found" : merchant)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(merchant.isEmpty ? SpendyColors.textSecondary : SpendyColors.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            cardDivider
            detailRow(label: "Date") {
                Text(result.hasDetectedDate ? result.date.formatted(date: .abbreviated, time: .omitted) : "Check in Edit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            cardDivider
            detailRow(label: "Category") {
                entityValue(
                    symbol: category?.sfSymbol ?? "tag.fill",
                    color: category.map { Color(hex: $0.colorHex) } ?? SpendyColors.primaryBlue,
                    name: category?.label ?? "Choose in Edit",
                    isCircle: true
                )
            }
            cardDivider
            detailRow(label: "Account") {
                entityValue(
                    symbol: account?.sfSymbol ?? account?.type.defaultSymbol ?? "building.columns.fill",
                    color: account.map { Color(hex: $0.colorHex) } ?? SpendyColors.incomeGreen,
                    name: account?.label ?? "Choose in Edit"
                )
            }
        }
        .padding(.horizontal, 18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }

    private func recognizedItemsCard(_ result: ReceiptScanResult) -> some View {
        DisclosureGroup("Recognized items (\(result.lineItems.count))") {
            VStack(spacing: 0) {
                ForEach(result.lineItems) { item in
                    HStack {
                        Text(item.name)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Text(item.amount.formattedCurrency(symbol: result.currencySymbol, decimals: 2))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .padding(.vertical, 9)
                }
            }
            .padding(.top, 8)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(SpendyColors.textPrimary)
        .padding(18)
        .background(SpendyColors.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cardDivider: some View {
        Divider().background(SpendyColors.separator)
    }

    private func detailRow<Value: View>(label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            Spacer(minLength: 12)
            value()
        }
        .padding(.vertical, 14)
    }

    private func entityValue(symbol: String, color: Color, name: String, isCircle: Bool = false) -> some View {
        HStack(spacing: 8) {
            SpendyIconBadge(
                sfSymbol: symbol,
                color: color,
                size: .small,
                style: isCircle ? .circle : .rounded(),
                monogramName: name
            )
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
        }
    }

    private func reviewGuidance(_ result: ReceiptScanResult) -> String? {
        if result.rawRecognizedText.isEmpty { return "We couldn’t read this photo. Tap Edit to enter the details." }
        if result.paymentStatus == .pending { return "Payment is pending. Confirm it completed before recording it." }
        if result.paymentStatus == .failed { return "This payment failed. It hasn’t been added to your spending." }
        if result.currencySymbol != store.currencySymbol { return "Receipt shows \(result.currencySymbol). Tap Edit to check the amount in \(store.currencySymbol)." }
        if result.totalAmount == 0 { return "The amount needs checking. Tap Edit to enter it." }
        if !result.hasDetectedDate { return "The date wasn’t clear. Check it in Edit before adding." }
        if merchant.isEmpty || category == nil || account == nil { return "Tap Edit to check the note, category, and account." }
        return nil
    }

    private func reviewedResult() -> ReceiptScanResult? {
        guard var result = scanResult else { return nil }
        result.merchantName = merchant
        result.suggestedCategoryId = category?.id
        result.suggestedAccountId = account?.id
        return result
    }

    private func editResult() {
        guard !isFinishing, let result = reviewedResult() else { return }
        isFinishing = true
        onEditResult(result)
        dismiss()
    }

    private func addResult() {
        guard canAdd, let result = reviewedResult() else { return }
        isFinishing = true
        onAddResult(result)
        dismiss()
    }

    private func processImages() async {
        guard scanResult == nil else { return }
        let result = await ReceiptScannerEngine.shared.scanImages(
            images,
            categories: store.categories,
            accounts: store.accounts,
            defaultCurrencySymbol: store.currencySymbol,
            onIntelligenceStarted: { isUsingAppleIntelligence = true }
        )
        scanResult = result
        isScanning = false
    }
}
