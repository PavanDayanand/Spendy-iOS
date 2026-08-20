//
//  Account.swift
//  Spendy
//
//  Account Model with Pure SF Symbols
//

import SwiftUI

struct Account: Identifiable, Codable, Hashable {
    var id: String
    var label: String
    var sfSymbol: String
    var colorHex: String
    var openingBalance: Double
    var order: Int
    
    init(
        id: String,
        label: String,
        sfSymbol: String = SFIcons.bankAccount,
        colorHex: String = "#007AFF",
        openingBalance: Double = 0.0,
        order: Int = 0
    ) {
        self.id = id
        self.label = label
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.openingBalance = openingBalance
        self.order = order
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    // MARK: - Default Accounts
    static let defaultAccounts: [Account] = [
        Account(id: "bank", label: "Main Checking", sfSymbol: SFIcons.bankAccount, colorHex: "#007AFF", openingBalance: 2450.0, order: 0),
        Account(id: "savings", label: "High Yield Savings", sfSymbol: SFIcons.savingsAccount, colorHex: "#30D158", openingBalance: 8200.0, order: 1),
        Account(id: "cash", label: "Wallet Cash", sfSymbol: SFIcons.cashAccount, colorHex: "#FF9500", openingBalance: 180.0, order: 2),
        Account(id: "credit", label: "Apple Card", sfSymbol: SFIcons.creditCard, colorHex: "#5856D6", openingBalance: 0.0, order: 3)
    ]
}
