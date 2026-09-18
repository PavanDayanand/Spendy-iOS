//
//  SpendySticker.swift
//  Spendy
//
//  Illustrated brand sticker tokens for onboarding, avatar selection, companion coaching,
//  and dynamic financial commentary.
//

import SwiftUI

public enum SpendySticker: String, CaseIterable, Identifiable, Sendable {
    case growthChart = "Sticker1"
    case targetShield = "Sticker2"
    case zenPeace = "Sticker3"
    case billDue = "Sticker4"
    case coffeeExpenses = "Sticker5"
    case catCompanion = "Sticker6"
    case piggySavings = "Sticker7"
    case moneyHug = "Sticker8"

    public var id: String { rawValue }
    public var assetName: String { rawValue }

    public var title: String {
        switch self {
        case .growthChart: return "The Strategist"
        case .targetShield: return "The Guardian"
        case .zenPeace: return "The Zen Master"
        case .billDue: return "The Bill Hawk"
        case .coffeeExpenses: return "The Fuel Enthusiast"
        case .catCompanion: return "The Cat Whisperer"
        case .piggySavings: return "The Saver"
        case .moneyHug: return "The Wealth Keeper"
        }
    }

    public var subtitle: String {
        switch self {
        case .growthChart: return "you see the pattern before the number."
        case .targetShield: return "shielding your cash from impulsive spikes."
        case .zenPeace: return "the island is later. the calm is now."
        case .billDue: return "that bill does not get to surprise you."
        case .coffeeExpenses: return "expenses fuel life. noted."
        case .catCompanion: return "someone has to sit with the budget. that’s you two."
        case .piggySavings: return "one more coin. then another."
        case .moneyHug: return "protect it. then spend it on purpose."
        }
    }

    public var launchLine: String {
        switch self {
        case .growthChart: return "board’s live. let’s go."
        case .targetShield: return "defense line set. let’s go."
        case .zenPeace: return "quiet money. let’s go."
        case .billDue: return "i’m watching. let’s go."
        case .coffeeExpenses: return "fuel’s in. let’s go."
        case .catCompanion: return "i’m on the laptop. let’s go."
        case .piggySavings: return "coins ready. let’s go."
        case .moneyHug: return "bag’s coming with us. let’s go."
        }
    }

    public var firstLogLine: String {
        switch self {
        case .growthChart: return "give me one number. i’ll do the rest."
        case .targetShield: return "log your expense to keep shields powered up."
        case .zenPeace: return "log something small. keep the calm honest."
        case .billDue: return "what’s the first thing that billed you this month?"
        case .coffeeExpenses: return "log the coffee. that’s the whole app."
        case .catCompanion: return "drop one expense. i’ll sit on the rest."
        case .piggySavings: return "first coin in. the jar is listening."
        case .moneyHug: return "one honest spend. i’ll keep the rest close."
        }
    }
    
    // MARK: - Dynamic Mood Commentary
    public func interactiveQuote(tapIndex: Int) -> String {
        let quotes: [String]
        switch self {
        case .growthChart:
            quotes = [
                "Numbers tell stories. I help you write the best ending.",
                "Patterns revealed. You’re navigating like a pro!",
                "Check out that graph curve! Looking calculated.",
                "Every trend is an opportunity to optimize."
            ]
        case .targetShield:
            quotes = [
                "Shields holding strong! No unexpected spend breeches.",
                "I’ve got your back on every transaction.",
                "Target locked: Keep that budget in the green zone!",
                "Standing guard over your hard-earned funds."
            ]
        case .zenPeace:
            quotes = [
                "Breathe in calm, breathe out financial clarity.",
                "Peace of mind is the ultimate return on investment.",
                "Money flows smoothly when you stay centered.",
                "No stress, just mindful tracking one day at a time."
            ]
        case .billDue:
            quotes = [
                "No sneaky subscriptions on my watch!",
                "Eyes wide open on upcoming due dates.",
                "Bills scheduled, stress handled.",
                "Tracking recurring spends like a hawk."
            ]
        case .coffeeExpenses:
            quotes = [
                "Great financial plans start with great coffee.",
                "Fuel the hustle, log the brew!",
                "Espresso logged, productivity unleashed.",
                "Every cup accounted for and enjoyed."
            ]
        case .catCompanion:
            quotes = [
                "Purr-fect budgeting today! Keep it up.",
                "I’m warming up your keyboard while you log.",
                "Meow means: that was a very wise purchase.",
                "Nap scheduled right after we balance the books."
            ]
        case .piggySavings:
            quotes = [
                "Clink! Another coin safe in the stash.",
                "Small savings stack into mountain-sized wealth.",
                "Feed the piggy, watch your peace of mind grow.",
                "Every saved penny gives you superpower!"
            ]
        case .moneyHug:
            quotes = [
                "Hug your wealth tight, spend with clear intention.",
                "Your money loves being organized and valued.",
                "Wrapped in security and financial freedom.",
                "Safe, sound, and ready for future adventures."
            ]
        }
        return quotes[abs(tapIndex) % quotes.count]
    }

    public var image: Image {
        Image(assetName)
    }
}
