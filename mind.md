# Spendy App - Context & Progress (mind.md)

This document captures the current context, recent design decisions, and implemented features for the Spendy iOS app. Feed this to the new chat window so the next agent understands exactly what was done and what the current state is.

## 📱 Project Overview
*   **App:** Spendy (iOS Expense/Finance Tracker)
*   **Tech Stack:** SwiftUI, Swift, SwiftUI.Charts
*   **Key Files Modified:**
    *   `Spendy/Views/Analytics/AccountAnalyticsSheet.swift`
    *   `Spendy/Views/Analytics/CategoryAnalyticsSheet.swift`

## ✅ What Was Recently Completed

### 1. Index Selector (Chart Periods)
*   **Removed "All Time":** The `.all` case was completely removed from the `ChartPeriod` enum and the UI. The period selector now only shows `1w`, `1m`, `3m`, `6m`, and `1y`.
*   **1-Year Axis Labels:** Fixed an issue where the 1-year chart (`1y`) crammed 12 months of overlapping labels on the X-axis. It is now hardcoded to `desiredCount: 6` so it cleanly shows 6 evenly spaced months (e.g., Jan, Mar, May, Jul, Sep, Nov).

### 2. Predictive Analytics & Chart Rendering
*   **Threshold:** The predictive insights engine only kicks in and shows predictions if an account or category has **5 or more transactions**; otherwise, it only shows actual data.
*   **Styling (Apple/React Expense App Style):** 
    *   *Removed* the ugly blue dashed predictive curve (`LineMark`).
    *   *Replaced* the forecast with simple, clean **white dotted points** (`PointMark` with `Color.white.opacity(0.35)`). 
    *   Added a distinct "Today" endpoint marker (a larger dot with a white center and theme-colored border) to clearly separate actual data from future predictions.
*   **Y-Axis Scaling:** Chart structures were fixed so that empty future months do not unnecessarily pull the chart area down to `0`.

### 3. Stability & Builds
*   Fixed previous Swift compilation errors relating to invalid `Calendar` component extractions (like `startOfMonth` / `startOfYear`) and `DateFormatter` scope.
*   The project successfully builds using `xcodebuild` (tested against `iPhone 17` simulator) with no warnings or errors related to these analytics sheets.

## 🎯 Current Design Directives to Maintain
*   **Premium iOS Aesthetics:** Follow Apple's design guidelines (`/apple-design`). The user hates "cheap" looking UI. Avoid clunky text, heavy lines, or cluttered data.
*   **Predictive Charts:** Keep the predictive points strictly as **dots**, no lines.
*   **Less is More:** Ensure the UI feels spacious. Don't crowd the charts with too many axis markers (like the 12-month overlapping issue).

---
*Note to New Agent: Review the `CategoryAnalyticsSheet.swift` and `AccountAnalyticsSheet.swift` to see the charting implementations before making further UI tweaks.*
