//
//  SpendyBudgetLiveActivity.swift
//  SpendyWidgets
//
//  Dynamic Island & Lock Screen Live Activity for Spendy Daily Budget Pacing
//  & Upcoming Subscription Countdown.
//

import ActivityKit
import SwiftUI
import WidgetKit

public struct SpendyBudgetLiveActivity: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: BudgetPacingActivityAttributes.self) { context in
            // MARK: - Lock Screen & Banner Live Activity View
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            // MARK: - Dynamic Island View
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 3.5)
                                .frame(width: 32, height: 32)
                            
                            Circle()
                                .trim(from: 0, to: min(1.0, CGFloat(context.state.pacingPercent)))
                                .stroke(
                                    SpendyHexColor.color(from: context.state.statusColorHex),
                                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyHexColor.color(from: context.state.statusColorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("TODAY'S SPEND")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.6))
                            
                            Text(SpendyWidgetFormat.amount(context.state.spentToday, symbol: context.attributes.currencySymbol, decimals: 0))
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.leading, 8)
                }
                
                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("REMAINING")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.6))
                        
                        Text(SpendyWidgetFormat.amount(max(0, context.state.remainingToday), symbol: context.attributes.currencySymbol, decimals: 0))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(SpendyHexColor.color(from: context.state.statusColorHex))
                    }
                    .padding(.trailing, 8)
                }
                
                // Expanded Center / Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                SpendyHexColor.color(from: context.state.statusColorHex),
                                                SpendyHexColor.color(from: context.state.statusColorHex).opacity(0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * min(1.0, max(0.04, CGFloat(context.state.pacingPercent))), height: 6)
                            }
                        }
                        .frame(height: 6)
                        .padding(.horizontal, 4)
                        
                        // Footer: Status + Next Subscription countdown
                        HStack {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(SpendyHexColor.color(from: context.state.statusColorHex))
                                    .frame(width: 6, height: 6)
                                
                                Text(context.state.statusText)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                            
                            Spacer()
                            
                            if let subTitle = context.state.nextSubscriptionTitle,
                               let subAmount = context.state.nextSubscriptionAmount,
                               let subDays = context.state.nextSubscriptionDueDays {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 10))
                                    Text("\(subTitle) \(SpendyWidgetFormat.amount(subAmount, symbol: context.attributes.currencySymbol, decimals: 0)) in \(subDays)d")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundStyle(Color.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact Leading: Mini circle progress
                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 2.2)
                            .frame(width: 14, height: 14)
                        
                        Circle()
                            .trim(from: 0, to: min(1.0, CGFloat(context.state.pacingPercent)))
                            .stroke(
                                SpendyHexColor.color(from: context.state.statusColorHex),
                                style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 14, height: 14)
                    }
                    
                    Text(SpendyWidgetFormat.compactAmount(context.state.spentToday, symbol: context.attributes.currencySymbol))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }
            } compactTrailing: {
                // Compact Trailing: Remaining amount with status color
                Text(SpendyWidgetFormat.compactAmount(max(0, context.state.remainingToday), symbol: context.attributes.currencySymbol))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyHexColor.color(from: context.state.statusColorHex))
            } minimal: {
                // Minimal Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2.5)
                        .frame(width: 16, height: 16)
                    
                    Circle()
                        .trim(from: 0, to: min(1.0, CGFloat(context.state.pacingPercent)))
                        .stroke(
                            SpendyHexColor.color(from: context.state.statusColorHex),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 16, height: 16)
                }
            }
        }
    }
}

// MARK: - Lock Screen & Banner Live Activity View
private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<BudgetPacingActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header: App branding + Status badge + Last updated
            HStack {
                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(SpendyHexColor.color(from: context.state.statusColorHex).opacity(0.2))
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyHexColor.color(from: context.state.statusColorHex))
                    }
                    
                    Text(context.attributes.budgetCycleName.uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                // Status Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(SpendyHexColor.color(from: context.state.statusColorHex))
                        .frame(width: 6, height: 6)
                    
                    Text(context.state.statusText)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    SpendyHexColor.color(from: context.state.statusColorHex).opacity(0.22),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(SpendyHexColor.color(from: context.state.statusColorHex).opacity(0.4), lineWidth: 0.8)
                }
            }
            
            // Dual Metric Display
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent Today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(SpendyWidgetFormat.amount(context.state.spentToday, symbol: context.attributes.currencySymbol, decimals: 0))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                        
                        Text("/ \(SpendyWidgetFormat.amount(context.state.dailyBudget, symbol: context.attributes.currencySymbol, decimals: 0))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Daily Remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                    
                    Text(SpendyWidgetFormat.amount(max(0, context.state.remainingToday), symbol: context.attributes.currencySymbol, decimals: 0))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(SpendyHexColor.color(from: context.state.statusColorHex))
                }
            }
            
            // Pacing Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    SpendyHexColor.color(from: context.state.statusColorHex),
                                    SpendyHexColor.color(from: context.state.statusColorHex).opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(1.0, max(0.04, CGFloat(context.state.pacingPercent))), height: 8)
                }
            }
            .frame(height: 8)
            
            // Bottom Upcoming Subscription Alert (If Available)
            if let subTitle = context.state.nextSubscriptionTitle,
               let subAmount = context.state.nextSubscriptionAmount,
               let subDays = context.state.nextSubscriptionDueDays {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#FF9500"))
                    
                    Text("Upcoming: **\(subTitle)** (\(SpendyWidgetFormat.amount(subAmount, symbol: context.attributes.currencySymbol, decimals: 2))) in **\(subDays) \(subDays == 1 ? "day" : "days")**")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
    }
}
