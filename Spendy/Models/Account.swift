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
        Account(id: "cash", label: "Cash", sfSymbol: SFIcons.cashAccount, colorHex: "#FFFFFF", openingBalance: 0.0, order: 0),
        Account(id: "bank", label: "SBI", sfSymbol: SFIcons.bankAccount, colorHex: "#18181B", openingBalance: 0.0, order: 1)
    ]
}
