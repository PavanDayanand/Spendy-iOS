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
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .default: return "Default"
        case .dark: return "Obsidian"
        case .radiant: return "Radiant"
        }
    }
    
    var subtitle: String {
        switch self {
        case .default: return "Classic Neo Glass"
        case .dark: return "Deep Minimalist"
        case .radiant: return "Vibrant Gradient"
        }
    }
    
    var iconNameOrNil: String? {
        switch self {
        case .default: return nil
        case .dark: return "AppIcon-Dark"
        case .radiant: return "AppIcon-Radiant"
        }
    }
    
    var assetImageName: String {
        switch self {
        case .default: return "AppIconPreview-Default"
        case .dark: return "AppIconPreview-Dark"
        case .radiant: return "AppIconPreview-Radiant"
        }
    }
    
    @MainActor
    static var current: SpendyAppIcon {
        let name = UIApplication.shared.alternateIconName
        switch name {
        case "AppIcon-Dark": return .dark
        case "AppIcon-Radiant": return .radiant
        default: return .default
        }
    }
    
    @MainActor
    static func setIcon(_ icon: SpendyAppIcon) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let targetName = icon.iconNameOrNil
        guard UIApplication.shared.alternateIconName != targetName else { return }
        
        UIApplication.shared.setAlternateIconName(targetName) { error in
            if let error = error {
                print("⚠️ [SpendyAppIcon] Error setting alternate icon: \(error.localizedDescription)")
            }
        }
    }
}
