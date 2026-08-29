//
//  SFIcons.swift
//  Spendy
//
//  Centralized SF Symbols Icon Engine (Pure Icons - 0 Emojis)
//

import SwiftUI

enum SFIcons {
    // MARK: - Navigation Tabs
    static let tabDashboard = "rectangle.grid.2x2.fill"
    static let tabAnalytics = "chart.xyaxis.line"
    static let tabBudget = "gauge.with.dots.needle.bottom.50percent"
    static let tabManage = "tray.2.fill"
    static let tabSettings = "gearshape.2.fill"
    static let quickAdd = "plus.circle.fill"
    static let plus = "plus.circle.fill"
    static let profile = "person.crop.circle.fill"
    
    // MARK: - Transaction Types
    static let expense = "arrow.up.right.circle.fill"
    static let income = "arrow.down.left.circle.fill"
    static let transfer = "arrow.left.arrow.right.circle.fill"
    
    // MARK: - Default Categories (Expense)
    static let food = "fork.knife.circle.fill"
    static let transport = "car.side.fill"
    static let fuel = "fuelpump.circle.fill"
    static let groceries = "basket.fill"
    static let entertainment = "popcorn.circle.fill"
    static let savings = "piggybank.fill"
    static let subscriptions = "arrow.triangle.2.circlepath.circle.fill"
    static let shopping = "handbag.fill"
    static let health = "heart.square.fill"
    static let housing = "building.2.crop.circle.fill"
    static let utilities = "bolt.circle.fill"
    static let education = "book.closed.circle.fill"
    static let travel = "airplane.circle.fill"
    static let coffee = "mug.fill"
    static let insurance = "shield.inset.filled"
    static let internetMobile = "antenna.radiowaves.left.and.right.circle.fill"
    static let beauty = "sparkles.rectangle.stack.fill"
    static let clothing = "tshirt.circle.fill"
    static let gifts = "gift.circle.fill"
    static let pets = "pawprint.circle.fill"
    
    // MARK: - Default Categories (Income)
    static let paycheck = "banknote.fill"
    static let freelance = "laptopcomputer.and.iphone"
    static let investment = "chart.line.uptrend.xyaxis.circle.fill"
    static let refund = "arrow.counterclockwise.circle.fill"
    static let gift = "gift.circle.fill"
    static let bonus = "sparkles"
    static let interest = "percent"
    static let sideHustle = "wrench.and.screwdriver.fill"
    static let rentalIncome = "building.2.crop.circle.fill"
    static let dividends = "chart.bar.xaxis"
    static let giftsReceived = "gift.circle.fill"
    
    // MARK: - Accounts
    static let bankAccount = "landmark.fill"
    static let cashAccount = "dollarsign.square.fill"
    static let savingsAccount = "piggybank.fill"
    static let creditCard = "creditcard.circle.fill"
    static let cryptoAccount = "bitcoinsign.circle.fill"
    static let investmentAccount = "chart.line.uptrend.xyaxis.circle.fill"
    static let digitalWallet = "wallet.pass.fill"
    
    // MARK: - Subscriptions & Services
    static let streaming = "play.tv.fill"
    static let music = "music.note.house.fill"
    static let cloudStorage = "icloud.fill"
    static let artificialIntelligence = "cpu.fill"
    static let gaming = "gamecontroller.fill"
    static let fitness = "figure.run.circle.fill"
    static let news = "newspaper.fill"
    static let delivery = "shippingbox.circle.fill"
    static let vpn = "lock.shield.fill"
    static let designTools = "paintpalette.fill"
    static let devTools = "terminal.fill"
    static let productivity = "doc.text.fill"
    static let telecom = "antenna.radiowaves.left.and.right.circle.fill"
    
    // MARK: - Actions & UI
    static let search = "magnifyingglass.circle.fill"
    static let filter = "slider.horizontal.3"
    static let eye = "eye.circle.fill"
    static let eyeSlash = "eye.slash.circle.fill"
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
    static let subscriptionsFolder = "arrow.triangle.2.circlepath.circle.fill"
    
    /// Helper to safely resolve an SF Symbol with a fallback
    static func symbol(named name: String, fallback: String = "circle.grid.2x2.fill") -> String {
        return name.isEmpty ? fallback : name
    }
}
