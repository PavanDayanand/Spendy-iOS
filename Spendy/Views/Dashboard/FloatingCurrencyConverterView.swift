//
//  FloatingCurrencyConverterView.swift
//  Spendy
//
//  Real-time Currency Converter Floating Card with Liquid Glass Design.
//  Matches screenshot layout with editable base amount, dynamic conversion, and swap rate pill.
//

import SwiftUI

struct FloatingCurrencyConverterView: View {
    @Binding var isPresented: Bool
    @Environment(ExpenseStore.self) private var store
    
    @State private var fromAmount: String = "100"
    @State private var fromCurrency: String = "USD"
    @State private var toCurrency: String = "INR"
    
    @State private var showFromCurrencyPicker: Bool = false
    @State private var showToCurrencyPicker: Bool = false
    @FocusState private var isAmountFocused: Bool
    
    @State private var dragOffset: CGFloat = 0.0
    
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
    
    private var exchangeRate: Double {
        let fromRate = store.ratesToUSD[fromCurrency] ?? 1.0
        let toRate = store.ratesToUSD[toCurrency] ?? 1.0
        return (1.0 / fromRate) * toRate
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header Row: Close button on Left, Centered Title
            ZStack {
                HStack {
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        isAmountFocused = false // Resign keyboard focus
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: SFIcons.close)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(SpendyColors.textPrimary)
                            .frame(width: 40, height: 40)
                            .nativeLiquidGlassCircle(isInteractive: true)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
                Text("Currency converter")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(SpendyColors.textPrimary)
            }
            .padding(.bottom, 4)
            
            // From Currency Rounded Box
            HStack(spacing: 12) {
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showFromCurrencyPicker = true
                }) {
                    HStack(spacing: 6) {
                        Text(CurrencyInfo.flag(for: fromCurrency))
                            .font(.system(size: 20))
                        Text(fromCurrency)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(SpendyColors.textPrimary)
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 7))
                            .rotationEffect(.degrees(180))
                            .foregroundColor(SpendyColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(CurrencyInfo.symbol(for: fromCurrency))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(SpendyColors.textTertiary)
                    
                    TextField("100", text: $fromAmount)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(SpendyColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($isAmountFocused)
                        .frame(maxWidth: 160)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(SpendyColors.separator, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
            
            // Middle Exchange Rate Pill / Split Divider
            HStack {
                Rectangle()
                    .fill(SpendyColors.separator)
                    .frame(height: 1)
                
                Button(action: {
                    HapticsManager.shared.trigger(.medium)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        let temp = fromCurrency
                        fromCurrency = toCurrency
                        toCurrency = temp
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(SpendyColors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("1 \(fromCurrency) =")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(SpendyColors.textSecondary)
                            Text("\(CurrencyInfo.symbol(for: toCurrency))\(String(format: "%.2f", exchangeRate))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(SpendyColors.textPrimary)
                        }
                    }
                    .foregroundColor(SpendyColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .nativeLiquidGlassCapsule(isInteractive: true)
                }
                .buttonStyle(.plain)
                
                Rectangle()
                    .fill(SpendyColors.separator)
                    .frame(height: 1)
            }
            
            // To Currency Rounded Box
            HStack(spacing: 12) {
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showToCurrencyPicker = true
                }) {
                    HStack(spacing: 6) {
                        Text(CurrencyInfo.flag(for: toCurrency))
                            .font(.system(size: 20))
                        Text(toCurrency)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(SpendyColors.textPrimary)
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 7))
                            .rotationEffect(.degrees(180))
                            .foregroundColor(SpendyColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(CurrencyInfo.symbol(for: toCurrency))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(SpendyColors.textTertiary)
                    
                    Text(String(format: "%.2f", convertedAmount))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(SpendyColors.separator, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
        }
        .padding(20)
        .nativeLiquidGlass(cornerRadius: 32, isInteractive: true)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -60 {
                        HapticsManager.shared.trigger(.selection)
                        isAmountFocused = false // Resign keyboard first
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            dragOffset = 0.0
                        }
                    }
                }
        )
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
}
