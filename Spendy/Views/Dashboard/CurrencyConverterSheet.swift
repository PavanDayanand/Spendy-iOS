//
//  CurrencyConverterSheet.swift
//  Spendy
//
//  Real-time Currency Converter Modal with Liquid Glass Controls and dynamic API rates
//

import SwiftUI

struct CurrencyConverterSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var fromAmount: String = "100"
    @State private var fromCurrency: String = "USD"
    @State private var toCurrency: String = "INR"
    @State private var showFromCurrencyPicker: Bool = false
    @State private var showToCurrencyPicker: Bool = false
    
    private var convertedAmount: Double {
        guard let amount = Double(fromAmount.replacingOccurrences(of: ",", with: "")) else {
            return 0.0
        }
        let fromRate = store.ratesToUSD[fromCurrency] ?? 1.0
        let toRate = store.ratesToUSD[toCurrency] ?? 1.0
        // Convert to USD then to target currency
        let amountInUSD = amount / fromRate
        return amountInUSD * toRate
    }
    
    private var exchangeRateText: String {
        let fromRate = store.ratesToUSD[fromCurrency] ?? 1.0
        let toRate = store.ratesToUSD[toCurrency] ?? 1.0
        let singleUnitConverted = (1.0 / fromRate) * toRate
        let fromSym = CurrencyInfo.symbol(for: fromCurrency)
        let toSym = CurrencyInfo.symbol(for: toCurrency)
        return "1 \(fromCurrency) (\(fromSym)) = \(String(format: "%.4f", singleUnitConverted)) \(toCurrency) (\(toSym))"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Top Header Bar
                        HStack {
                            GlassCircleButton(
                                icon: "xmark",
                                size: 44,
                                iconSize: 14,
                                foregroundColor: .white,
                                haptic: .selection,
                                accessibilityLabel: "Close"
                            ) {
                                dismiss()
                            }
                            
                            Spacer()
                            
                            Text("Currency Converter")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 44, height: 44)
                        }
                        .padding(.top, 10)
                        
                        // Live Status Pill
                        HStack(spacing: 6) {
                            Circle()
                                .fill(SpendyColors.incomeGreen)
                                .frame(width: 8, height: 8)
                            Text("Real-Time Exchange Rates")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: Capsule())
                        
                        // "From" Input Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("YOU SEND")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(.white.opacity(0.40))
                            
                            HStack {
                                TextField("100", text: $fromAmount)
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .keyboardType(.decimalPad)
                                
                                Spacer()
                                
                                Button(action: {
                                    HapticsManager.shared.trigger(.light)
                                    showFromCurrencyPicker = true
                                }) {
                                    HStack(spacing: 6) {
                                        Text(CurrencyInfo.flag(for: fromCurrency))
                                            .font(.system(size: 16))
                                        Text(CurrencyInfo.symbol(for: fromCurrency))
                                            .font(.system(size: 15, weight: .bold))
                                        Text(fromCurrency)
                                            .font(.system(size: 15, weight: .bold))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .nativeLiquidGlassCapsule(isInteractive: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                }
                        }
                        
                        // Quick Swap Button ⇅
                        GlassCircleButton(
                            icon: "arrow.up.arrow.down",
                            size: 44,
                            iconSize: 16,
                            tintColor: SpendyColors.primaryBlue,
                            foregroundColor: .white,
                            haptic: .medium,
                            accessibilityLabel: "Swap Currencies"
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                let temp = fromCurrency
                                fromCurrency = toCurrency
                                toCurrency = temp
                            }
                        }
                        .shadow(color: SpendyColors.primaryBlue.opacity(0.35), radius: 8, y: 3)
                        
                        // "To" Result Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("THEY RECEIVE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(.white.opacity(0.40))
                            
                            HStack {
                                Text(String(format: "%.2f", convertedAmount))
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundStyle(SpendyColors.incomeGreen)
                                
                                Spacer()
                                
                                Button(action: {
                                    HapticsManager.shared.trigger(.light)
                                    showToCurrencyPicker = true
                                }) {
                                    HStack(spacing: 6) {
                                        Text(CurrencyInfo.flag(for: toCurrency))
                                            .font(.system(size: 16))
                                        Text(CurrencyInfo.symbol(for: toCurrency))
                                            .font(.system(size: 15, weight: .bold))
                                        Text(toCurrency)
                                            .font(.system(size: 15, weight: .bold))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .nativeLiquidGlassCapsule(isInteractive: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                }
                        }
                        
                        // Rate Exchange Info Box
                        Text(exchangeRateText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.50))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showFromCurrencyPicker) {
                CurrencyPickerSheet(selectedCode: fromCurrency) { currency in
                    fromCurrency = currency.code
                }
            }
            .sheet(isPresented: $showToCurrencyPicker) {
                CurrencyPickerSheet(selectedCode: toCurrency) { currency in
                    toCurrency = currency.code
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
