//
//  ReceiptPrinterSheet.swift
//  Spendy
//
//  Printable Thermal-Style Monthly Expense Summary with Liquid Glass Controls
//

import SwiftUI

struct ReceiptPrinterSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMonthOffset: Int = 0
    @State private var showShareSheet: Bool = false
    @State private var renderedReceiptImage: UIImage? = nil
    @Namespace private var receiptNamespace
    
    private var targetDate: Date {
        Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
    }
    
    private var monthTitle: String {
        targetDate.formatted(.dateTime.month(.wide).year())
    }
    
    private var monthTransactions: [Transaction] {
        let cal = Calendar.current
        return store.transactions.filter {
            cal.isDate($0.date, equalTo: targetDate, toGranularity: .month) &&
            cal.isDate($0.date, equalTo: targetDate, toGranularity: .year)
        }
    }
    
    private var monthExpense: Double {
        monthTransactions.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
    }
    
    private var monthIncome: Double {
        monthTransactions.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
    }
    
    private var categoryTotals: [(category: Category, total: Double)] {
        var map: [String: Double] = [:]
        for t in monthTransactions where t.type == .expense {
            map[t.categoryId, default: 0] += t.amount
        }
        return map.compactMap { (catId, total) in
            guard let cat = store.categories.first(where: { $0.id == catId }) else { return nil }
            return (category: cat, total: total)
        }.sorted(by: { $0.total > $1.total })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Top Header Bar
                        HStack {
                            GlassCircleButton(
                                icon: "xmark",
                                size: 44,
                                iconSize: 14,
                                foregroundColor: .white,
                                haptic: .selection,
                                accessibilityLabel: "Close",
                                morphID: "closeButton",
                                namespace: receiptNamespace
                            ) {
                                dismiss()
                            }
                            
                            Spacer()
                            
                            Text("Monthly Receipt")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            GlassCircleButton(
                                icon: "square.and.arrow.up",
                                size: 44,
                                iconSize: 15,
                                foregroundColor: .white,
                                haptic: .light,
                                accessibilityLabel: "Share Receipt",
                                morphID: "shareButton",
                                namespace: receiptNamespace
                            ) {
                                exportReceipt()
                            }
                        }
                        .padding(.top, 10)
                        
                        // Month Navigation Pill
                        SpendyGlassEffectContainer(spacing: 16) {
                            HStack(spacing: 16) {
                                Button(action: {
                                    selectedMonthOffset -= 1
                                    HapticsManager.shared.trigger(.light)
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 36, height: 36)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                                
                                Text(monthTitle)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 140)
                                
                                Button(action: {
                                    selectedMonthOffset += 1
                                    HapticsManager.shared.trigger(.light)
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 36, height: 36)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .disabled(selectedMonthOffset >= 0)
                                .opacity(selectedMonthOffset >= 0 ? 0.3 : 1.0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .nativeLiquidGlassCapsule(isInteractive: true)
                            .glassMorphID("monthNavPill", in: receiptNamespace)
                        }
                        
                        // Thermal Receipt Visual Card
                        receiptCardView
                            .shadow(color: Color.black.opacity(0.35), radius: 16, y: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showShareSheet) {
                if let img = renderedReceiptImage {
                    ShareActivityView(activityItems: [img])
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Thermal Receipt Card
    private var receiptCardView: some View {
        VStack(spacing: 14) {
            // Receipt Header
            VStack(spacing: 4) {
                Image("SpendyLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text("SPENDY EXPENSE REPORT")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.black)
                    .tracking(1.0)
                
                Text(monthTitle.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.6))
            }
            .padding(.top, 12)
            
            // Dotted Separator
            dashedLine
            
            // Stats Overview
            VStack(spacing: 6) {
                receiptRow(label: "TOTAL INCOME", value: "+\(monthIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                receiptRow(label: "TOTAL EXPENSES", value: "-\(monthExpense.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                receiptRow(label: "NET BALANCE", value: (monthIncome - monthExpense).formattedCurrency(symbol: store.currencySymbol, decimals: 0), isBold: true)
                receiptRow(label: "TX COUNT", value: "\(monthTransactions.count) items")
            }
            
            dashedLine
            
            // Category Breakdown Table
            if categoryTotals.isEmpty {
                Text("NO EXPENSES LOGGED")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.40))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(categoryTotals, id: \.category.id) { item in
                        receiptRow(
                            label: item.category.label.uppercased(),
                            value: item.total.formattedCurrency(symbol: store.currencySymbol, decimals: 0)
                        )
                    }
                }
            }
            
            dashedLine
            
            // Barcode / Footer Stamp
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    ForEach(0..<28, id: \.self) { i in
                        Rectangle()
                            .fill(Color.black.opacity(i % 3 == 0 ? 0.9 : 0.4))
                            .frame(width: (i % 2 == 0) ? 2 : 4, height: 32)
                    }
                }
                
                Text("THANK YOU FOR USING SPENDY")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(.black.opacity(0.50))
            }
            .padding(.bottom, 12)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "#F5F5F0"))
        }
    }
    
    private var dashedLine: some View {
        Line()
            .stroke(Color.black.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .frame(height: 1)
            .padding(.vertical, 4)
    }
    
    private func receiptRow(label: String, value: String, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: isBold ? 13 : 11, weight: isBold ? .black : .semibold, design: .monospaced))
                .foregroundStyle(.black.opacity(isBold ? 1.0 : 0.70))
            
            Spacer()
            
            Text(value)
                .font(.system(size: isBold ? 13 : 11, weight: isBold ? .black : .bold, design: .monospaced))
                .foregroundStyle(.black)
        }
    }
    
    private func exportReceipt() {
        let renderer = ImageRenderer(content: receiptCardView.frame(width: 320))
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            self.renderedReceiptImage = image
            self.showShareSheet = true
            HapticsManager.shared.trigger(.success)
        }
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
