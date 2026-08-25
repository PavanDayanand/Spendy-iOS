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
    
    // Preset colors matching Image 2
    private let presetColors: [Color] = [
        Color(hex: "#FF3B30"), // Red
        Color(hex: "#FF9500"), // Orange
        Color(hex: "#FFCC00"), // Gold / Yellow
        Color(hex: "#34C759"), // Green
        Color(hex: "#00C7BE"), // Teal / Cyan
        Color(hex: "#007AFF"), // Blue
        Color(hex: "#5856D6"), // Purple
        Color(hex: "#AF52DE")  // Pink Violet
    ]
    
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
                    }
                    .buttonStyle(.plain)
                    
                    // Preset Color Circles
                    ForEach(presetColors, id: \.self) { color in
                        Button(action: {
                            store.setTopGradientColor(color)
                            HapticsManager.shared.trigger(.light)
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 38, height: 38)
                                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
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
                .tint(Color.green)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
        }
    }
}

// MARK: - Hue Spectrum Slider Component
private struct HueSpectrumSlider: View {
    @Binding var hue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let thumbX = CGFloat(hue) * width
            
            ZStack(alignment: .leading) {
                // Vibrant Full-Spectrum Rainbow Bar
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hue: 0.0, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.17, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.33, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.50, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.67, saturation: 1.0, brightness: 1.0),
                                Color(hue: 0.83, saturation: 1.0, brightness: 1.0),
                                Color(hue: 1.0, saturation: 1.0, brightness: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 38)
                
                // Draggable White Ring Thumb Indicator
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .background(Circle().fill(Color(hue: hue, saturation: 1.0, brightness: 1.0)))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: max(16, min(width - 16, thumbX)), y: 19)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = max(0, min(geometry.size.width, value.location.x))
                        let newHue = Double(locationX / geometry.size.width)
                        self.hue = newHue
                    }
            )
        }
        .frame(height: 38)
    }
}

// MARK: - Dark-to-Vibrant Brightness Slider Component
private struct DarkBrightnessSlider: View {
    let hue: Double
    @Binding var brightness: Double
    
    private let minB: Double = 0.15
    private let maxB: Double = 0.95
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let normB = (brightness - minB) / (maxB - minB)
            let thumbX = CGFloat(max(0, min(1, normB))) * width
            
            ZStack(alignment: .leading) {
                // Black to Saturated Vibrant Accent Bar
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black,
                                Color(hue: hue, saturation: 0.90, brightness: 0.50),
                                Color(hue: hue, saturation: 0.90, brightness: maxB)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 38)
                
                // Draggable White Ring Thumb Indicator
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .background(Circle().fill(Color(hue: hue, saturation: 0.90, brightness: min(max(brightness, minB), maxB))))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: max(16, min(width - 16, thumbX)), y: 19)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = max(0, min(geometry.size.width, value.location.x))
                        let fraction = Double(locationX / geometry.size.width)
                        let newB = minB + fraction * (maxB - minB)
                        self.brightness = min(max(minB, newB), maxB)
                    }
            )
        }
        .frame(height: 38)
    }
}
