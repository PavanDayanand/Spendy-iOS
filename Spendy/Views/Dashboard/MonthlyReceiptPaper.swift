import SwiftUI

struct MonthlyReceiptPaper: View {
    let snapshot: MonthlyReceiptSnapshot

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image("SpendyLogo")
                    .resizable().scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(.rect(cornerRadius: 7))
                    .accessibilityHidden(true)
                Text("SPENDY EXPENSE REPORT")
                    .font(.caption.monospaced().bold())
                    .tracking(0.8)
                    .multilineTextAlignment(.center)
                Text(snapshot.title.uppercased())
                    .font(.caption2.monospaced())
                    .foregroundStyle(.black.opacity(0.5))
                    .accessibilityIdentifier("monthly-receipt-month")
            }

            perforation

            VStack(spacing: 7) {
                Text("TOTAL SPENT")
                    .font(.caption2.monospaced().weight(.medium))
                    .tracking(1.8)
                    .foregroundStyle(.black.opacity(0.55))
                Text(snapshot.expenses.formattedCurrency(symbol: snapshot.currencySymbol, decimals: 2))
                    .font(.largeTitle.monospaced().bold())
                    .lineLimit(1).minimumScaleFactor(0.35)
                    .accessibilityIdentifier("monthly-receipt-expense-total")
                Text("\(snapshot.transactionCount) recorded transactions")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            perforation

            if snapshot.categories.isEmpty {
                Text("NO EXPENSES LOGGED")
                    .font(.caption.monospaced())
                    .foregroundStyle(.black.opacity(0.5))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(snapshot.categories, id: \.id) { item in
                        MonthlyReceiptPaperRow(label: item.name.uppercased(),
                            value: item.amount.formattedCurrency(symbol: snapshot.currencySymbol, decimals: 2))
                    }
                }
            }

            perforation

            VStack(spacing: 10) {
                MonthlyReceiptPaperRow(label: "MONEY IN",
                    value: snapshot.income.formattedCurrency(symbol: snapshot.currencySymbol, decimals: 2))
                MonthlyReceiptPaperRow(label: "NET BALANCE",
                    value: (snapshot.income - snapshot.expenses).formattedCurrency(symbol: snapshot.currencySymbol, decimals: 2),
                    emphasized: true)
            }

            VStack(spacing: 12) {
                HStack(spacing: 3) {
                    ForEach(0..<36, id: \.self) { index in
                        Rectangle().fill(.black.opacity(index % 3 == 0 ? 0.75 : 0.4))
                            .frame(width: index % 2 == 0 ? 2 : 3, height: 24)
                    }
                }
                .accessibilityHidden(true)
                Text("A LITTLE CLARITY, EVERY MONTH.")
                    .font(.caption2.monospaced())
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black.opacity(0.45))
            }
            .padding(.top, 4)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 22)
        .padding(.top, 28)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.98, green: 0.97, blue: 0.94), in: MonthlyReceiptPaperShape())
        .environment(\.colorScheme, .light)
    }

    private var perforation: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .stroke(.black.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
        }
        .frame(height: 1)
        .accessibilityHidden(true)
    }
}
