//
//  CurrencyPickerSheet.swift
//  Spendy
//
//  Shared currency drawer, consistent with category selection.
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

// MARK: - Currency drawer
// Matches the category drawer's header, grouped rows, detents, and bottom search.
struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    @State private var searchText = ""

    var selectedCode: String? = nil
    var onSelect: ((CurrencyInfo) -> Void)? = nil
    var allowedCodes: Set<String>? = nil

    private var activeSelectedCode: String { (selectedCode ?? store.currencyCode).uppercased() }
    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var allCurrencies: [CurrencyInfo] {
        let codes = Set(CurrencyInfo.allStandardCodes + Array(store.ratesToUSD.keys))
        let allowed = allowedCodes.map { Set($0.map { $0.uppercased() }) }
        return Set(codes.map { $0.uppercased() })
            .filter { allowed?.contains($0) ?? true }
            .map { code in
                CurrencyInfo(code: code, symbol: CurrencyInfo.symbol(for: code),
                             name: CurrencyInfo.name(for: code), flag: CurrencyInfo.flag(for: code))
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var suggestedCurrencies: [CurrencyInfo] {
        guard query.isEmpty else { return [] }
        let preferred = [activeSelectedCode, Locale.current.currency?.identifier ?? "USD", "USD", "EUR"]
        var seen = Set<String>()
        return Array(preferred.compactMap { code -> CurrencyInfo? in
            guard seen.insert(code).inserted else { return nil }
            return allCurrencies.first { $0.code == code }
        }.prefix(2))
    }

    private var filteredCurrencies: [CurrencyInfo] {
        guard !query.isEmpty else { return allCurrencies }
        return allCurrencies.filter { currency in
            [currency.code, currency.name, currency.symbol].contains {
                $0.localizedStandardContains(query)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 22) {
                    if !suggestedCurrencies.isEmpty {
                        currencyGroup("Suggested", currencies: suggestedCurrencies)
                    }
                    if filteredCurrencies.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        currencyGroup(query.isEmpty ? "All currencies" : "Results", currencies: filteredCurrencies)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(0.88), .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            GlassCircleButton(icon: "xmark", size: 44, iconSize: 14,
                              foregroundColor: SpendyColors.textPrimary,
                              haptic: .selection, accessibilityLabel: "Close") {
                dismiss()
            }
            Spacer()
            Text("Select currency")
                .font(.headline)
                .foregroundStyle(SpendyColors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private func currencyGroup(_ title: String, currencies: [CurrencyInfo]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 4)
            LazyVStack(spacing: 0) {
                ForEach(currencies) { currency in
                    currencyRow(currency)
                    if currency.id != currencies.last?.id {
                        Divider()
                            .overlay(SpendyColors.separator)
                            .padding(.leading, 68)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }

    private func currencyRow(_ currency: CurrencyInfo) -> some View {
        let selected = activeSelectedCode == currency.code
        return Button {
            HapticsManager.shared.trigger(.selection)
            if let onSelect {
                onSelect(currency)
            } else {
                store.updateCurrency(symbol: currency.symbol, code: currency.code)
            }
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(currency.symbol)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(5)
                    .frame(width: 38, height: 38)
                    .background(Color.primary.opacity(0.06), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(currency.name).font(.subheadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(currency.code).font(.caption)
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                Spacer(minLength: 8)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(SpendyColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(currency.name), \(currency.code)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            TextField("Search currency", text: $searchText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SpendyColors.textTertiary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .nativeLiquidGlassCapsule(isInteractive: true)
        .shadow(color: Color.black.opacity(0.35), radius: 12, y: 4)
    }
}
