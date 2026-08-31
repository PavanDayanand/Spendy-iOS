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
    @Namespace private var currencySheetNamespace
    
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
        ZStack {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header Bar: Close & Centered Title
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                // 2. Top Search Bar (Liquid Glass)
                searchCapsule
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                
                // 3. Scrollable List with Suggested Chips & Horizontal Rows
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Quick-Select Horizontal Scrolling Chips for Suggested Currencies
                        if searchText.isEmpty && !suggestedCurrencies.isEmpty {
                            suggestedChipsSection
                        }
                        
                        // Grouped Currency Cards
                        if groupedAllCurrencies.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(groupedAllCurrencies, id: \.key) { group in
                                currencyGroupSection(key: group.key, currencies: group.value)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 36)
                }
            }
        }
        .presentationBackground(SpendyColors.appBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
    
    // MARK: - Header
    private var headerBar: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            ZStack {
                Text("Select Currency")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 60)
                
                HStack {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 14,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .selection,
                        accessibilityLabel: "Close",
                        morphID: "closeButton",
                        namespace: currencySheetNamespace
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Top Search Bar
    private var searchCapsule: some View {
        HStack(spacing: 10) {
            Image(systemName: SFIcons.search)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            TextField("Search currency or country", text: $searchText)
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
        .frame(height: 48)
        .nativeLiquidGlassCapsule(isInteractive: true)
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
    }
    
    // MARK: - Suggested Horizontal Chips
    private var suggestedChipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Popular")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(SpendyColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedCurrencies) { currency in
                        let isSelected = activeSelectedCode == currency.code
                        
                        Button {
                            HapticsManager.shared.trigger(.selection)
                            selectCurrency(currency)
                        } label: {
                            HStack(spacing: 6) {
                                Text(currency.flag)
                                    .font(.system(size: 16))
                                
                                Text(currency.code)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                                
                                Text(currency.symbol)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(isSelected ? SpendyColors.textPrimary.opacity(0.8) : SpendyColors.textTertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                            .background {
                                Capsule()
                                    .fill(isSelected ? SpendyColors.cardBackgroundSecondary : Color.white.opacity(0.05))
                                    .overlay {
                                        Capsule()
                                            .stroke(isSelected ? SpendyColors.primaryBlue : SpendyColors.separator, lineWidth: isSelected ? 1.5 : 0.8)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    // MARK: - Group Section Card
    private var currencyGroupSection: some View {
        EmptyView()
    }
    
    @ViewBuilder
    private func currencyGroupSection(key: String, currencies: [CurrencyInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(key)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(currencies.enumerated()), id: \.element.id) { index, currency in
                    currencyRow(currency: currency)
                    
                    if index < currencies.count - 1 {
                        Divider()
                            .background(SpendyColors.separator)
                            .padding(.leading, 56)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - Horizontal Currency Row (NO SQUARED BOXES)
    @ViewBuilder
    private func currencyRow(currency: CurrencyInfo) -> some View {
        let isSelected = activeSelectedCode == currency.code
        
        Button {
            HapticsManager.shared.trigger(.selection)
            selectCurrency(currency)
        } label: {
            HStack(spacing: 14) {
                // Flag Badge
                ZStack {
                    Circle()
                        .fill(SpendyColors.cardBackgroundSecondary)
                        .frame(width: 38, height: 38)
                        .overlay {
                            Circle().stroke(SpendyColors.separator, lineWidth: 0.6)
                        }
                    
                    Text(currency.flag)
                        .font(.system(size: 20))
                }
                
                // Code & Full Name
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(currency.code)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Text(currency.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    
                    Text(currency.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.top, 30)
            
            Text("No currency matching \"\(searchText)\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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
