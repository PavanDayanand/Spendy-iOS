//
//  SpendyKeypad.swift
//  Spendy
//
//  Shared 3×4 Numeric Keypad with Tactile Press Style
//  Used by AddTransactionView and EditBudgetSheet
//

import SwiftUI

// MARK: - Shared Numeric Keypad
struct SpendyKeypad: View {
    @Binding var amountString: String
    var maxDigits: Int = 10
    var maxDecimals: Int = 2
    var buttonBackgroundColor: Color = Color(hex: "#1C1C1E")
    var useLiquidGlass: Bool = false
    
    private let rows = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "delete"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        keypadCell(key: key)
                    }
                }
            }
        }
    }
    
    private func keypadCell(key: String) -> some View {
        Button(action: {
            handleKeypress(key)
        }) {
            ZStack {
                if key == "delete" || key == "backspace" {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Color.white)
                } else {
                    Text(key)
                        .font(.system(size: 24, weight: .medium, design: .default))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .modifier(KeypadBackgroundModifier(useLiquidGlass: useLiquidGlass, buttonBackgroundColor: buttonBackgroundColor))
        }
        .buttonStyle(KeypadPressStyle())
    }
    
    private func handleKeypress(_ key: String) {
        if key == "delete" || key == "backspace" {
            HapticsManager.shared.trigger(.cardSnap)
            if amountString.count > 1 {
                amountString.removeLast()
            } else {
                amountString = "0"
            }
            return
        }
        
        if key == "." {
            HapticsManager.shared.trigger(.selection)
            if !amountString.contains(".") {
                amountString += "."
            }
            return
        }
        
        // Digit (0-9)
        HapticsManager.shared.trigger(.tick)
        if amountString == "0" {
            amountString = key
        } else {
            // Enforce decimal limit
            if let dotIndex = amountString.firstIndex(of: ".") {
                let decimals = amountString[dotIndex...].count - 1
                if decimals >= maxDecimals { return }
            }
            // Enforce max digits
            let digitCount = amountString.replacingOccurrences(of: ".", with: "").count
            if digitCount >= maxDigits { return }
            amountString += key
        }
    }
}

// MARK: - Keypad Background Modifier (Pure Native Liquid Glass)
private struct KeypadBackgroundModifier: ViewModifier {
    var useLiquidGlass: Bool
    var buttonBackgroundColor: Color
    
    func body(content: Content) -> some View {
        if useLiquidGlass {
            content
                .nativeLiquidGlass(cornerRadius: 18, isInteractive: true)
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(buttonBackgroundColor)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.04), lineWidth: 0.8)
                        }
                }
        }
    }
}

// MARK: - Keypad Button Tactile Press Style
struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
