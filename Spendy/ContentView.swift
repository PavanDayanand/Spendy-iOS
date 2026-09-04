//
//  ContentView.swift
//  Spendy
//
//  Created by Pavan D on 19/8/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(ExpenseStore.self) private var store
    
    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .scale(scale: 1.05).combined(with: .opacity)
                    ))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.50, dampingFraction: 0.86), value: shouldShowOnboarding)
    }
    
    private var shouldShowOnboarding: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(where: { $0.starts(with: "--onboarding") || $0 == "--reset-onboarding" }) {
            return true
        }
        #endif
        return !store.hasCompletedOnboarding
    }
}

#Preview {
    ContentView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
