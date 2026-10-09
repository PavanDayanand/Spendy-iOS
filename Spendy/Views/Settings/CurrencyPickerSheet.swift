//
//  CurrencyPickerSheet.swift
//  Spendy
//
//  Centralized, Reusable Universal Currency Picker Sheet Drawer
//  Features:
//  - Rates updated status card with relative timestamp
//  - Continuous categorized list with "Suggested" section and alphabetical A–Z grouping
//  - Interactive Alphabet Scrubber Index Bar on the right edge with haptic feedback
//  - Floating liquid glass bottom search bar with real-time filtering
//  - High-accuracy ISO 4217 flags, symbols, and localized country/currency names
//  - Fully reusable across the entire app with custom selection bindings or ExpenseStore updates
//

import SwiftUI

// MARK: - Currency Info Model
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
            "AED": "د.إ", "BRL": "R$", "CNY": "¥", "RUB": "₽",
            "CHF": "CHF", "KRW": "₩", "PLN": "zł", "UAH": "₴",
            "SEK": "kr", "NOK": "kr", "DKK": "kr", "TRY": "₺",
            "ZAR": "R", "NZD": "$", "HKD": "$", "THB": "฿",
            "PHP": "₱", "IDR": "Rp", "MYR": "RM", "VND": "₫"
        ]
        if let special = specialSymbols[code.uppercased()] {
            return special
        }
        let localeId = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: localeId)
        return locale.currencySymbol ?? code
    }
    
    static func name(for code: String) -> String {
        let cleanCode = code.uppercased()
        let specialNames: [String: String] = [
            "AFN": "Afghan Afghani",
            "ALL": "Albanian Lek",
            "DZD": "Algerian Dinar",
            "AOA": "Angolan Kwanza",
            "ARS": "Argentine Peso",
            "AMD": "Armenian Dram",
            "AWG": "Aruban Florin",
            "AUD": "Australian Dollar",
            "AZN": "Azerbaijani Manat",
            "BAM": "Bosnia-Herzegovina Convertible Mark",
            "BBD": "Barbadian Dollar",
            "BDT": "Bangladeshi Taka",
            "BGN": "Bulgarian Lev",
            "BHD": "Bahraini Dinar",
            "BIF": "Burundian Franc",
            "BMD": "Bermudan Dollar",
            "BND": "Brunei Dollar",
            "BOB": "Bolivian Boliviano",
            "BRL": "Brazilian Real",
            "BSD": "Bahamian Dollar",
            "BTN": "Bhutanese Ngultrum",
            "BWP": "Botswanan Pula",
            "BYN": "Belarusian Ruble",
            "BZD": "Belize Dollar",
            "CAD": "Canadian Dollar",
            "CDF": "Congolese Franc",
            "CHF": "Swiss Franc",
            "CLP": "Chilean Peso",
            "CNY": "Chinese Yuan",
            "COP": "Colombian Peso",
            "CRC": "Costa Rican Colón",
            "CUP": "Cuban Peso",
            "CVE": "Cape Verdean Escudo",
            "CZK": "Czech Koruna",
            "DJF": "Djiboutian Franc",
            "DKK": "Danish Krone",
            "DOP": "Dominican Peso",
            "EGP": "Egyptian Pound",
            "ERN": "Eritrean Nakfa",
            "ETB": "Ethiopian Birr",
            "EUR": "Euro",
            "FJD": "Fijian Dollar",
            "FKP": "Falkland Islands Pound",
            "GBP": "British Pound",
            "GEL": "Georgian Lari",
            "GHS": "Ghanaian Cedi",
            "GIP": "Gibraltar Pound",
            "GMD": "Gambian Dalasi",
            "GNF": "Guinean Franc",
            "GTQ": "Guatemalan Quetzal",
            "GYD": "Guyanaese Dollar",
            "HKD": "Hong Kong Dollar",
            "HNL": "Honduran Lempira",
            "HRK": "Croatian Kuna",
            "HTG": "Haitian Gourde",
            "HUF": "Hungarian Forint",
            "IDR": "Indonesian Rupiah",
            "ILS": "Israeli New Shekel",
            "INR": "Indian Rupee",
            "IQD": "Iraqi Dinar",
            "IRR": "Iranian Rial",
            "ISK": "Icelandic Króna",
            "JMD": "Jamaican Dollar",
            "JOD": "Jordanian Dinar",
            "JPY": "Japanese Yen",
            "KES": "Kenyan Shilling",
            "KGS": "Kyrgystani Som",
            "KHR": "Cambodian Riel",
            "KMF": "Comorian Franc",
            "KPW": "North Korean Won",
            "KRW": "South Korean Won",
            "KWD": "Kuwaiti Dinar",
            "KYD": "Cayman Islands Dollar",
            "KZT": "Kazakhstani Tenge",
            "LAK": "Laotian Kip",
            "LBP": "Lebanese Pound",
            "LKR": "Sri Lankan Rupee",
            "LRD": "Liberian Dollar",
            "LSL": "Lesotho Loti",
            "LYD": "Libyan Dinar",
            "MAD": "Moroccan Dirham",
            "MDL": "Moldovan Leu",
            "MGA": "Malagasy Ariary",
            "MKD": "Macedonian Denar",
            "MMK": "Myanmar Kyat",
            "MNT": "Mongolian Tugrik",
            "MOP": "Macanese Pataca",
            "MRU": "Mauritanian Ouguiya",
            "MUR": "Mauritian Rupee",
            "MVR": "Maldivian Rufiyaa",
            "MWK": "Malawian Kwacha",
            "MXN": "Mexican Peso",
            "MYR": "Malaysian Ringgit",
            "MZN": "Mozambican Metical",
            "NAD": "Namibian Dollar",
            "NGN": "Nigerian Naira",
            "NIO": "Nicaraguan Córdoba",
            "NOK": "Norwegian Krone",
            "NPR": "Nepalese Rupee",
            "NZD": "New Zealand Dollar",
            "OMR": "Omani Rial",
            "PAB": "Panamanian Balboa",
            "PEN": "Peruvian Sol",
            "PGK": "Papua New Guinean Kina",
            "PHP": "Philippine Peso",
            "PKR": "Pakistani Rupee",
            "PLN": "Polish Złoty",
            "PYG": "Paraguayan Guarani",
            "QAR": "Qatari Rial",
            "RON": "Romanian Leu",
            "RSD": "Serbian Dinar",
            "RUB": "Russian Ruble",
            "RWF": "Rwandan Franc",
            "SAR": "Saudi Riyal",
            "SBD": "Solomon Islands Dollar",
            "SCR": "Seychellois Rupee",
            "SDG": "Sudanese Pound",
            "SEK": "Swedish Krona",
            "SGD": "Singapore Dollar",
            "SHP": "Saint Helena Pound",
            "SLL": "Sierra Leonean Leone",
            "SOS": "Somali Shilling",
            "SRD": "Surinamese Dollar",
            "SSP": "South Sudanese Pound",
            "STN": "São Tomé & Príncipe Dobra",
            "SVC": "Salvadoran Colón",
            "SYP": "Syrian Pound",
            "SZL": "Swazi Lilangeni",
            "THB": "Thai Baht",
            "TJS": "Tajikistani Somoni",
            "TMT": "Turkmenistani Manat",
            "TND": "Tunisian Dinar",
            "TOP": "Tongan Paʻanga",
            "TRY": "Turkish Lira",
            "TTD": "Trinidad & Tobago Dollar",
            "TWD": "New Taiwan Dollar",
            "TZS": "Tanzanian Shilling",
            "UAH": "Ukrainian Hryvnia",
            "UGX": "Ugandan Shilling",
            "USD": "US Dollar",
            "UYU": "Uruguayan Peso",
            "UZS": "Uzbekistan Som",
            "VES": "Venezuelan Bolívar",
            "VND": "Vietnamese Dong",
            "VUV": "Vanuatu Vatu",
            "WST": "Samoan Tala",
            "XAF": "Central African CFA Franc",
            "XCD": "East Caribbean Dollar",
            "XOF": "West African CFA Franc",
            "XPF": "CFP Franc",
            "YER": "Yemeni Rial",
            "ZAR": "South African Rand",
            "ZMW": "Zambian Kwacha",
            "ZWL": "Zimbabwean Dollar"
        ]
        if let special = specialNames[cleanCode] {
            return special
        }
        let locale = Locale.current
        return locale.localizedString(forCurrencyCode: cleanCode) ?? cleanCode
    }
    
    static func flag(for code: String) -> String {
        let cleanCode = code.uppercased()
        
        let specialMappings: [String: String] = [
            "EUR": "EU",
            "GBP": "GB",
            "USD": "US",
            "INR": "IN",
            "PLN": "PL",
            "UAH": "UA",
            "ANG": "CW",
            "XOF": "SN",
            "XAF": "CM",
            "XCD": "DM",
            "XPF": "PF",
            "CHF": "CH",
            "ZAR": "ZA",
            "RUB": "RU",
            "CAD": "CA",
            "AUD": "AU",
            "JPY": "JP",
            "CNY": "CN",
            "BRL": "BR",
            "AED": "AE",
            "SGD": "SG",
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
    
    // Comprehensive standard ISO 4217 currencies list
    static let allStandardCodes: [String] = [
        "USD", "EUR", "GBP", "INR", "JPY", "CAD", "AUD", "CHF", "CNY", "BRL",
        "SGD", "AED", "HKD", "NZD", "SEK", "NOK", "DKK", "PLN", "UAH", "TRY",
        "ZAR", "MXN", "KRW", "SAR", "THB", "IDR", "MYR", "PHP", "VND", "CZK",
        "HUF", "ILS", "CLP", "COP", "EGP", "QAR", "KWD", "OMR", "BHD", "PEN",
        "PKR", "BDT", "NGN", "KES", "GHS", "MAD", "DZD", "TND", "IQD", "JOD",
        "LKR", "NPR", "AFN", "ALL", "AOA", "ARS", "AMD", "AWG", "AZN", "BAM",
        "BBD", "BIF", "BMD", "BND", "BOB", "BSD", "BTN", "BWP", "BYN", "BZD",
        "CDF", "CRC", "CUP", "CVE", "DJF", "DOP", "ERN", "ETB", "FJD", "FKP",
        "GEL", "GIP", "GMD", "GNF", "GTQ", "GYD", "HNL", "HRK", "HTG", "IRR",
        "ISK", "JMD", "KGS", "KHR", "KMF", "KPW", "KYD", "KZT", "LAK", "LBP",
        "LRD", "LSL", "LYD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRU",
        "MUR", "MVR", "MWK", "MZN", "NAD", "NIO", "PAB", "PGK", "PYG", "RON",
        "RSD", "RUB", "RWF", "SBD", "SCR", "SDG", "SHP", "SLL", "SOS", "SRD",
        "SSP", "STN", "SVC", "SYP", "SZL", "TJS", "TMT", "TOP", "TTD", "TWD",
        "TZS", "UGX", "UYU", "UZS", "VES", "VUV", "WST", "XAF", "XCD", "XOF",
        "XPF", "YER", "ZMW", "ZWL"
    ]
}

// MARK: - Centralized CurrencyPickerSheet View
struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    
    @State private var searchText: String = ""
    @State private var lastScrubbedLetter: String? = nil
    @Namespace private var currencySheetNamespace
    
    // Custom highlights & selection triggers
    var selectedCode: String? = nil
    var onSelect: ((CurrencyInfo) -> Void)? = nil
    var allowedCodes: Set<String>? = nil
    
    private var activeSelectedCode: String {
        selectedCode ?? store.currencyCode
    }
    
    // Suggested currencies (Matches reference: Polish Złoty, Ukrainian Hryvnia, and popular world currencies)
    private var suggestedCurrencies: [CurrencyInfo] {
        let codes = ["PLN", "UAH", "USD", "EUR", "GBP", "INR", "JPY", "CAD", "AUD", "CHF"]
        return codes.filter { allowedCodes?.contains($0) ?? true }.map { code in
            CurrencyInfo(
                code: code,
                symbol: CurrencyInfo.symbol(for: code),
                name: CurrencyInfo.name(for: code),
                flag: CurrencyInfo.flag(for: code)
            )
        }
    }
    
    // All Currencies merged from static ISO codes and store.ratesToUSD
    private var allCurrencies: [CurrencyInfo] {
        var codesSet = Set(CurrencyInfo.allStandardCodes)
        for code in store.ratesToUSD.keys {
            codesSet.insert(code)
        }
        
        return codesSet.filter { allowedCodes?.contains($0) ?? true }.sorted().map { code in
            CurrencyInfo(
                code: code,
                symbol: CurrencyInfo.symbol(for: code),
                name: CurrencyInfo.name(for: code),
                flag: CurrencyInfo.flag(for: code)
            )
        }
    }
    
    // Filtered Suggested Currencies
    private var filteredSuggestedCurrencies: [CurrencyInfo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return suggestedCurrencies
        }
        return suggestedCurrencies.filter {
            $0.code.lowercased().contains(query) ||
            $0.name.lowercased().contains(query) ||
            $0.symbol.lowercased().contains(query)
        }
    }
    
    // Filtered and Grouped Alphabetical Currencies
    private var groupedAllCurrencies: [(key: String, value: [CurrencyInfo])] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = allCurrencies.filter {
            if query.isEmpty { return true }
            return $0.code.lowercased().contains(query) ||
                   $0.name.lowercased().contains(query) ||
                   $0.symbol.lowercased().contains(query)
        }
        
        let grouped = Dictionary(grouping: filtered) { currency in
            String(currency.code.prefix(1)).uppercased()
        }
        
        return grouped.map { (key: $0.key, value: $0.value.sorted(by: { $0.code < $1.code })) }
            .sorted(by: { $0.key < $1.key })
    }
    
    // Available alphabetical scrubber letters
    private var alphabetIndexLetters: [String] {
        var letters = ["★"]
        let groupKeys = groupedAllCurrencies.map { $0.key }
        for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            let str = String(letter)
            if groupKeys.contains(str) {
                letters.append(str)
            }
        }
        return letters
    }
    
    // MARK: - Apple Default Grey Design Tokens
    private var sheetBackgroundColor: Color {
        Color(uiColor: .systemGroupedBackground)
    }
    
    private var cardBackgroundColor: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            sheetBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header Bar: Close & Centered Title "Select currency"
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                // 2. Continuous Scrollable Content with Section Anchors & Alphabet Index
                ScrollViewReader { proxy in
                    ZStack(alignment: .trailing) {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 18) {
                                // Rates updated Status Card
                                if searchText.isEmpty {
                                    ratesUpdatedCard
                                }
                                
                                // Suggested Section
                                if !filteredSuggestedCurrencies.isEmpty {
                                    suggestedSection
                                        .id("section_suggested")
                                }
                                
                                // Alphabetical Sections ("A", "B", "C", ... "Z")
                                if groupedAllCurrencies.isEmpty && filteredSuggestedCurrencies.isEmpty {
                                    emptyStateView
                                } else {
                                    ForEach(groupedAllCurrencies, id: \.key) { group in
                                        alphabetGroupSection(key: group.key, currencies: group.value)
                                            .id("section_\(group.key)")
                                    }
                                }
                                
                                // Bottom spacing to ensure items are never hidden behind floating search bar
                                Color.clear
                                    .frame(height: 72)
                            }
                            .padding(.horizontal, 20)
                            .padding(.trailing, searchText.isEmpty ? 16 : 0)
                            .padding(.top, 4)
                        }
                        
                        // 3. Right-side Alphabet Scrubber Index Bar
                        if searchText.isEmpty {
                            alphabetScrubberBar(proxy: proxy)
                                .padding(.trailing, 4)
                        }
                    }
                }
            }
            
            // 4. Floating Liquid Glass Bottom Search Bar
            floatingSearchCapsule
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .presentationBackground(sheetBackgroundColor)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            ZStack {
                Text("Select currency")
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
                        morphID: "closeCurrencyButton",
                        namespace: currencySheetNamespace
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Rates Updated Status Card
    private var ratesUpdatedCard: some View {
        HStack {
            Text("Rates updated")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            Text(store.ratesLastUpdatedFormatted)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Suggested Section
    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(filteredSuggestedCurrencies.enumerated()), id: \.element.id) { index, currency in
                    currencyRow(currency: currency)
                    
                    if index < filteredSuggestedCurrencies.count - 1 {
                        Divider()
                            .background(SpendyColors.separator)
                            .padding(.leading, 48)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardBackgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - Alphabetical Group Section Card
    @ViewBuilder
    private func alphabetGroupSection(key: String, currencies: [CurrencyInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(key)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(currencies.enumerated()), id: \.element.id) { index, currency in
                    currencyRow(currency: currency)
                    
                    if index < currencies.count - 1 {
                        Divider()
                            .background(SpendyColors.separator)
                            .padding(.leading, 48)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardBackgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - Currency Row Item (Matching Reference Screenshot)
    @ViewBuilder
    private func currencyRow(currency: CurrencyInfo) -> some View {
        let isSelected = activeSelectedCode.uppercased() == currency.code.uppercased()
        
        Button {
            HapticsManager.shared.trigger(.selection)
            selectCurrency(currency)
        } label: {
            HStack(spacing: 12) {
                // Flag
                Text(currency.flag)
                    .font(.system(size: 20))
                    .frame(width: 28, alignment: .center)
                
                // Code (e.g. PLN, UAH, AFN)
                Text(currency.code)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .frame(width: 44, alignment: .leading)
                
                // Name (e.g. Polish Złoty, Ukrainian Hryvnia, Afghan Afghani)
                Text(currency.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                // Selected Indicator Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Right-side Alphabet Scrubber Index Bar
    @ViewBuilder
    private func alphabetScrubberBar(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 2) {
            ForEach(alphabetIndexLetters, id: \.self) { item in
                Button {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        if item == "★" {
                            proxy.scrollTo("section_suggested", anchor: .top)
                        } else {
                            proxy.scrollTo("section_\(item)", anchor: .top)
                        }
                    }
                } label: {
                    Text(item)
                        .font(.system(size: item == "★" ? 10 : 10, weight: .bold))
                        .foregroundStyle(lastScrubbedLetter == item ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                        .scaleEffect(lastScrubbedLetter == item ? 1.25 : 1.0)
                        .frame(width: 18, height: 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let totalHeight = geo.size.height
                                guard totalHeight > 0, !alphabetIndexLetters.isEmpty else { return }
                                let itemHeight = totalHeight / CGFloat(alphabetIndexLetters.count)
                                let index = Int(value.location.y / itemHeight)
                                let clampedIndex = max(0, min(alphabetIndexLetters.count - 1, index))
                                let letter = alphabetIndexLetters[clampedIndex]
                                if letter != lastScrubbedLetter {
                                    lastScrubbedLetter = letter
                                    HapticsManager.shared.trigger(.selection)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        if letter == "★" {
                                            proxy.scrollTo("section_suggested", anchor: .top)
                                        } else {
                                            proxy.scrollTo("section_\(letter)", anchor: .top)
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    lastScrubbedLetter = nil
                                }
                            }
                    )
            }
        )
        .accessibilityHidden(true)
    }
    
    // MARK: - Floating Liquid Glass Bottom Search Bar
    private var floatingSearchCapsule: some View {
        HStack(spacing: 10) {
            Image(systemName: SFIcons.search)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            TextField("Search currency", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button {
                    HapticsManager.shared.trigger(.tick)
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
        .shadow(color: Color.black.opacity(0.16), radius: 12, y: 4)
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
    
    // MARK: - Selection Handler
    private func selectCurrency(_ currency: CurrencyInfo) {
        if let onSelect = onSelect {
            onSelect(currency)
        } else {
            store.updateCurrency(symbol: currency.symbol, code: currency.code)
        }
        dismiss()
    }
}
