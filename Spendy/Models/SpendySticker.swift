//
//  SpendySticker.swift
//  Spendy
//
//  Illustrated brand sticker tokens for onboarding, avatar selection, and visual feedback
//

import SwiftUI

public enum SpendySticker: String, CaseIterable, Identifiable, Sendable {
    case growthChart = "Sticker1"
    case planSpendSave = "Sticker2"
    case zenPeace = "Sticker3"
    case billDue = "Sticker4"
    case coffeeExpenses = "Sticker5"
    case catCompanion = "Sticker6"
    case piggySavings = "Sticker7"
    case moneyHug = "Sticker8"
    case icedBoba = "Sticker9"
    case dreamIsland = "Sticker10"
    
    public var id: String { rawValue }
    public var assetName: String { rawValue }
    
    public var title: String {
        switch self {
        case .growthChart: return "The Strategist"
        case .planSpendSave: return "The Mastermind"
        case .zenPeace: return "The Zen Master"
        case .billDue: return "The Bill Hawk"
        case .coffeeExpenses: return "The Fuel Enthusiast"
        case .catCompanion: return "The Cat Whisperer"
        case .piggySavings: return "The Saver"
        case .moneyHug: return "The Wealth Keeper"
        case .icedBoba: return "The Daily Logger"
        case .dreamIsland: return "The Dreamer"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .growthChart: return "Watching your wealth and net worth climb steadily"
        case .planSpendSave: return "Plan smart, spend with intent, save with ease"
        case .zenPeace: return "Total peace of mind with stress-free money flow"
        case .billDue: return "Never let an unexpected recurring charge slip through"
        case .coffeeExpenses: return "Honoring everyday habits without guilt"
        case .catCompanion: return "Your loyal buddy keeping your budget company"
        case .piggySavings: return "Building an unstoppable rainy-day reserve"
        case .moneyHug: return "Protecting and cherishing every single coin"
        case .icedBoba: return "Quick, effortless logging anywhere, anytime"
        case .dreamIsland: return "Funding your biggest life goals and bucket list"
        }
    }
    
    public var image: Image {
        Image(assetName)
    }
}
