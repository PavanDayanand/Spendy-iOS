//
//  MascotCompanionPickerSheet.swift
//  Spendy
//
//  Interactive Mascot Companion Switcher with floating tactile physics,
//  comic speech bubbles, and instant character switching.
//

import SwiftUI

public struct MascotCompanionPickerSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSticker: SpendySticker
    @State private var isBouncing: Bool = false
    
    public init(initialSticker: SpendySticker) {
        _selectedSticker = State(initialValue: initialSticker)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.settingsBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. Hero Showcase of Selected Mascot
                        VStack(spacing: 12) {
                            SpendyCharacterMomentCard(
                                sticker: selectedSticker,
                                speechText: selectedSticker.subtitle,
                                kicker: "Active Mascot",
                                stickerSize: 120
                            )
                            
                            SpendyComicBadge(
                                selectedSticker.title,
                                palette: .cyberGold,
                                size: .small,
                                rotationAngle: -4
                            )
                        }
                        .padding(.top, 10)
                        
                        // 2. Mascot Selection Grid
                        VStack(alignment: .leading, spacing: 14) {
                            Text("CHOOSE YOUR COMPANION")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .tracking(0.8)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(SpendySticker.allCases) { sticker in
                                    let isChosen = selectedSticker == sticker
                                    
                                    Button {
                                        HapticsManager.shared.trigger(.selection)
                                        withAnimation(.spring(response: 0.32, dampingFraction: 0.65)) {
                                            selectedSticker = sticker
                                            store.selectedSticker = sticker.rawValue
                                            if let uiImage = UIImage(named: sticker.assetName),
                                               let data = uiImage.pngData() {
                                                store.profileImageData = data
                                            }
                                        }
                                    } label: {
                                        VStack(spacing: 8) {
                                            sticker.image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 80, height: 80)
                                                .scaleEffect(isChosen ? 1.08 : 0.95)
                                            
                                            Text(sticker.title)
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundStyle(isChosen ? SpendyColors.textPrimary : SpendyColors.textSecondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 10)
                                        .background {
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(isChosen ? SpendyColors.primaryBlue.opacity(0.18) : SpendyColors.cardBackground)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                        .stroke(
                                                            isChosen ? SpendyColors.primaryBlue : SpendyColors.separator,
                                                            lineWidth: isChosen ? 2.0 : 0.8
                                                        )
                                                }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Companion Mascot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                }
            }
        }
    }
}
