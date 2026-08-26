//
//  HapticsManager.swift
//  Spendy
//
//  Hardware-accelerated physical haptic feedback
//

import UIKit

final class HapticsManager {
    static let shared = HapticsManager()
    private init() {}
    
    var isEnabled: Bool = true
    
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
    }
    
    func trigger(_ style: FeedbackStyle) {
        guard isEnabled else { return }
        Task { @MainActor in
            switch style {
            case .light:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            case .medium:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            case .heavy:
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.prepare()
                generator.impactOccurred()
            case .soft:
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.prepare()
                generator.impactOccurred()
            case .rigid:
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.prepare()
                generator.impactOccurred()
            case .selection:
                let generator = UISelectionFeedbackGenerator()
                generator.prepare()
                generator.selectionChanged()
            case .success:
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
            case .warning:
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.warning)
            case .error:
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.error)
            }
        }
    }
}
