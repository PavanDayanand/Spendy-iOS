//
//  CurrencyPickerSheet.swift
//  Spendy
//
//  Universal Choose Currency Sheet Drawer with Suggested & Alphabetical grid sections
//  and dynamic Liquid Glass Search Filtering. Matches CategoryIconPickerSheet style.
//

import SwiftUI

struct CurrencyInfo: Identifiable, Hashable {
    var id: String { code }
    let code: String
    let symbol: String
    let name: String
    let flag: String
    
    static func symbol(for code: String) -> String {
        let specialSymbols: [String: String] = [
            "USD": "$", "EUR": "€", "GBP": "£", "INR": "₹",
            "JPY": "¥", "CAD": "$", "AUD": "$", "SGD": "$",
            "AED": "د.إ", "BRL": "R$", "CNY": "¥", "RUB": "₽"
        ]
        if let special = specialSymbols[code.uppercased()] {
            return special
        }
        let localeId = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: localeId)
        return locale.currencySymbol ?? code
    }
    
    static func name(for code: String) -> String {
        let locale = Locale.current
        return locale.localizedString(forCurrencyCode: code) ?? code
    }
    
    static func flag(for code: String) -> String {
        let cleanCode = code.uppercased()
        
        let specialMappings: [String: String] = [
            "EUR": "EU",
            "ANG": "CW",
            "XOF": "SN",
            "XAF": "CM",
            "XCD": "DM",
            "XPF": "PF",
            "BTC": "🪙"
        ]
        
        let countryCode: String
        if let special = specialMappings[cleanCode] {
            if special.count == 2 {
                countryCode = special
            } else {
                return special
            }
        } else {
            countryCode = String(cleanCode.prefix(2))
        }
        
        guard countryCode.count == 2 else { return "🏳️" }
        
        let base: UInt32 = 127397
        var result = ""
        for scalar in countryCode.unicodeScalars {
            if let scalarValue = UnicodeScalar(base + scalar.value) {
                result.append(String(scalarValue))
            }
        }
        return result
    }
}

struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    
    @State private var searchText: String = ""
    
    // Custom highlights & selection triggers
    var selectedCode: String? = nil
    var onSelect: ((CurrencyInfo) -> Void)? = nil
    
    private var activeSelectedCode: String {
        selectedCode ?? store.currencyCode
    }
    
    // Suggested currencies
    private var suggestedCurrencies: [CurrencyInfo] {
        let codes = ["USD", "EUR", "GBP", "INR", "AUD", "CAD", "SGD", "JPY"]
        return codes.compactMap { code in
            guard store.ratesToUSD.keys.contains(code) else { return nil }
            return CurrencyInfo(
                code: code,
                symbol: CurrencyInfo.symbol(for: code),
                name: CurrencyInfo.name(for: code),
                flag: CurrencyInfo.flag(for: code)
            )
        }
    }
    
    // All Currencies dynamically mapped from store.ratesToUSD
    private var allCurrencies: [CurrencyInfo] {
        return store.ratesToUSD.keys.sorted().map { code in
            CurrencyInfo(
                code: code,
                symbol: CurrencyInfo.symbol(for: code),
                name: CurrencyInfo.name(for: code),
                flag: CurrencyInfo.flag(for: code)
            )
        }
    }
    
    // Filter Suggested
    private var filteredSuggestedCurrencies: [CurrencyInfo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return suggestedCurrencies
        }
        return suggestedCurrencies.filter {
            $0.code.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
    }
    
    // Filter and Group All
    private var groupedAllCurrencies: [(key: String, value: [CurrencyInfo])] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = allCurrencies.filter {
            if query.isEmpty { return true }
            return $0.code.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
        
        let grouped = Dictionary(grouping: filtered) { currency in
            String(currency.code.prefix(1)).uppercased()
        }
        
        return grouped.map { (key: $0.key, value: $0.value.sorted(by: { $0.code < $1.code })) }
            .sorted(by: { $0.key < $1.key })
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header: Close, Title
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Scrollable Grid of Currencies
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Suggested section
                        if !filteredSuggestedCurrencies.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Suggested")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(SpendyColors.textSecondary)
                                    .padding(.horizontal, 4)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                    ForEach(filteredSuggestedCurrencies) { currency in
                                        currencyGridCell(currency: currency)
                                    }
                                }
                            }
                        }
                        
                        // Alphabetical sections
                        ForEach(groupedAllCurrencies, id: \.key) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.key)
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(SpendyColors.textSecondary)
                                    .padding(.horizontal, 4)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                    ForEach(group.value) { currency in
                                        currencyGridCell(currency: currency)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 120) // Clearance for search capsule
                }
            }
            
            // Search Input capsule container (Full Width)
            VStack(spacing: 0) {
                searchCapsule
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 16)
            }
            .background {
                LinearGradient(
                    colors: [Color.clear, Color(hex: "#1C1C1E").opacity(0.95), Color(hex: "#1C1C1E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .presentationBackground(Color(hex: "#1C1C1E"))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
    }
    
    // MARK: - Header
    private var headerBar: some View {
        ZStack {
            HStack {
                GlassCircleButton(
                    icon: "xmark",
                    size: 44,
                    iconSize: 14,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Close"
                ) {
                    dismiss()
                }
                Spacer()
            }
            
            Text("Select Currency")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(SpendyColors.textPrimary)
        }
    }
    
    // MARK: - Search Capsule
    private var searchCapsule: some View {
        HStack(spacing: 8) {
            Image(systemName: SFIcons.search)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(SpendyColors.textTertiary)
            
            TextField("Search currency", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(SpendyColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(SpendyColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .nativeLiquidGlassCapsule(isInteractive: true)
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
    }
    
    // MARK: - Currency Grid Cell (styled like CategoryIconPickerSheet)
    @ViewBuilder
    private func currencyGridCell(currency: CurrencyInfo) -> some View {
        let isSelected = activeSelectedCode == currency.code
        
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            selectCurrency(currency)
        }) {
            HStack(spacing: 8) {
                Text(currency.flag)
                    .font(.system(size: 20))
                
                Text(currency.code)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? Color.white : SpendyColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? SpendyColors.primaryBlue : Color(hex: "#1C1C1E"))
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(SpendyColors.textPrimary, lineWidth: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func selectCurrency(_ currency: CurrencyInfo) {
        if let onSelect = onSelect {
            onSelect(currency)
        } else {
            store.updateCurrency(symbol: currency.symbol, code: currency.code)
        }
        dismiss()
    }
}
