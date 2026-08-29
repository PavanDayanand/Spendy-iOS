//
//  SpendyColorPicker.swift
//  Spendy
//

import SwiftUI

// MARK: - Hue Spectrum Slider Component
public struct HueSpectrumSlider: View {
    @Binding var hue: Double
    
    public var body: some View {
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
public struct DarkBrightnessSlider: View {
    let hue: Double
    @Binding var brightness: Double
    
    private let minB: Double = 0.15
    private let maxB: Double = 0.95
    
    public var body: some View {
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

public struct SpendyColorPresetSwatches: View {
    @Binding var selectedHex: String
    var showSliderToggle: Bool = true
    @State private var showSliders: Bool = false
    @Binding var hue: Double
    @Binding var brightness: Double
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if showSliderToggle {
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
                    }
                    
                    ForEach(SpendyColors.presetAccentColors, id: \.self) { hex in
                        Button(action: {
                            selectedHex = hex
                            HapticsManager.shared.trigger(.light)
                        }) {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 38, height: 38)
                                .overlay {
                                    if selectedHex.uppercased() == hex.uppercased() {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2.5)
                                    }
                                }
                                .shadow(color: Color(hex: hex).opacity(0.3), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
            
            if showSliders {
                VStack(spacing: 14) {
                    HueSpectrumSlider(hue: $hue)
                    DarkBrightnessSlider(hue: hue, brightness: $brightness)
                }
                .padding(.vertical, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
