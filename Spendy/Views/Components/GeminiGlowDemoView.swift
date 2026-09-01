//
//  GeminiGlowDemoView.swift
//  Spendy
//
//  Interactive Showcase & Playground for Gemini Animated Gradient Glow Modifier
//

import SwiftUI

public struct GeminiGlowDemoView: View {
    @State private var isThinking: Bool = false
    @State private var isStreaming: Bool = false
    @State private var promptText: String = "Analyze my monthly dining budget..."
    @State private var streamedTest: String = ""
    @State private var selectedCornerRadius: CGFloat = 18.0
    @State private var showNoiseOverlay: Bool = true
    @State private var autoDismissEnabled: Bool = true
    
    private let sampleResponses = [
        "Based on your recent transactions, your dining expenses decreased by 14% compared to last month. You're well within your $450 safe spending target!",
        "Gemini analyzed 32 transactions. Recurring subscriptions total $84.50/mo. Consider reviewing inactive memberships.",
        "Your savings velocity is trending upward! You have accumulated an extra $320 this pay period."
    ]
    
    @State private var responseIndex: Int = 0
    @State private var streamingTask: Task<Void, Never>? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        
                        // MARK: - Hero Header Banner
                        headerSection
                        
                        // MARK: - Live Chat Window & Response Demo
                        liveChatDemonstrationSection
                        
                        // MARK: - Interactive Prompt Input Bar
                        promptInputBarSection
                        
                        // MARK: - Standalone Shape & Container Showcase
                        shapeShowcaseSection
                        
