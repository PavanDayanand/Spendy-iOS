//
//  SpendySpeedLoggerSheet.swift
//  Spendy
//
//  Minimal Liquid Glass Voice & Speed Logger.
//  Matches native recording HUD (Screenshot 1) and Review Transactions Sheet (Screenshot 2).
//

import SwiftUI
import Speech

struct SpendySpeedLoggerSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    enum ScreenState {
        case listening
        case review
    }
    
    @State private var screenState: ScreenState = .listening
    @State private var speechManager = SpendySpeechRecognitionManager()
    @State private var recordingDuration: Int = 0
    @State private var timer: Timer? = nil
    
    @State private var drafts: [ParsedTransactionDraft] = []
    @State private var isSubmitting: Bool = false
    @State private var showSuccessAnimation: Bool = false
    
    init() {}
    
    private var defaultAccount: Account? {
        store.accounts.first
    }
    
    private var selectedDrafts: [ParsedTransactionDraft] {
        drafts.filter { $0.isSelected }
    }
    
    private var allSelected: Bool {
        !drafts.isEmpty && drafts.allSatisfy { $0.isSelected }
    }
    
    var body: some View {
        ZStack {
            // Liquid Glass Background
            SpendyColors.cardBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                switch screenState {
                case .listening:
                    listeningView
                case .review:
                    reviewView
                }
            }
            
            if showSuccessAnimation {
                successOverlay
            }
        }
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .onAppear {
            startListeningSession()
        }
        .onDisappear {
            stopListeningSession()
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: screenState)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: drafts)
    }
    
    // MARK: - 1. Listening HUD View (Screenshot 1)
    private var listeningView: some View {
        VStack(spacing: 0) {
            // Top Cancel
            HStack {
                GlassCircleButton(
                    icon: "xmark",
                    size: 44,
                    iconSize: 13,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .light,
                    accessibilityLabel: "Close"
                ) {
                    stopListeningSession()
                    dismiss()
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            // Center Live Speech State
            VStack(spacing: 8) {
                if speechManager.transcribedText.isEmpty {
                    Text("Start speaking...")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("5 voice entries left")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(SpendyColors.separator.opacity(0.6)))
                } else {
                    Text("“\(speechManager.transcribedText)”")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Bottom Floating Recorder Bar (Screenshot 1)
            bottomFloatingRecorderBar
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }
    
    // MARK: - Bottom Floating Recorder Bar
    private var bottomFloatingRecorderBar: some View {
        HStack(spacing: 12) {
            // Left Cancel Button (44pt)
            Button {
                SoundManager.shared.playWithHaptic(.tap, haptic: .light)
                stopListeningSession()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(SpendyColors.cardBackgroundSecondary, in: Circle())
                    .overlay(Circle().stroke(SpendyColors.separator, lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            
            // Center Dotted Waveform Meter & Timer
            HStack(spacing: 5) {
                ForEach(0..<speechManager.audioLevels.count, id: \.self) { index in
                    Circle()
                        .fill(SpendyColors.textPrimary.opacity(0.85))
                        .frame(
                            width: max(3.5, speechManager.audioLevels[index] * 7),
                            height: max(3.5, speechManager.audioLevels[index] * 7)
                        )
                }
                
                Spacer()
                
                Text(formattedTimer(recordingDuration))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                Capsule()
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .overlay(Capsule().stroke(SpendyColors.separator, lineWidth: 0.8))
            )
            
            // Right Stop Recording Button (44pt)
            Button {
                finishAndTransitionToReview()
            } label: {
                ZStack {
                    Circle()
                        .fill(SpendyColors.cardBackgroundSecondary)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(SpendyColors.separator, lineWidth: 0.8))
                    
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .fill(SpendyColors.expenseRed)
                        .frame(width: 15, height: 15)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 2. Review Transactions View (Screenshot 2)
    private var reviewView: some View {
        VStack(spacing: 0) {
            // Header Bar (Screenshot 2)
            HStack {
                GlassCircleButton(
                    icon: "xmark",
                    size: 44,
                    iconSize: 13,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .light,
                    accessibilityLabel: "Close"
                ) {
                    dismiss()
                }
                
                Text("Review transactions")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .padding(.leading, 6)
                
                Spacer()
                
                // Select / Unselect All Pill
                if !drafts.isEmpty {
                    Button {
                        SoundManager.shared.playWithHaptic(.tap, haptic: .selection)
                        let target = !allSelected
                        for i in 0..<drafts.count {
                            drafts[i].isSelected = target
                        }
                    } label: {
                        Text(allSelected ? "Unselect all" : "Select all")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(SpendyColors.cardBackgroundSecondary)
                                    .overlay(Capsule().stroke(SpendyColors.separator, lineWidth: 0.8))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            // Section Header ("Today" + "X items")
            HStack {
                Text("Today")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Text("\(drafts.count) items")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if drafts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "waveform.badge.exclamationmark")
                                .font(.system(size: 38))
                                .foregroundStyle(SpendyColors.textTertiary)
                            Text("No transactions recognized")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(SpendyColors.textPrimary)
                            Text("Tap Start speaking and say amounts like “Groceries 20 thousand and Fuel 15 thousand”.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 32)
                    } else {
                        ForEach($drafts) { $draft in
                            reviewTransactionRow(draft: $draft)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            
            // Bottom Save Action Button (Screenshot 2)
            VStack {
                let count = selectedDrafts.count
                let canSave = count > 0
                
                Button {
                    commitSelectedTransactions()
                } label: {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .heavy))
                            Text(count > 1 ? "Save \(count) transactions" : (count == 1 ? "Save transaction" : "Select transactions to save"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(canSave ? Color.white : SpendyColors.cardBackgroundSecondary)
                    )
                    .foregroundStyle(canSave ? Color.black : SpendyColors.textTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: canSave ? 0 : 0.8)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSave || isSubmitting)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Review Transaction Row (Screenshot 2)
    private func reviewTransactionRow(draft: Binding<ParsedTransactionDraft>) -> some View {
        let cat = draft.wrappedValue.category
        let acc = draft.wrappedValue.account ?? defaultAccount
        let isInteger = draft.wrappedValue.amount.truncatingRemainder(dividingBy: 1) == 0
        let formattedAmt = draft.wrappedValue.amount.formattedCurrency(symbol: store.currencySymbol, decimals: isInteger ? 0 : 2)
        let themeColor = cat != nil ? Color(hex: cat!.colorHex) : SpendyColors.primaryBlue
        
        return Button {
            SoundManager.shared.playWithHaptic(.tap, haptic: .selection)
            draft.wrappedValue.isSelected.toggle()
        } label: {
            HStack(spacing: 14) {
                // Checkbox Circle
                Image(systemName: draft.wrappedValue.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(draft.wrappedValue.isSelected ? Color.white : SpendyColors.textTertiary)
                
                // Category Icon with Blue Sparkle Overlay Badge (✨)
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: cat?.sfSymbol ?? "bag.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                    
                    // Sparkle badge overlay
                    Circle()
                        .fill(SpendyColors.primaryBlue)
                        .frame(width: 17, height: 17)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.white)
                        )
                        .offset(x: 3, y: -3)
                }
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(draft.wrappedValue.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    HStack(spacing: 4) {
                        if !draft.wrappedValue.notes.isEmpty && draft.wrappedValue.notes.lowercased() != draft.wrappedValue.title.lowercased() {
                            Text(draft.wrappedValue.notes)
                            Text("•")
                        }
                        Text(acc?.label ?? "Cash")
                    }
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .lineLimit(1)
                }
                
                Spacer()
                
                // Formatted Amount
                Text(formattedAmt)
                    .spendyNumberFont(size: 17, weight: .bold, tracking: -0.4)
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(draft.wrappedValue.isSelected ? SpendyColors.separator.opacity(0.9) : SpendyColors.separator.opacity(0.4), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(SpendyColors.incomeGreen)
                    .scaleEffect(showSuccessAnimation ? 1.0 : 0.4)
                
                Text(selectedDrafts.count > 1 ? "\(selectedDrafts.count) Transactions Saved!" : "Transaction Saved!")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            .padding(26)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThinMaterial))
        }
        .transition(.opacity)
    }
    
    // MARK: - Audio & State Transitions
    private func startListeningSession() {
        screenState = .listening
        recordingDuration = 0
        SoundManager.shared.playWithHaptic(.tap, haptic: .light)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1
        }
        
        speechManager.startListening { transcript in
            // Transcript continuously updating
        }
    }
    
    private func stopListeningSession() {
        timer?.invalidate()
        timer = nil
        speechManager.stopListening()
    }
    
    private func finishAndTransitionToReview() {
        stopListeningSession()
        SoundManager.shared.playWithHaptic(.tap, haptic: .medium)
        
        let parsed = NaturalLanguageTransactionParser.parseMultiple(
            text: speechManager.transcribedText,
            categories: store.categories,
            accounts: store.accounts,
            defaultAccount: defaultAccount
        )
        
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            drafts = parsed.filter { $0.amount > 0 }
            screenState = .review
        }
    }
    
    private func commitSelectedTransactions() {
        guard !selectedDrafts.isEmpty else { return }
        
        isSubmitting = true
        SoundManager.shared.playWithHaptic(.successChime, haptic: .cardSnap)
        
        for draft in selectedDrafts {
            let cat = draft.category ?? store.categories.first!
            let acc = draft.account ?? defaultAccount ?? store.accounts.first!
            
            let tx = Transaction(
                title: draft.title,
                amount: draft.amount,
                type: draft.type,
                categoryId: cat.id,
                accountId: acc.id,
                date: draft.date,
                notes: draft.rawText
            )
            store.addTransaction(tx)
        }
        
        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
            showSuccessAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            dismiss()
        }
    }
    
    private func formattedTimer(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
