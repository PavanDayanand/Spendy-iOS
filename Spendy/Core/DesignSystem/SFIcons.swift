//
//  SFIcons.swift
//  Spendy
//
//  Centralized SF Symbols Icon Engine (Pure Icons - 0 Emojis)
//

import SwiftUI

enum SFIcons {
    // MARK: - Navigation Tabs
    static let tabDashboard = "house.fill"
    static let tabAnalytics = "chart.pie.fill"
    static let tabBudget = "target"
    static let tabManage = "square.grid.2x2.fill"
    static let tabSettings = "gearshape.fill"
    static let quickAdd = "plus"
    static let plus = "plus"
    static let profile = "person.crop.circle.fill"
    
    // MARK: - Transaction Types
    static let expense = "arrow.up.right.circle.fill"
    static let income = "arrow.down.left.circle.fill"
    static let transfer = "arrow.left.arrow.right.circle.fill"
    
    // MARK: - Default Categories (Expense)
    static let food = "fork.knife"
    static let transport = "car.fill"
    static let groceries = "basket.fill"
    static let entertainment = "popcorn.fill"
    static let savings = "banknote.fill"
    static let subscriptions = "repeat"
    static let shopping = "bag.fill"
    static let health = "heart.fill"
    static let housing = "building.2.fill"
    static let utilities = "bolt.fill"
    static let education = "graduationcap.fill"
    static let travel = "airplane"
    
    // MARK: - Default Categories (Income)
    static let paycheck = "briefcase.fill"
    static let freelance = "laptopcomputer"
    static let investment = "chart.line.uptrend.xyaxis"
    static let refund = "arrow.uturn.backward.circle.fill"
    static let gift = "gift.fill"
    static let bonus = "sparkles"
    static let interest = "percent"
    
    // MARK: - Accounts
    static let bankAccount = "building.columns.fill"
    static let cashAccount = "banknote.fill"
    static let savingsAccount = "lock.shield.fill"
    static let creditCard = "creditcard.fill"
    static let cryptoAccount = "bitcoinsign.circle.fill"
    static let investmentAccount = "chart.bar.fill"
    
    // MARK: - Subscriptions & Services
    static let streaming = "tv.fill"
    static let music = "music.note"
    static let cloudStorage = "icloud.fill"
    static let artificialIntelligence = "cpu.fill"
    static let gaming = "gamecontroller.fill"
    static let fitness = "figure.run"
    static let news = "newspaper.fill"
    static let delivery = "shippingbox.fill"
    
    // MARK: - Actions & UI
    static let search = "magnifyingglass"
    static let filter = "line.3.horizontal.decrease.circle"
    static let calendar = "calendar"
    static let checkmark = "checkmark"
    static let checkmarkCircle = "checkmark.circle.fill"
    static let delete = "trash.fill"
    static let trash = "trash"
    static let edit = "pencil"
    static let chevronRight = "chevron.right"
    static let chevronLeft = "chevron.left"
    static let chevronDown = "chevron.down"
    static let close = "xmark"
    static let info = "info.circle"
    static let trendUp = "arrow.trend.up"
    static let trendDown = "arrow.trend.down"
    static let wallet = "wallet.pass.fill"
    static let lock = "lock.fill"
    static let exportData = "square.and.arrow.up"
    static let importData = "square.and.arrow.down"
    static let accountsFolder = "folder.fill"
    static let categoriesFolder = "square.stack.3d.up.fill"
    static let subscriptionsFolder = "repeat.circle.fill"
    
    /// Helper to safely resolve an SF Symbol with a fallback
    static func symbol(named name: String, fallback: String = "circle.grid.2x2.fill") -> String {
        return name.isEmpty ? fallback : name
    }
}
