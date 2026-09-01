//
//  CustomColorSliderPickerView.swift
//  Spendy
//
//  Custom Color Picker Card & Sliders matching Image 2 design
//

import SwiftUI

struct CustomColorSliderPickerView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showSliders: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Row 1: Swatches (Rainbow Wheel + Presets)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Rainbow Spectrum Circle Button (Toggles Sliders)
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showSliders.toggle()
                        }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red]),
                                    center: .center
                                )
                            )
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: showSliders ? 3 : 0)
                            )
                            .shadow(color: Color.white.opacity(0.35), radius: showSliders ? 4 : 0)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Preset Color Circles
                    ForEach(SpendyColors.presetAccentColors, id: \.self) { hex in
                        Button(action: {
                            store.setTopGradientColor(Color(hex: hex))
                            HapticsManager.shared.trigger(.light)
                        }) {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 38, height: 38)
                                .shadow(color: Color(hex: hex).opacity(0.3), radius: 3, x: 0, y: 2)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
            
            // MARK: - Sliders (Hue & Dark-Brightness)
            if showSliders {
                VStack(spacing: 14) {
                    // 1. Hue Slider
                    HueSpectrumSlider(hue: Binding(
                        get: { store.topGradientHue },
                        set: { store.topGradientHue = $0 }
                    ))
                    
                    // 2. Dark-to-Medium Brightness Slider (Clamped max 0.55 for Dark Mode)
                    DarkBrightnessSlider(
                        hue: store.topGradientHue,
                        brightness: Binding(
                            get: { store.topGradientBrightness },
                            set: { store.topGradientBrightness = $0 }
                        )
                    )
                }
                .padding(.vertical, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Divider()
                .overlay(SpendyColors.separator)
            
            // MARK: - Gradient Background Toggle
            HStack {
                Text("Gradient background")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { store.isGradientBackgroundEnabled },
                    set: {
                        store.isGradientBackgroundEnabled = $0
                        HapticsManager.shared.trigger(.selection)
                    }
                ))
                .labelsHidden()
                .tint(SpendyColors.incomeGreen)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
        }
    }
}
