//
//  ContentView.swift
//  Spendy
//
//  Created by Pavan D on 19/8/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ExpenseStore.self) private var store
    @State private var showSaveError = false
    @State private var showRecoveryImporter = false
    @State private var showOnboardingOverride = Self.onboardingOverrideRequested
    
    var body: some View {
        Group {
            if let error = store.loadError {
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "externaldrive.badge.exclamationmark")
                            .font(.largeTitle)
                            .accessibilityHidden(true)
                        Text("Saved Data Needs Attention")
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text(error)
                            .multilineTextAlignment(.center)
                        VStack(spacing: 12) {
                            if store.hasRecoveryBackup {
                                Button("Restore Last Backup") { store.restoreRecoveryBackup() }
                                    .buttonStyle(.borderedProminent)
                            }
                            Button("Import a Backup") { showRecoveryImporter = true }
                                .buttonStyle(.bordered)
                            Button("Try Again") { store.loadFromDisk() }
                                .buttonStyle(.bordered)
                        }
                        .controlSize(.large)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                }
            } else if shouldShowOnboarding {
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
        .fileImporter(isPresented: $showRecoveryImporter, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                store.restoreRecoveryData(try Data(contentsOf: url))
            } catch {
                store.loadError = "The backup could not be opened. Your saved files are preserved. \(error.localizedDescription)"
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = store.sharedReceiptImportError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shared receipt needs attention").font(.headline)
                    Text(error).font(.subheadline)
                    Button("Retry") { store.ingestSharedReceipts() }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
            }
            if store.persistenceError != nil {
                HStack(spacing: 12) {
                    Label("Changes are not saved", systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                    Spacer(minLength: 0)
                    Button("Retry") { store.flushPendingSave() }
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal)
                .background(.regularMaterial)
            }
        }
        .onChange(of: store.persistenceError) { _, error in
            if error != nil { showSaveError = true }
        }
        .alert("Changes Could Not Be Saved", isPresented: $showSaveError) {
            Button("Retry Save") { store.flushPendingSave() }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text("Keep the app open and retry, or export a backup from Settings. \(store.persistenceError ?? "")")
        }
        .animation(reduceMotion ? nil : .spring(response: 0.50, dampingFraction: 0.86), value: shouldShowOnboarding)
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
