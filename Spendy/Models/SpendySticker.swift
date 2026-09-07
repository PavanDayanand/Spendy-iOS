//
//  SpendySticker.swift
//  Spendy
//
//  Illustrated brand sticker tokens for onboarding, avatar selection, and visual feedback
//

import SwiftUI

public enum SpendySticker: String, CaseIterable, Identifiable, Sendable {
    case growthChart = "Sticker1"
    case zenPeace = "Sticker3"
    case billDue = "Sticker4"
    case coffeeExpenses = "Sticker5"
    case catCompanion = "Sticker6"
    case piggySavings = "Sticker7"
    case moneyHug = "Sticker8"
    case icedBoba = "Sticker9"

    public var id: String { rawValue }
    public var assetName: String { rawValue }

    public var title: String {
        switch self {
        case .growthChart: return "The Strategist"
        case .zenPeace: return "The Zen Master"
        case .billDue: return "The Bill Hawk"
        case .coffeeExpenses: return "The Fuel Enthusiast"
        case .catCompanion: return "The Cat Whisperer"
        case .piggySavings: return "The Saver"
        case .moneyHug: return "The Wealth Keeper"
        case .icedBoba: return "The Daily Logger"
        }
    }

    public var subtitle: String {
        switch self {
        case .growthChart: return "you see the pattern before the number."
        case .zenPeace: return "the island is later. the calm is now."
        case .billDue: return "that bill does not get to surprise you."
        case .coffeeExpenses: return "expenses fuel life. noted."
        case .catCompanion: return "someone has to sit with the budget. that’s you two."
        case .piggySavings: return "one more coin. then another."
        case .moneyHug: return "protect it. then spend it on purpose."
        case .icedBoba: return "sip. log. done."
        }
    }

    public var launchLine: String {
        switch self {
        case .growthChart: return "board’s live. let’s go."
        case .zenPeace: return "quiet money. let’s go."
        case .billDue: return "i’m watching. let’s go."
        case .coffeeExpenses: return "fuel’s in. let’s go."
        case .catCompanion: return "i’m on the laptop. let’s go."
        case .piggySavings: return "coins ready. let’s go."
        case .moneyHug: return "bag’s coming with us. let’s go."
        case .icedBoba: return "one more sip. let’s go."
        }
    }

    public var firstLogLine: String {
        switch self {
        case .growthChart: return "give me one number. i’ll do the rest."
        case .zenPeace: return "log something small. keep the calm honest."
        case .billDue: return "what’s the first thing that billed you this month?"
        case .coffeeExpenses: return "log the coffee. that’s the whole app."
        case .catCompanion: return "drop one expense. i’ll sit on the rest."
        case .piggySavings: return "first coin in. the jar is listening."
        case .moneyHug: return "one honest spend. i’ll keep the rest close."
        case .icedBoba: return "one drink. that’s a start."
        }
    }

    public var image: Image {
        Image(assetName)
    }
}
