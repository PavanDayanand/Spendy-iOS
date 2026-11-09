import SwiftUI

struct CustomCalendarDrawer: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date = Date()
    @State private var isPickingMonthYear: Bool = false
    
    private let calendar = Calendar.current
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    private let monthSymbols = Calendar.current.shortMonthSymbols
    
    private var monthYearString: String {
        SpendyDateFormatterCache.monthYear.string(from: displayedMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let _ = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        let numberOfDays = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Clean Custom Header
                HStack {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 14,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .selection
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text(calendar.isDateInToday(selectedDate) ? "Today" : formattedDateTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedDate = Date()
                        displayedMonth = Date()
                        HapticsManager.shared.trigger(.selection)
                        dismiss()
                    }) {
                        Text("Today")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .nativeLiquidGlassCapsule(isInteractive: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isPickingMonthYear.toggle()
                        }
                        HapticsManager.shared.trigger(.selection)
                    } label: {
                        HStack(spacing: 6) {
                            Text(isPickingMonthYear ? displayedYearTitle : monthYearString)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                            
                            Image(systemName: isPickingMonthYear ? "chevron.down" : "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPickingMonthYear ? "Choose year and month" : "Choose month")
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            shiftDisplayed(by: isPickingMonthYear ? -1 : -1, unit: isPickingMonthYear ? .year : .month)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            shiftDisplayed(by: 1, unit: isPickingMonthYear ? .year : .month)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)
                
                if isPickingMonthYear {
                    monthYearPicker
                } else {
                    weekdayHeader
                    daysGrid
                }
                
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.68)])
        .presentationDragIndicator(.visible)
        .onAppear {
            displayedMonth = selectedDate
        }
    }
    
    private var formattedDateTitle: String {
        SpendyDateFormatterCache.dayMonth.string(from: selectedDate)
    }
    
    private var displayedYearTitle: String {
        String(calendar.component(.year, from: displayedMonth))
    }
    
    private var displayedYear: Int {
        calendar.component(.year, from: displayedMonth)
    }
    
    private var displayedMonthIndex: Int {
        calendar.component(.month, from: displayedMonth)
    }
    
    private func shiftDisplayed(by value: Int, unit: Calendar.Component) {
        if let next = calendar.date(byAdding: unit, value: value, to: displayedMonth) {
            displayedMonth = next
        }
        HapticsManager.shared.trigger(.light)
    }
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
    }
    
    private var daysGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, dayDate in
                if let day = dayDate {
                    let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                    let dayNumber = calendar.component(.day, from: day)
                    
                    Button {
                        selectedDate = day
                        HapticsManager.shared.trigger(.selection)
                        dismiss()
                    } label: {
                        VStack(spacing: 2) {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(SpendyColors.elevatedControlFill)
                                        .frame(width: 38, height: 38)
                                }
                                
                                Text("\(dayNumber)")
                                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                            }
                            .frame(width: 44, height: 44)
                            
                            if isSelected {
                                Circle()
                                    .fill(SpendyColors.elevatedControlFill)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 14)
    }
    
    private var monthYearPicker: some View {
        VStack(spacing: 18) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(1...12, id: \.self) { month in
                    let isSelected = month == displayedMonthIndex
                    Button {
                        selectMonth(month)
                    } label: {
                        Text(monthSymbols[month - 1])
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background {
                                if isSelected {
                                    Capsule(style: .continuous)
                                        .fill(SpendyColors.elevatedControlFill)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(monthSymbols[month - 1])
                }
            }
            .padding(.horizontal, 18)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(yearRange, id: \.self) { year in
                            let isSelected = year == displayedYear
                            Button {
                                selectYear(year)
                            } label: {
                                Text(String(year))
                                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                                    .padding(.horizontal, 16)
                                    .frame(height: 40)
                                    .background {
                                        Capsule(style: .continuous)
                                            .fill(isSelected ? SpendyColors.elevatedControlFill : SpendyColors.cardBackgroundSecondary)
                                    }
                            }
                            .buttonStyle(.plain)
                            .id(year)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    proxy.scrollTo(displayedYear, anchor: .center)
                }
                .onChange(of: displayedYear) { _, year in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(year, anchor: .center)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 15)...(current + 2))
    }
    
    private func selectMonth(_ month: Int) {
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.month = month
        if let next = calendar.date(from: components) {
            displayedMonth = next
        }
        HapticsManager.shared.trigger(.selection)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isPickingMonthYear = false
        }
    }
    
    private func selectYear(_ year: Int) {
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.year = year
        if let next = calendar.date(from: components) {
            displayedMonth = next
        }
        HapticsManager.shared.trigger(.selection)
    }
}

