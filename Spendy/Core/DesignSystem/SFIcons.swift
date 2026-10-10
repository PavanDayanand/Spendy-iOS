//
//  SFIcons.swift
//  Spendy
//
//  Centralized SF Symbols Icon Engine (Pure Icons - 0 Emojis)
//

import SwiftUI
import UIKit

enum SFIcons {
    // MARK: - Navigation Tabs
    static let tabDashboard = "house.fill"
    static let tabDashboardOutline = "house"
    static let tabAnalytics = "chart.bar.fill"
    static let tabAnalyticsOutline = "chart.bar"
    static let tabBudget = "wallet.pass.fill"
    static let tabBudgetOutline = "wallet.pass"
    static let tabManage = "tray.2.fill"
    static let tabManageOutline = "tray.2"
    static let tabSettings = "gearshape.2.fill"
    static let tabSettingsOutline = "gearshape.2"
    static let quickAdd = "plus"
    static let plus = "plus"
    static let plusCircle = "plus.circle.fill"
    static let profile = "person.fill"
    static let profileCircle = "person.crop.circle.fill"
    
    // MARK: - Transaction Types
    static let expense = "arrow.up.right.circle.fill"
    static let expenseOutline = "arrow.up.right"
    static let income = "arrow.down.left.circle.fill"
    static let incomeOutline = "arrow.down.left"
    static let transfer = "arrow.left.arrow.right.circle.fill"
    static let transferOutline = "arrow.left.arrow.right"
    
    // MARK: - Default Categories (Expense)
    static let groceries = "cart.fill"
    static let food = "fork.knife"
    static let coffee = "cup.and.saucer.fill"
    static let foodDelivery = "bag.badge.plus"
    static let fuel = "fuelpump.fill"
    static let transport = "car.fill"
    static let publicTransport = "tram.fill"
    static let carMaintenance = "gearshape.2.fill"
    static let shopping = "bag.fill"
    static let housing = "house.fill"
    static let rent = "house.fill"
    static let utilities = "bolt.fill"
    static let subscriptions = "arrow.triangle.2.circlepath"
    static let insurance = "shield.fill"
    static let internetMobile = "antenna.radiowaves.left.and.right"
    static let education = "book.fill"
    static let entertainment = "popcorn.fill"
    static let health = "heart.fill"
    static let savings = "piggybank.fill"
    static let gifts = "gift.fill"
    static let beauty = "sparkles"
    static let clothing = "tshirt.fill"
    static let travel = "airplane"
    static let pets = "pawprint.fill"
    
    // MARK: - Default Categories (Income)
    static let paycheck = "banknote.fill"
    static let freelance = "laptopcomputer"
    static let investment = "chart.line.uptrend.xyaxis"
    static let refund = "arrow.counterclockwise"
    static let gift = "gift.fill"
    static let bonus = "sparkles"
    static let interest = "percent"
    static let sideHustle = "wrench.and.screwdriver.fill"
    static let rentalIncome = "building.2.fill"
    static let dividends = "chart.bar.xaxis"
    static let giftsReceived = "gift.fill"
    
    // MARK: - Accounts & Management
    static let bankAccount = "building.columns.fill"
    static let bankAccountOutline = "building.columns"
    static let cashAccount = "banknote.fill"
    static let savingsAccount = "piggybank.fill"
    static let creditCard = "creditcard.fill"
    static let cryptoAccount = "bitcoinsign.circle.fill"
    static let investmentAccount = "chart.line.uptrend.xyaxis"
    static let digitalWallet = "wallet.pass.fill"
    static let digitalWalletOutline = "wallet.pass"
    static let categoriesGrid = "square.grid.2x2.fill"
    static let categoriesGridOutline = "square.grid.2x2"
    static let recurrings = "calendar.badge.clock"
    static let tags = "tag.fill"
    static let tagOutline = "tag"
    static let automation = "arrow.triangle.branch"
    
    // MARK: - Subscriptions & Services
    static let streaming = "play.tv.fill"
    static let music = "music.note.house.fill"
    static let cloudStorage = "icloud.fill"
    static let artificialIntelligence = "cpu.fill"
    static let gaming = "gamecontroller.fill"
    static let fitness = "figure.run"
    static let news = "newspaper.fill"
    static let delivery = "shippingbox.fill"
    static let vpn = "lock.shield.fill"
    static let designTools = "paintpalette.fill"
    static let devTools = "terminal.fill"
    static let productivity = "doc.text.fill"
    static let telecom = "antenna.radiowaves.left.and.right"
    
    // MARK: - Actions & UI
    static let search = "magnifyingglass"
    static let searchCircle = "magnifyingglass.circle.fill"
    static let filter = "slider.horizontal.3"
    static let eye = "eye"
    static let eyeSlash = "eye.slash"
    static let eyeCircle = "eye.circle.fill"
    static let eyeSlashCircle = "eye.slash.circle.fill"
    static let calendar = "calendar"
    static let amountKeypad = "circle.grid.3x3.fill"
    static let amountRuler = "ruler"
    static let repeatIcon = "arrow.triangle.2.circlepath"
    static let checkmark = "checkmark"
    static let checkmarkCircle = "checkmark.circle.fill"
    static let delete = "trash.fill"
    static let trash = "trash"
    static let edit = "pencil"
    static let chevronRight = "chevron.right"
    static let chevronLeft = "chevron.left"
    static let chevronDown = "chevron.down"
    static let chevronUp = "chevron.up"
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
    static let subscriptionsFolder = "arrow.triangle.2.circlepath"
    static let scanReceipt = "viewfinder"
    static let voiceMic = "mic.fill"
    static let voiceMicOutline = "mic"
    static let appearance = "circle.lefthalf.filled"
    static let applePay = "bolt.fill"
    static let dataManagement = "cylinder.split.1x2"
    static let notification = "bell.fill"
    static let notificationOutline = "bell"
    static let language = "globe"
    
    /// Hide symbols unavailable on this device instead of showing empty choices.
    static func availableSymbols(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted && UIImage(systemName: $0) != nil }
    }

    /// Helper to safely resolve an SF Symbol with a fallback
    static func symbol(named name: String, fallback: String = "square.grid.2x2.fill") -> String {
        return !name.isEmpty && UIImage(systemName: name) != nil ? name : fallback
    }
}
