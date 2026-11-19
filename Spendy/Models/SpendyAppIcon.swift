//
//  SpendyAppIcon.swift
//  Spendy
//
//  Alternate App Icon support for Spendy (Light Neo Glass, Obsidian Dark, Radiant Aurora)
//

import SwiftUI
import UIKit

enum SpendyAppIcon: String, CaseIterable, Identifiable, Codable, Sendable {
    case `default` = "AppIcon"
    case dark = "AppIcon-Dark"
    case radiant = "AppIcon-Radiant"
    case frosted = "SpendyFrosted"
    case ember = "SpendyFrostedEmber"
    case graphite = "SpendyFrostedGraphite"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .default: return "Classic"
        case .dark: return "Obsidian"
        case .radiant: return "Radiant"
        case .frosted: return "Neon Blue"
        case .ember: return "Ember Red"
        case .graphite: return "Graphite"
        }
    }
    
    var subtitle: String {
        switch self {
        case .default: return "Original mascot"
        case .dark: return "Deep Minimalist"
        case .radiant: return "Vibrant Gradient"
        case .frosted: return "Electric blue"
        case .ember: return "Warm red"
        case .graphite: return "Soft monochrome"
        }
    }
    
    var iconNameOrNil: String? {
        switch self {
        case .default: return nil
        case .dark: return "AppIcon-Dark"
        case .radiant: return "AppIcon-Radiant"
        case .frosted: return "SpendyFrosted"
        case .ember: return "SpendyFrostedEmber"
        case .graphite: return "SpendyFrostedGraphite"
        }
    }
    
    var assetImageName: String {
        switch self {
        case .default: return "AppIconPreview-Default"
        case .dark: return "AppIconPreview-Dark"
        case .radiant: return "AppIconPreview-Radiant"
        case .frosted: return "AppIconPreview-Frosted"
        case .ember: return "AppIconPreview-Ember"
        case .graphite: return "AppIconPreview-Graphite"
        }
    }
    
    @MainActor
    static var current: SpendyAppIcon {
        let name = UIApplication.shared.alternateIconName
        switch name {
        case "AppIcon-Dark": return .dark
        case "AppIcon-Radiant": return .radiant
        case "SpendyFrosted": return .frosted
        case "SpendyFrostedEmber": return .ember
        case "SpendyFrostedGraphite": return .graphite
        default: return .default
        }
    }
    
    /// The primary icon and Frosted both provide system-managed light/dark renditions.
    static let selectableIcons: [SpendyAppIcon] = [.frosted, .ember, .graphite]

    @MainActor
    static func setIcon(_ icon: SpendyAppIcon) async throws {
        guard UIApplication.shared.supportsAlternateIcons else {
            throw NSError(domain: "SpendyAppIcon", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "App icon changes are unavailable on this device."])
        }
        guard UIApplication.shared.alternateIconName != icon.iconNameOrNil else { return }
        try await UIApplication.shared.setAlternateIconName(icon.iconNameOrNil)
    }
}
