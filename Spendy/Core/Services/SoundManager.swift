//
//  SoundManager.swift
//  Spendy
//
//  Hardware-accelerated, zero-latency physical audio feedback engine
//  utilizing Apple's AudioToolbox SystemSoundID infrastructure.
//

import Foundation
import AudioToolbox
import UIKit

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    
    private init() {}
    
    var isEnabled: Bool = true
    
    enum SoundEffect {
        /// Subtle mechanical tap (1104)
        case tap
        /// Smooth card pop / slide (1054)
        case pageTransition
        /// Typewriter / keyboard key stroke (1104)
        case keyStroke
        /// Coin drop / metallic tink (1057)
        case currencySelect
        /// Apple Pay style confirmation chime (1407)
        case successChime
        /// Gentle tick (1105)
        case tick
        
        var systemSoundID: SystemSoundID {
            switch self {
            case .tap: return 1104
            case .pageTransition: return 1054
            case .keyStroke: return 1104
            case .currencySelect: return 1057
            case .successChime: return 1407
            case .tick: return 1105
            }
        }
    }
    
    /// Plays the requested sound effect if sounds are enabled
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }
    
    /// Seamlessly coordinates physical tactile haptics with zero-latency audio
    func playWithHaptic(_ effect: SoundEffect, haptic: HapticsManager.FeedbackStyle = .selection) {
        if isEnabled {
            AudioServicesPlaySystemSound(effect.systemSoundID)
        }
        HapticsManager.shared.trigger(haptic)
    }
}
