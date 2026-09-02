//
//  SmartInsightsUnitTests.swift
//  Spendy
//
//  Test runner for Spendy Smart Insights Engine.
//

import Foundation

enum SmartInsightsUnitTests {
    
    private static func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
        if actual != expected {
            fatalError("❌ Assertion Failed [\(file):\(line)]: expected \(expected), got \(actual). \(message)")
        }
    }

    private static func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
        if !condition {
            fatalError("❌ Assertion Failed [\(file):\(line)]: expected true. \(message)")
        }
    }

    public static func runAllTests() {
        print("🧪 Starting Spendy Smart Insights Engine Unit Tests...")

        // 1. Test Fatigue & Exposure Store
        print("\n--- 1. Testing InsightExposureStore ---")
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_exposures_\(UUID().uuidString).json")
        let store = InsightExposureStore(fileURL: tempURL)

        // Fresh candidate shouldn't be suppressed
        assertTrue(!store.shouldSuppress(semanticId: "test_key", isCritical: false), "Fresh candidate should not be suppressed")

        // Record exposure
        let now = Date()
        store.recordExposure(semanticId: "test_key", delta: 15.0, value: 1000.0, now: now)

        // Immediate re-check should be suppressed
        assertTrue(store.shouldSuppress(semanticId: "test_key", isCritical: false, currentDelta: 16.0, currentValue: 1020.0, now: now), "Recent non-material change should be suppressed")

        // Critical alert should NOT be suppressed
        assertTrue(!store.shouldSuppress(semanticId: "test_key", isCritical: true, currentDelta: 16.0, currentValue: 1020.0, now: now), "Critical alert must bypass suppression")

        // Material delta shift (>= 10%) should bypass suppression
        assertTrue(!store.shouldSuppress(semanticId: "test_key", isCritical: false, currentDelta: 28.0, currentValue: 1020.0, now: now), "Material delta shift >= 10% should bypass suppression")

        // Material value shift (>= 20%) should bypass suppression
        assertTrue(!store.shouldSuppress(semanticId: "test_key", isCritical: false, currentDelta: 16.0, currentValue: 1300.0, now: now), "Material value shift >= 20% should bypass suppression")

        print("✅ InsightExposureStore tests passed!")

        // 2. Test Deterministic InsightMessageBuilder
        print("\n--- 2. Testing InsightMessageBuilder ---")
        let sampleCandidate = InsightCandidate(
            id: "sample_cat_surge",
            semanticKey: "cat_surge",
            family: .category,
            kind: .warning,
            surfaceAffinity: [.home, .category(id: "food")],
            confidence: 0.9,
            severity: 0.7,
            evidence: .categoryTrend(categoryId: "food", categoryName: "Dining Out", currentAmount: 4500, baselineAmount: 3000, deltaAmount: 1500, deltaPercent: 50.0)
        )
        let msg = InsightMessageBuilder.buildMessage(for: sampleCandidate, currencySymbol: "₹")
        assertEqual(msg.headline, "Noticeable increase in Dining Out spending.")
        assertEqual(msg.supportingText, "+₹1,500 higher than last month.")
        print("✅ InsightMessageBuilder tests passed!")

        // 3. Test Compound Insight Synthesis
        print("\n--- 3. Testing Compound Insight Message Builder ---")
        let budgetPrimary = InsightCandidate(
            id: "budget_burn",
            semanticKey: "budget_burn_rate",
            family: .budget,
            kind: .warning,
            surfaceAffinity: [.home, .budget],
            confidence: 0.9,
            severity: 0.8,
            evidence: .budgetPacing(limit: 10000, spent: 7000, percentSpent: 70.0, overPacePercent: 20.0, daysToExhaustion: 18, exhaustionDate: nil, safeDailyRemaining: 200.0, daysRemaining: 15)
        )

        let catDriver = InsightCandidate(
            id: "cat_driver_shopping",
            semanticKey: "cat_driver",
            family: .category,
            kind: .explanation,
            surfaceAffinity: [.home, .analytics],
            confidence: 0.88,
            severity: 0.6,
            evidence: .categoryDriver(categoryId: "shopping", categoryName: "Shopping", categoryIncrease: 2500, totalIncrease: 3000, driverSharePercent: 83.3)
        )

        let compoundMsg = InsightMessageBuilder.buildCompoundMessage(primary: budgetPrimary, driver: catDriver, currencySymbol: "₹")
        assertEqual(compoundMsg.headline, "Spending is outpacing your budget timeline.")
        assertEqual(compoundMsg.supportingText, "Shopping is driving most of this month's increase.")
        print("✅ Compound Insight synthesis tests passed!")

        // 4. Test Insufficient Data Moment
        print("\n--- 4. Testing Insufficient Data Factory ---")
        let emptyMoment = InsightMoment.insufficientData(for: .home)
        assertTrue(emptyMoment.isInsufficientData)
        assertEqual(emptyMoment.headline, "Insights")
        assertEqual(emptyMoment.supportingText, "Add more transactions to unlock personalised insights")
        print("✅ Insufficient data canonical factory tests passed!")

        print("\n🎉 ALL TESTS PASSED SUCCESSFULLY! 100% Deterministic Engine Verified.")
    }
}
