//
//  Account.swift
//  Spendy
//
//  Account Model with Pure SF Symbols and Custom Types
//

import SwiftUI

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case cash = "Cash"
    case bank = "Bank"
    case amazonPay = "Amazon Pay"
    case savings = "Savings"
    
    var id: String { rawValue }
    
    var defaultSymbol: String {
        switch self {
        case .cash: return "banknote.fill"
        case .bank: return "building.columns.fill"
        case .amazonPay: return "cart.fill"
        case .savings: return "heart.fill"
        }
    }
}

struct Account: Identifiable, Codable, Hashable {
    var id: String
    var label: String
    var sfSymbol: String
    var colorHex: String
    var openingBalance: Double
    var order: Int
    var type: AccountType
    
    init(
        id: String,
        label: String,
        sfSymbol: String = SFIcons.bankAccount,
        colorHex: String = "#007AFF",
        openingBalance: Double = 0.0,
        order: Int = 0,
        type: AccountType = .bank
    ) {
        self.id = id
        self.label = label
        self.sfSymbol = sfSymbol
        self.colorHex = colorHex
        self.openingBalance = openingBalance
        self.order = order
        self.type = type
    }
    
    enum CodingKeys: String, CodingKey {
        case id, label, sfSymbol, colorHex, openingBalance, order, type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        sfSymbol = try container.decode(String.self, forKey: .sfSymbol)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        openingBalance = try container.decode(Double.self, forKey: .openingBalance)
        order = try container.decode(Int.self, forKey: .order)
        type = try container.decodeIfPresent(AccountType.self, forKey: .type) ?? (id == "cash" ? .cash : .bank)
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    // MARK: - Default Accounts
    static let defaultAccounts: [Account] = [
        Account(id: "cash", label: "Cash", sfSymbol: SFIcons.cashAccount, colorHex: "#34C759", openingBalance: 0.0, order: 0, type: .cash),
        Account(id: "bank", label: "Bank Account", sfSymbol: SFIcons.bankAccount, colorHex: "#007AFF", openingBalance: 0.0, order: 1, type: .bank)
    ]
}
