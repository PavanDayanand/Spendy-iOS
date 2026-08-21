//
//  SubscriptionIconPickerSheet.swift
//  Spendy
//
//  Universal Sheet Drawer for Selecting Subscription Icons & Logos with Black & White Badges
//

import SwiftUI

struct SubscriptionIconCategory: Identifiable {
    let id = UUID()
    let title: String
    let symbols: [String]
}

private let defaultIconCategories: [SubscriptionIconCategory] = [
    SubscriptionIconCategory(title: "STREAMING & MEDIA", symbols: [
        "tv.fill", "play.tv.fill", "film.fill", "popcorn.fill", "video.fill", "play.circle.fill"
    ]),
    SubscriptionIconCategory(title: "MUSIC & AUDIO", symbols: [
        "music.note", "music.quaver.fill", "waveform", "headphones", "radio.fill", "mic.fill"
    ]),
    SubscriptionIconCategory(title: "TECH, AI & CLOUD", symbols: [
        "cpu.fill", "icloud.fill", "cloud.fill", "laptopcomputer", "terminal.fill",
        "globe", "sparkles", "brain.head.profile", "network", "server.rack"
    ]),
    SubscriptionIconCategory(title: "SOFTWARE & DEV", symbols: [
        "repeat", "square.stack.3d.up.fill", "folder.fill", "doc.text.fill", "curlybraces",
        "wrench.and.screwdriver.fill", "hammer.fill", "gearshape.fill", "square.and.pencil"
    ]),
    SubscriptionIconCategory(title: "GAMING & ENTERTAINMENT", symbols: [
        "gamecontroller.fill", "arcade.stick.console", "puzzlepiece.fill", "dice.fill"
    ]),
    SubscriptionIconCategory(title: "FINANCE & SHOPPING", symbols: [
        "creditcard.fill", "banknote.fill", "building.columns.fill", "bag.fill",
        "cart.fill", "shippingbox.fill", "tag.fill", "percent"
    ]),
    SubscriptionIconCategory(title: "HEALTH, UTILITIES & LIFE", symbols: [
        "figure.run", "heart.fill", "bolt.fill", "newspaper.fill",
        "graduationcap.fill", "airplane", "car.fill", "house.fill"
    ])
]

struct SubscriptionIconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedSymbol: String
    @Binding var isDarkBadge: Bool
    
    @State private var searchText: String = ""
    
    private var filteredCategories: [SubscriptionIconCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return defaultIconCategories
        }
        return defaultIconCategories.compactMap { category in
            let matchingSymbols = category.symbols.filter { $0.lowercased().contains(query) }
            if matchingSymbols.isEmpty { return nil }
            return SubscriptionIconCategory(title: category.title, symbols: matchingSymbols)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - Live Badge Preview
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(isDarkBadge ? Color(hex: "#18181B") : Color.white)
                                    .frame(width: 76, height: 76)
                                    .shadow(color: isDarkBadge ? Color.black.opacity(0.5) : Color.white.opacity(0.15), radius: 16, x: 0, y: 8)
                                    .overlay {
                                        Circle()
                                            .stroke(isDarkBadge ? Color.white.opacity(0.25) : Color.black.opacity(0.15), lineWidth: 1.5)
                                    }
                                
                                Image(systemName: selectedSymbol)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(isDarkBadge ? .white : .black)
                            }
                            
                            Text("ICON BADGE COLOR")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(SpendyColors.textTertiary)
                            
                            // Badge Color Selector (White vs Black)
                            HStack(spacing: 12) {
                                Button(action: {
                                    isDarkBadge = false
                                    HapticsManager.shared.trigger(.selection)
                                }) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 14, height: 14)
                                            .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1))
                                        Text("White Badge")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background {
                                        Capsule()
                                            .fill(!isDarkBadge ? SpendyColors.textPrimary : SpendyColors.cardBackgroundSecondary)
                                    }
                                    .foregroundStyle(!isDarkBadge ? SpendyColors.appBackground : SpendyColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    isDarkBadge = true
                                    HapticsManager.shared.trigger(.selection)
                                }) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(hex: "#18181B"))
                                            .frame(width: 14, height: 14)
                                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                                        Text("Black Badge")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background {
                                        Capsule()
                                            .fill(isDarkBadge ? SpendyColors.textPrimary : SpendyColors.cardBackgroundSecondary)
                                    }
                                    .foregroundStyle(isDarkBadge ? SpendyColors.appBackground : SpendyColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 10)
                        
                        // MARK: - Search Field
                        HStack {
                            Image(systemName: SFIcons.search)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(SpendyColors.textTertiary)
                            
                            TextField("Search icons...", text: $searchText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                                }
                        }
                        
                        // MARK: - Categories Grid
                        VStack(spacing: 20) {
                            ForEach(filteredCategories) { category in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(category.title)
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.0)
                                        .foregroundStyle(SpendyColors.textTertiary)
                                        .padding(.horizontal, 4)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                        ForEach(category.symbols, id: \.self) { sym in
                                            Button(action: {
                                                selectedSymbol = sym
                                                HapticsManager.shared.trigger(.selection)
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedSymbol == sym ? SpendyColors.primaryBlue : SpendyColors.cardBackgroundSecondary)
                                                        .frame(width: 48, height: 48)
                                                        .overlay {
                                                            if selectedSymbol == sym {
                                                                Circle()
                                                                    .stroke(SpendyColors.textPrimary, lineWidth: 2)
                                                            }
                                                        }
                                                    
                                                    Image(systemName: sym)
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundStyle(
                                                            selectedSymbol == sym
                                                                ? Color(uiColor: .dynamic(light: .white, dark: .black))
                                                                : SpendyColors.textPrimary
                                                        )
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .presentationDetents([.large])
    }
}