                        // MARK: - Control Playground
                        controlPlaygroundSection
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.lg)
                }
            }
            .navigationTitle("Gemini Glow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: toggleThinking) {
                        HStack(spacing: 4) {
                            Image(systemName: isThinking ? "sparkles.rectangle.stack.fill" : "sparkles")
                                .symbolEffect(.bounce, value: isThinking)
                            Text(isThinking ? "Thinking" : "Trigger")
                                .font(AppTypography.subheadlineBold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isThinking ? .purple : .blue)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Gemini Glow Modifier")
                    .font(AppTypography.title2)
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            Text("Continuous rotating AngularGradient with dual-stroke bloom halo, crisp foreground edge, and subtle overlay grain.")
                .font(AppTypography.footnoteMedium)
                .foregroundStyle(SpendyColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.sm)
        }
        .padding(.top, AppSpacing.xs)
    }
    
    // MARK: - Live Chat & Response Section
    private var liveChatDemonstrationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("AI ASSISTANT RESPONSE")
                .font(AppTypography.eyebrow)
                .foregroundStyle(SpendyColors.textTertiary)
            
            VStack(alignment: .leading, spacing: AppSpacing.md12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Gemini Intelligence")
                        .font(AppTypography.subheadlineBold)
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    if isStreaming {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 6, height: 6)
                            Text("STREAMING")
                                .font(AppTypography.badgeMicro)
                                .foregroundStyle(Color.cyan)
                        }
                    }
                }
                
                Text(streamedTest.isEmpty ? "Tap 'Ask Gemini' below or trigger thinking state to watch the animated blooming glow respond." : streamedTest)
                    .font(AppTypography.footnoteMedium)
                    .foregroundStyle(streamedTest.isEmpty ? SpendyColors.textTertiary : SpendyColors.textPrimary)
                    .animation(AppMotion.snappySpring, value: streamedTest)
            }
            .padding(AppSpacing.md)
            .background(SpendyColors.cardBackgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: selectedCornerRadius, style: .continuous))
            // Apply Gemini Glow Modifier with custom corner radius and auto-dismiss
            .geminiGlow(
                isActive: isStreaming || isThinking,
                cornerRadius: selectedCornerRadius,
                showNoise: showNoiseOverlay,
                autoDismissAfter: autoDismissEnabled ? 5.0 : nil
            )
            .overlay {
                RoundedRectangle(cornerRadius: selectedCornerRadius, style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
        }
    }
    
    // MARK: - Prompt Input Bar Section
    private var promptInputBarSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("INTERACTIVE PROMPT CONTAINER")
                .font(AppTypography.eyebrow)
                .foregroundStyle(SpendyColors.textTertiary)
            
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bubble.left.and.sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isThinking ? Color.purple : SpendyColors.textTertiary)
                
                TextField("Ask anything...", text: $promptText)
                    .font(AppTypography.footnoteMedium)
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Button(action: startStreamingSimulation) {
                    Image(systemName: isStreaming ? "stop.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm6)
            .background(SpendyColors.cardBackground)
            .clipShape(Capsule(style: .continuous))
            // Apply Capsule Glow
            .geminiGlow(
                isActive: isThinking || isStreaming,
                shape: Capsule(style: .continuous),
                showNoise: showNoiseOverlay,
                autoDismissAfter: autoDismissEnabled ? 5.0 : nil
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
        }
    }
    
    // MARK: - Shape Showcase Section
    private var shapeShowcaseSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("SHAPE COMPATIBILITY")
                .font(AppTypography.eyebrow)
                .foregroundStyle(SpendyColors.textTertiary)
            
            HStack(spacing: AppSpacing.md) {
                // Card Shape
                VStack(spacing: 6) {
                    Image(systemName: "rectangle.roundedtop")
                        .font(.system(size: 20))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("Card (16pt)")
                        .font(AppTypography.badgeMicro)
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(SpendyColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .geminiGlow(isActive: isThinking, cornerRadius: 16, showNoise: showNoiseOverlay)
                
                // Capsule Pill
                VStack(spacing: 6) {
                    Image(systemName: "capsule")
                        .font(.system(size: 20))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("Pill")
                        .font(AppTypography.badgeMicro)
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(SpendyColors.cardBackground)
                .clipShape(Capsule(style: .continuous))
                .geminiGlow(isActive: isThinking, shape: Capsule(style: .continuous), showNoise: showNoiseOverlay)
                
                // Circular Badge
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.cyan)
                }
                .frame(width: 72, height: 72)
                .background(SpendyColors.cardBackground)
                .clipShape(Circle())
                .geminiGlow(isActive: isThinking, shape: Circle(), showNoise: showNoiseOverlay)
            }
        }
    }
    
    // MARK: - Control Playground Section
    private var controlPlaygroundSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("INTERACTIVE SETTINGS")
                .font(AppTypography.eyebrow)
                .foregroundStyle(SpendyColors.textTertiary)
            
            VStack(spacing: AppSpacing.md) {
                Toggle(isOn: $showNoiseOverlay) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Subtle Noise / Grain Texture")
                            .font(AppTypography.itemTitle)
                            .foregroundStyle(SpendyColors.textPrimary)
                        Text("Composited with .blendMode(.overlay)")
                            .font(AppTypography.captionMedium)
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
                .tint(SpendyColors.incomeGreen)
                
                Divider()
                    .background(SpendyColors.separator)
                
                Toggle(isOn: $autoDismissEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("5-Second Auto Ease Out")
                            .font(AppTypography.itemTitle)
                            .foregroundStyle(SpendyColors.textPrimary)
                        Text(".easeOut(duration: 0.6) on timeout")
                            .font(AppTypography.captionMedium)
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }
                .tint(SpendyColors.incomeGreen)
                
                Divider()
                    .background(SpendyColors.separator)
                
                HStack {
                    Text("Corner Radius")
                        .font(AppTypography.itemTitle)
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Picker("Radius", selection: $selectedCornerRadius) {
                        Text("12pt").tag(CGFloat(12))
                        Text("18pt").tag(CGFloat(18))
                        Text("24pt").tag(CGFloat(24))
                        Text("32pt").tag(CGFloat(32))
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 200)
                }
            }
            .padding(AppSpacing.md)
            .background(SpendyColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
        }
    }
    
    // MARK: - Actions & Streaming Simulation
    private func toggleThinking() {
        HapticsManager.shared.trigger(.selection)
        withAnimation(AppMotion.snappySpring) {
            isThinking.toggle()
        }
    }
    
    private func startStreamingSimulation() {
        if isStreaming {
            streamingTask?.cancel()
            streamingTask = nil
            isStreaming = false
            return
        }
        
        HapticsManager.shared.trigger(.light)
        isStreaming = true
        streamedTest = ""
        
        let fullText = sampleResponses[responseIndex % sampleResponses.count]
        responseIndex += 1
        
        streamingTask = Task { @MainActor in
            let words = fullText.split(separator: " ")
            for word in words {
                try? await Task.sleep(nanoseconds: 70_000_000)
                guard !Task.isCancelled else { break }
                streamedTest += (streamedTest.isEmpty ? "" : " ") + String(word)
            }
            
            // Allow user to see completed state briefly before settling
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            
            withAnimation(AppMotion.gentleSpring) {
                isStreaming = false
            }
        }
    }
}

// MARK: - Xcode Preview
struct GeminiGlowDemoView_Previews: PreviewProvider {
    static var previews: some View {
        GeminiGlowDemoView()
            .preferredColorScheme(.dark)
        
        GeminiGlowDemoView()
            .preferredColorScheme(.light)
    }
}
