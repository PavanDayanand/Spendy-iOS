//
//  AppIconPickerView.swift
//  Spendy
//
//  Alternate App Icon selector with interactive previews and liquid glass styling.
//

import SwiftUI

struct AppIconPickerView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIcon: SpendyAppIcon = .default
    
    var body: some View {
        ZStack {
            SpendyColors.settingsBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Customize your home screen with curated icons designed for light, dark, and vibrant aesthetics.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    
                    // Icon Options Card List
                    VStack(spacing: 12) {
                        ForEach(SpendyAppIcon.allCases) { icon in
                            let isSelected = currentIcon == icon
                            
                            Button {
                                HapticsManager.shared.trigger(.selection)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    currentIcon = icon
                                }
                                SpendyAppIcon.setIcon(icon)
                            } label: {
                                HStack(spacing: 16) {
                                    // App Icon Image Preview
                                    Image(icon.assetImageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                                    
                                    // Title and Subtitle
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(icon.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(SpendyColors.textPrimary)
                                        
                                        Text(icon.subtitle)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(SpendyColors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Selection Checkmark
                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? Color.blue : Color.white.opacity(0.08))
                                            .frame(width: 26, height: 26)
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(SpendyColors.sheetCardBackground)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(
                                                    isSelected ? Color.blue.opacity(0.5) : SpendyColors.separator,
                                                    lineWidth: isSelected ? 1.5 : 0.8
                                                )
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentIcon = SpendyAppIcon.current
        }
    }
}
