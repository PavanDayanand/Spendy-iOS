//
//  FloatingCurrencyConverterView.swift
//  Spendy
//
//  Focused currency conversion sheet backed by the store's cached exchange rates.
//

import SwiftUI

struct FloatingCurrencyConverterView: View {
    @Binding var isPresented: Bool
    @Environment(ExpenseStore.self) private var store

    @State private var fromAmount = "100"
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "INR"
    @State private var showFromCurrencyPicker = false
    @State private var showToCurrencyPicker = false
    @FocusState private var isAmountFocused: Bool

    private var availableCodes: Set<String> {
        Set(store.ratesToUSD.keys).union([fromCurrency, toCurrency])
    }

    private var inputAmount: Double? {
        let grouping = Locale.current.groupingSeparator ?? ","
        let decimal = Locale.current.decimalSeparator ?? "."
        let normalized = fromAmount
            .replacingOccurrences(of: grouping, with: "")
            .replacingOccurrences(of: decimal, with: ".")
        guard let value = Double(normalized), value.isFinite, value >= 0 else { return nil }
        return value
    }

    private var exchangeRate: Double? {
        if fromCurrency == toCurrency { return 1 }
        guard store.ratesLastUpdated != nil,
              let fromRate = store.ratesToUSD[fromCurrency], fromRate > 0,
              let toRate = store.ratesToUSD[toCurrency], toRate > 0 else { return nil }
        return toRate / fromRate
    }

    private var convertedAmount: Double? {
        guard let inputAmount, let exchangeRate else { return nil }
        let result = inputAmount * exchangeRate
        return result.isFinite ? result : nil
    }

    private func fractionDigits(for code: String) -> Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.maximumFractionDigits
    }

    @Namespace private var sheetNamespace

    var body: some View {
        ZStack(alignment: .top) {
            SpendyAmbientHeaderBackground(color: SpendyColors.primaryBlue, height: 320, opacity: 0.30)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Spacer().frame(height: 58)
                    heroSection
                    conversionCard
                    rateFooter
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            topActionBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
        }
        .background(Color.clear)
        .presentationDetents([.height(420), .large])
        .presentationDragIndicator(.hidden)
        .task {
            toCurrency = store.currencyCode == "USD" ? "INR" : store.currencyCode
            await store.refreshExchangeRates()
        }
        .sheet(isPresented: $showFromCurrencyPicker) {
            CurrencyPickerSheet(selectedCode: fromCurrency, onSelect: { currency in
                fromCurrency = currency.code
            }, allowedCodes: availableCodes)
        }
        .sheet(isPresented: $showToCurrencyPicker) {
            CurrencyPickerSheet(selectedCode: toCurrency, onSelect: { currency in
                toCurrency = currency.code
            }, allowedCodes: availableCodes)
        }
    }

    private var topActionBar: some View {
        HStack {
            GlassCircleButton(
                icon: SFIcons.close,
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close currency converter",
                morphID: "closeButton",
                namespace: sheetNamespace
            ) {
                isAmountFocused = false
                isPresented = false
            }

            Spacer()

            GlassCircleButton(
                icon: "arrow.up.arrow.down",
                size: 44,
                iconSize: 16,
                iconWeight: .semibold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Swap currencies",
                morphID: "swapButton",
                namespace: sheetNamespace
            ) {
                swapCurrencies()
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 9) {
            SpendyIconBadge(
                sfSymbol: "arrow.left.arrow.right",
                color: SpendyColors.primaryBlue,
                size: .large,
                style: .circle,
                monogramName: "Conversion"
            )
            Text(convertedAmount.map {
                "\(CurrencyInfo.symbol(for: toCurrency))\($0.formattedNumber(decimals: fractionDigits(for: toCurrency)))"
            } ?? "—")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .accessibilityLabel("Converted amount in \(toCurrency)")
        }
    }

    private var conversionCard: some View {
        VStack(spacing: 0) {
            conversionRow(label: "From", code: fromCurrency, isInput: true) {
                isAmountFocused = false
                showFromCurrencyPicker = true
            }
            cardDivider
            conversionRow(label: "To", code: toCurrency, isInput: false) {
                isAmountFocused = false
                showToCurrencyPicker = true
            }
            cardDivider
            HStack(spacing: 10) {
                Text("Rate")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                Spacer(minLength: 4)
                if let exchangeRate {
                    Text("1 \(fromCurrency) = \(exchangeRate.formatted(.number.precision(.significantDigits(4...6)))) \(toCurrency)")
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else {
                    Text(store.isRefreshingRates ? "Updating…" : "Unavailable")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
            }
            .frame(minHeight: 52)
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

    private var cardDivider: some View {
        Divider().background(SpendyColors.separator)
    }

    private func conversionRow(label: String, code: String, isInput: Bool, choose: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)

            Spacer(minLength: 4)

            Button(action: choose) {
                HStack(spacing: 5) {
                    Text(CurrencyInfo.flag(for: code))
                        .font(.system(size: 20))
                    Text(code)
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .foregroundStyle(SpendyColors.textPrimary)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: 96, alignment: .leading)
            .accessibilityLabel("Choose \(label.lowercased()) currency, \(code)")

            if isInput {
                TextField("0", text: $fromAmount)
                    .font(.system(size: 20, weight: .semibold))
                    .monospacedDigit()
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .focused($isAmountFocused)
                    .frame(width: 116)
                    .accessibilityLabel("Amount in \(code)")
            } else {
                Text(convertedAmount.map { $0.formattedNumber(decimals: fractionDigits(for: code)) } ?? "—")
                    .font(.system(size: 20, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 116, alignment: .trailing)
            }
        }
        .frame(minHeight: 62)
    }

    private var rateFooter: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                if let updated = store.ratesLastUpdated {
                    Text("\(store.ratesError == nil ? "Updated" : "Cached rate from") \(updated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 12))
                        .foregroundStyle(SpendyColors.textSecondary)
                } else {
                    Text(store.ratesError ?? "Waiting for live rates")
                        .font(.system(size: 12))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                Link("Rates by Exchange Rate API", destination: URL(string: "https://www.exchangerate-api.com")!)
                    .font(.system(size: 12))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            Spacer(minLength: 0)
            Button {
                Task { await store.refreshExchangeRates(force: true) }
            } label: {
                if store.isRefreshingRates {
                    ProgressView().frame(width: 44, height: 44)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .nativeLiquidGlassCircle(isInteractive: true)
                }
            }
            .buttonStyle(.plain)
            .disabled(store.isRefreshingRates)
            .accessibilityLabel("Refresh exchange rates")
        }
        .padding(.horizontal, 2)
    }

    private func swapCurrencies() {
        HapticsManager.shared.trigger(.selection)
        if let convertedAmount {
            let digits = fractionDigits(for: toCurrency)
            fromAmount = convertedAmount.formatted(.number.grouping(.never).precision(.fractionLength(0...digits)))
        }
        swap(&fromCurrency, &toCurrency)
    }
}
