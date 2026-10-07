//
//  ContentView.swift
//  Spendy
//
//  Created by Pavan D on 19/8/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var showOnboardingOverride = Self.onboardingOverrideRequested
    
    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingView(onComplete: {
                    showOnboardingOverride = false
                })
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
        showOnboardingOverride || !store.hasCompletedOnboarding
    }

    private static var onboardingOverrideRequested: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(where: {
            $0.starts(with: "--onboarding") || $0 == "--reset-onboarding"
        })
        #else
        return false
        #endif
    }
}

#Preview {
    ContentView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
