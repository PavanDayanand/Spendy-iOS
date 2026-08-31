//
//  Transaction.swift
//  Spendy
//
//  Transaction Data Model and Enums
//

import SwiftUI

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .transfer: return "Transfer"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .expense: return SFIcons.expense
        case .income: return SFIcons.income
        case .transfer: return SFIcons.transfer
        }
    }
    
    var color: Color {
        switch self {
        case .expense: return SpendyColors.expenseRed
        case .income: return SpendyColors.incomeGreen
        case .transfer: return SpendyColors.transferBlue
        }
    }
}

struct Transaction: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var amount: Double
    var toAmount: Double?
    var type: TransactionType
    var categoryId: String
    var accountId: String
    var toAccountId: String?
    var date: Date
    var notes: String?
    var subscriptionId: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        toAmount: Double? = nil,
        type: TransactionType = .expense,
        categoryId: String,
        accountId: String,
        toAccountId: String? = nil,
        date: Date = Date(),
        notes: String? = nil,
        subscriptionId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.toAmount = toAmount
        self.type = type
        self.categoryId = categoryId
        self.accountId = accountId
        self.toAccountId = toAccountId
        self.date = date
        self.notes = notes
        self.subscriptionId = subscriptionId
    }
    
    // MARK: - Sample Data
    static let samples: [Transaction] = []
}
