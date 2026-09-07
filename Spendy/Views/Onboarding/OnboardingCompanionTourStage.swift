//
//  OnboardingCompanionTourStage.swift
//  Spendy
//
//  Feature beat using the same recent-transactions card as Home, with dummy rows.
//

import SwiftUI

struct OnboardingCompanionTourStage: View {
    let companion: SpendySticker
    var onFinished: () -> Void

    @Environment(ExpenseStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var visibleCount: Int = 0
    @State private var dummyRows: [DummyRow] = []

    private struct DummyRow: Identifiable {
        let id = UUID()
        let title: String
        let amount: Double
        let categoryId: String
        let accountLabel: String
        let accountSymbol: String
        let accountColor: Color
    }

    var body: some View {
        VStack(spacing: 0) {
            recentTransactionsCard
                .padding(.horizontal, 24)
                .padding(.top, 8)

            Spacer(minLength: 12)

            FloatingStickerView(sticker: companion, size: 132)

            VStack(spacing: 8) {
                Text("track expenses & subscriptions")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)

                Text("your simple, delightful way to track expenses.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 4)

            Spacer(minLength: 8)

            Button {
                onFinished()
            } label: {
                HStack(spacing: 8) {
                    Text("continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(Color.white))
                .nativeLiquidGlassCapsule(isInteractive: true)
                .shadow(color: Color.white.opacity(0.30), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .accessibilityLabel("Continue")
        }
        .onAppear {
            if dummyRows.isEmpty {
                dummyRows = makeDummyRows()
            }
            runRowEntrance()
        }
    }

    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent transactions")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.white)

            VStack(spacing: 0) {
                ForEach(Array(dummyRows.enumerated()), id: \.element.id) { index, row in
                    if index < visibleCount {
                        dummyStyleRow(row)
                            .transition(.move(edge: .top).combined(with: .opacity))

                        if index < min(visibleCount, dummyRows.count) - 1 {
                            Rectangle()
                                .fill(SpendyColors.separator.opacity(0.6))
                                .frame(height: 0.5)
                                .padding(.leading, 58)
                                .padding(.trailing, 16)
                        }
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }

    private func dummyStyleRow(_ row: DummyRow) -> some View {
        let cat = store.categories.first(where: { $0.id == row.categoryId })
        let iconSymbol = cat?.sfSymbol ?? "cart.fill"
        let iconColor = cat?.color ?? Color(hex: "#34C759")
        let symbol = store.currencySymbol.isEmpty ? "₹" : store.currencySymbol

        return HStack(spacing: 14) {
            SpendyIconBadge(
                sfSymbol: iconSymbol,
                color: iconColor,
                size: .medium,
                style: .rounded()
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: row.accountSymbol)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(
                            row.accountColor,
                            in: RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        )
                        .shadow(color: row.accountColor.opacity(0.35), radius: 1, x: 0, y: 0)

                    Text(row.accountLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(row.amount.formattedCurrency(symbol: symbol))
                .spendyNumberFont(size: 16.5, weight: .bold, tracking: -0.5)
                .foregroundStyle(SpendyColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.title), \(row.amount.formattedCurrency(symbol: symbol)), \(row.accountLabel)")
    }

    private func makeDummyRows() -> [DummyRow] {
        let coffeeId = resolveCategoryId(preferred: ["coffee"], hints: ["coffee", "café", "cafe"])
        let groceryId = resolveCategoryId(preferred: ["groceries"], hints: ["groc"])
        let subId = resolveCategoryId(preferred: ["subscriptions"], hints: ["subscr"])

        return [
            DummyRow(
                title: "Coffee",
                amount: 180,
                categoryId: coffeeId,
                accountLabel: "Cash",
                accountSymbol: "dollarsign",
                accountColor: Color(hex: "#34C759")
            ),
            DummyRow(
                title: "Groceries",
                amount: 1_450,
                categoryId: groceryId,
                accountLabel: "Bank",
                accountSymbol: "building.columns.fill",
                accountColor: Color(hex: "#007AFF")
            ),
            DummyRow(
                title: "Subscriptions",
                amount: 649,
                categoryId: subId,
                accountLabel: "Bank",
                accountSymbol: "building.columns.fill",
                accountColor: Color(hex: "#007AFF")
            )
        ]
    }

    private func resolveCategoryId(preferred: [String], hints: [String]) -> String {
        for id in preferred where store.categories.contains(where: { $0.id == id }) {
            return id
        }
        for hint in hints {
            if let cat = store.categories.first(where: { $0.label.localizedCaseInsensitiveContains(hint) }) {
                return cat.id
            }
        }
        return store.categories.first(where: { $0.type == .expense })?.id ?? preferred.first ?? "coffee"
    }

    private func runRowEntrance() {
        let total = dummyRows.count
        guard total > 0 else { return }
        visibleCount = reduceMotion ? total : 0
        guard !reduceMotion else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            for i in 1...total {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    visibleCount = i
                }
                HapticsManager.shared.trigger(i == total ? .light : .soft)
                try? await Task.sleep(for: .milliseconds(180))
            }
        }
    }
}
