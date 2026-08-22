//
//  CurrencyPickerSheet.swift
//  Spendy
//
//  Universal Choose Currency Sheet Drawer with Suggested & Alphabetical sections
//  and dynamic Liquid Glass Search Filtering. Loaded directly from the API rates.
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
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Suggested section
                        if !filteredSuggestedCurrencies.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Suggested")
                                    .font(.system(size: 13, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundStyle(SpendyColors.textSecondary)
                                    .padding(.horizontal, 4)
                                
                                CurrencyGroupCard {
                                    ForEach(Array(filteredSuggestedCurrencies.enumerated()), id: \.element.code) { index, currency in
                                        CurrencyRow(
                                            currency: currency,
                                            isSelected: activeSelectedCode == currency.code
                                        ) {
                                            selectCurrency(currency)
                                        }
                                        
                                        if index < filteredSuggestedCurrencies.count - 1 {
                                            Divider()
                                                .overlay(SpendyColors.separator)
                                                .padding(.leading, 64)
                                        }
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
                                    .foregroundStyle(SpendyColors.textSecondary)
                                    .padding(.horizontal, 4)
                                
                                CurrencyGroupCard {
                                    ForEach(Array(group.value.enumerated()), id: \.element.code) { index, currency in
                                        CurrencyRow(
                                            currency: currency,
                                            isSelected: activeSelectedCode == currency.code
                                        ) {
                                            selectCurrency(currency)
                                        }
                                        
                                        if index < group.value.count - 1 {
                                            Divider()
                                                .overlay(SpendyColors.separator)
                                                .padding(.leading, 64)
                                        }
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
                    colors: [Color.clear, SpendyColors.appBackground.opacity(0.95), SpendyColors.appBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
    
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
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }
    
    private var searchCapsule: some View {
        HStack(spacing: 8) {
            Image(systemName: SFIcons.search)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            TextField("Search currency", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .nativeLiquidGlassCapsule(isInteractive: true)
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
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

// MARK: - Row Components & Helpers

struct CurrencyRow: View {
    let currency: CurrencyInfo
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Flag emoji
                Text(currency.flag)
                    .font(.system(size: 24))
                    .frame(width: 32)
                
                // Code
                Text(currency.code)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .frame(width: 44, alignment: .leading)
                
                // Name
                Text(currency.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct CurrencyGroupCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
}
