//
//  OnboardingView.swift
//  Spendy
//
//  A short, text-led setup for currency and name.
//

import SwiftUI

public struct OnboardingView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int
    @State private var inputName: String = ""
    @State private var showCurrencyPicker = false
    @FocusState private var isNameFocused: Bool

    private let totalSteps = 3
    private let onComplete: () -> Void

    public init(initialStep: Int = 0, onComplete: @escaping () -> Void = {}) {
        let stepArgument = CommandLine.arguments.first { $0.starts(with: "--onboarding-step=") }
        let requestedStep = stepArgument.flatMap { Int($0.replacingOccurrences(of: "--onboarding-step=", with: "")) }
        _currentStep = State(initialValue: min(max(requestedStep ?? initialStep, 0), 2))
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                Spacer(minLength: 32)

                stepContent
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 32)

                Button {
                    if currentStep == totalSteps - 1 {
                        finishSetup()
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep += 1
                        }
                    }
                } label: {
                    Text(currentStep == totalSteps - 1 ? "Start using Spendy" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.elevatedControlForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(SpendyColors.elevatedControlFill, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(
                selectedCode: store.currencyCode,
                onSelect: { currency in
                    store.updateCurrency(symbol: currency.symbol, code: currency.code)
                    showCurrencyPicker = false
                }
            )
        }
        .onAppear {
            if store.currencyCode.isEmpty {
                store.updateCurrency(symbol: "₹", code: "INR")
            }
            if inputName.isEmpty {
                inputName = store.userName
            }
        }
        .onChange(of: currentStep) { _, step in
            isNameFocused = step == 2
        }
    }

    private var header: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    isNameFocused = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("\(currentStep + 1) of \(totalSteps)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            VStack(alignment: .leading, spacing: 14) {
                Text("Spendy")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)

                Text("A clearer view of your money.")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)

                Text("Track transactions, budgets, and subscriptions in one place.")
                    .font(.system(size: 16))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .padding(.top, 8)
            }

        case 1:
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose your currency")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)

                Text("You can change this later in Settings.")
                    .font(.system(size: 16))
                    .foregroundStyle(SpendyColors.textSecondary)

                Button {
                    showCurrencyPicker = true
                } label: {
                    HStack {
                        Text("\(store.currencyCode) · \(store.currencySymbol) · \(CurrencyInfo.name(for: store.currencyCode))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textPrimary)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    .padding(18)
                    .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }

        default:
            VStack(alignment: .leading, spacing: 18) {
                Text("What should we call you?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)

                Text("Your name is optional and can be changed later.")
                    .font(.system(size: 16))
                    .foregroundStyle(SpendyColors.textSecondary)

                TextField("Your name", text: $inputName)
                    .font(.system(size: 17))
                    .textContentType(.nickname)
                    .textInputAutocapitalization(.words)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit(finishSetup)
                    .padding(18)
                    .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 8)
            }
        }
    }

    private func finishSetup() {
        isNameFocused = false
        let name = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            store.userName = name
        }
        HapticsManager.shared.trigger(.success)
        store.hasCompletedOnboarding = true
        onComplete()
        dismiss()
    }
}

#Preview {
    OnboardingView()
        .environment(ExpenseStore())
}
