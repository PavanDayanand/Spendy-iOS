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
        self.type = type
        self.categoryId = categoryId
        self.accountId = accountId
        self.toAccountId = toAccountId
        self.date = date
        self.notes = notes
        self.subscriptionId = subscriptionId
    }
    
    // MARK: - Sample Data
    static let samples: [Transaction] = [
        Transaction(
            title: "Supermarket & Groceries",
            amount: 64.50,
            type: .expense,
            categoryId: "groceries",
            accountId: "bank",
            date: Date()
        ),
        Transaction(
            title: "Client Project Payment",
            amount: 1450.00,
            type: .income,
            categoryId: "freelance",
            accountId: "bank",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        Transaction(
            title: "Blue Bottle Coffee",
            amount: 6.75,
            type: .expense,
            categoryId: "food",
            accountId: "bank",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        Transaction(
            title: "Uber Ride",
            amount: 24.80,
            type: .expense,
            categoryId: "transport",
            accountId: "bank",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        ),
        Transaction(
            title: "Savings Transfer",
            amount: 300.00,
            type: .transfer,
            categoryId: "savings",
            accountId: "bank",
            toAccountId: "savings",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        )
    ]
}
