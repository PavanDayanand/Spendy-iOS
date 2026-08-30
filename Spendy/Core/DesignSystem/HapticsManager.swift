//
//  HapticsManager.swift
//  Spendy
//
//  Hardware-accelerated physical, zero-latency tactile haptic feedback
//

import UIKit
import SwiftUI

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()
    private init() {
        prepareAll()
    }
    
    var isEnabled: Bool = true
    
    // Cached, pre-warmed feedback generators for instant 0ms latency
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    enum FeedbackStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
        case selection
        case success
        case warning
        case error
        case tick
        case cardSnap
    }
    
    func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    func trigger(_ style: FeedbackStyle) {
        guard isEnabled else { return }
        
        switch style {
        case .light:
            lightImpact.impactOccurred()
            lightImpact.prepare()
        case .medium:
            mediumImpact.impactOccurred()
            mediumImpact.prepare()
        case .heavy:
            heavyImpact.impactOccurred()
            heavyImpact.prepare()
        case .soft:
            softImpact.impactOccurred()
            softImpact.prepare()
        case .rigid:
            rigidImpact.impactOccurred()
            rigidImpact.prepare()
        case .selection:
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        case .tick:
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        case .cardSnap:
            rigidImpact.impactOccurred(intensity: 0.85)
            rigidImpact.prepare()
        case .success:
            notificationFeedback.notificationOccurred(.success)
            notificationFeedback.prepare()
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
            notificationFeedback.prepare()
        case .error:
            notificationFeedback.notificationOccurred(.error)
            notificationFeedback.prepare()
        }
    }
}

// MARK: - SwiftUI Haptic Extensions
extension View {
    /// Plays crisp zero-latency tactile vibration on tap
    func spendyHapticFeedback(_ style: HapticsManager.FeedbackStyle = .selection) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticsManager.shared.trigger(style)
            }
        )
    }
}
