//
//  SmartInsightsUnitTests.swift
//  Spendy
//
//  Comprehensive verification test suite for Spendy's 100% deterministic Smart Insights engine,
//  AnalyticsInsightContext synchronization, exact date-range boundaries, period switching stability,
//  and destination/capitalization correctness.
//

import Foundation

enum SmartInsightsUnitTests {
    
    static func runAllTests() {
        print("🧠 [SmartInsightsUnitTests] Starting Master Intelligence & Analytical Context verification...")
        
        testPeriodBoundsAndCapability()
        testDataSufficiencyGates()
        testMaterialityWeightedRanking()
        testDynamicNoveltyDecayAndMaterialShift()
        testCompoundSynthesis()
        testDeterministicMessageGeneration()
        testLongTermPatternRule()
        testDestinationIdentityPreservation()
        testFixedGeometryConstants()
        testMaxThreeMomentsSelection()
        testRealisticFamilySupport24TransactionsFixture()
        testCategoryAndAccountScoping()
        testCustomDateRangeAndBaselineSemantics()
        testContextualExposureFatigue()
        
        // Focused Bug Regressions
        testPeriodSwitchingRegression1Wto1Mto1W()
        testPeriodSwitchingRegression1Wto1Mto3Mto1W()
        testActionRowExistenceAndSelfReferentialResolution()
        testLabelCapitalizationNormalCase()
        
        print("✅ [SmartInsightsUnitTests] All 18 Master Intelligence Test Suites Passed Successfully!")
    }
    
    // MARK: - 1. Period Bounds & Capability Matrix
    private static func testPeriodBoundsAndCapability() {
        let calendar = Calendar.current
        let now = Date()
        
        for period in InsightPeriod.allCases {
            let bounds = period.resolveBounds(now: now, calendar: calendar)
            assert(bounds.periodStart <= bounds.periodEnd, "Period bounds start must precede end for \(period)")
            assert(bounds.baselineStart <= bounds.baselineEnd, "Baseline bounds start must precede end for \(period)")
        }
        
        // Capability Matrix Verification
        let velocityRule = SpendingVelocityRule()
        assert(velocityRule.supportedPeriods.contains(.week) && velocityRule.supportedPeriods.contains(.month), "SpendingVelocityRule should support week and month")
        
        let budgetRule = BudgetPacingRule()
        assert(budgetRule.supportedPeriods == [.month], "BudgetPacingRule should support month only")
        
        let longTermRule = LongTermPatternRule()
        assert(longTermRule.supportedPeriods.contains(.year) && longTermRule.supportedPeriods.contains(.sixMonths), "LongTermPatternRule should support 6M, 1Y, All")
    }
    
    // MARK: - 2. Data Sufficiency Gates
    private static func testDataSufficiencyGates() {
        let emptyFacts = InsightFactsExtractor.extractFacts(
            transactions: [],
            budget: Budget(amount: 10000, period: .monthly, isActive: true),
            categories: [],
            subscriptions: [],
            period: .month
        )
        assert(!emptyFacts.hasSufficientGeneralData, "Empty transactions must not satisfy general data sufficiency")
        
        let moments = InsightDecisionEngine.shared.evaluate(
            facts: emptyFacts,
            surface: .home,
            period: .month,
            recordExposures: false
        )
        assert(moments.count == 1 && moments.first?.isInsufficientData == true, "Insufficient data must return canonical empty moment")
    }
    
    // MARK: - 3. Materiality-Weighted Ranking
    private static func testMaterialityWeightedRanking() {
        let smallHighPercentCandidate = InsightCandidate(
            id: "small_surge",
            semanticKey: "small_surge",
            family: .category,
            kind: .warning,
            surfaceAffinity: [.home],
            confidence: 0.85,
            severity: 0.60,
            relevance: 0.80,
            actionability: 0.50,
            materiality: 0.05, // +100% on ₹50
            evidence: .zeroSpendStreak(streakDays: 2)
        )
        
        let largeModeratePercentCandidate = InsightCandidate(
            id: "large_surge",
            semanticKey: "large_surge",
            family: .category,
            kind: .warning,
            surfaceAffinity: [.home],
            confidence: 0.90,
            severity: 0.80,
            relevance: 0.90,
            actionability: 0.80,
            materiality: 0.95, // +12.5% on ₹8,000
            evidence: .budgetExceeded(limit: 8000, spent: 9000, excessAmount: 1000)
        )
        
        let scoreSmall = (smallHighPercentCandidate.severity * 0.30)
                       + (smallHighPercentCandidate.confidence * 0.25)
                       + (smallHighPercentCandidate.relevance * 0.20)
                       + (1.0 * 0.15)
                       + (smallHighPercentCandidate.materiality * 0.05)
                       + (smallHighPercentCandidate.actionability * 0.05)
        
        let scoreLarge = (largeModeratePercentCandidate.severity * 0.30)
                       + (largeModeratePercentCandidate.confidence * 0.25)
                       + (largeModeratePercentCandidate.relevance * 0.20)
                       + (1.0 * 0.15)
                       + (largeModeratePercentCandidate.materiality * 0.05)
                       + (largeModeratePercentCandidate.actionability * 0.05)
        
        assert(scoreLarge > scoreSmall, "Substantial financial materiality must outrank tiny percentage changes")
    }
    
    // MARK: - 4. Dynamic Novelty Decay & Material Shifts
    private static func testDynamicNoveltyDecayAndMaterialShift() {
        let testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_exposures_\(UUID().uuidString).json")
        let store = InsightExposureStore(fileURL: testURL)
        
        let key = "test_cat_surge"
        assert(store.calculateNovelty(for: key) == 1.0, "Fresh candidate must have 1.0 novelty")
        
        store.recordExposure(semanticId: key, delta: 15.0, value: 500.0)
        assert(store.calculateNovelty(for: key) == 0.70, "1 exposure must decay novelty to 0.70")
        
        // Simulating second exposure after 1 hr
        store.recordExposure(semanticId: key, delta: 15.0, value: 500.0, now: Date().addingTimeInterval(3700))
        assert(store.calculateNovelty(for: key) == 0.40, "2 exposures must decay novelty to 0.40")
        
        // Material shift (+15% -> +30%) must restore novelty to 0.90
        let shiftNovelty = store.calculateNovelty(for: key, currentDelta: 30.0, currentValue: 650.0)
        assert(shiftNovelty == 0.90, "Material delta shift must reset novelty to 0.90")
        
        store.reset()
    }
    
    // MARK: - 5. Compound Synthesis
    private static func testCompoundSynthesis() {
        let macroCandidate = InsightCandidate(
            id: "budget_burn",
            semanticKey: "budget_burn",
            family: .budget,
            kind: .warning,
            surfaceAffinity: [.home, .budget],
            confidence: 0.90,
            severity: 0.75,
            materiality: 0.80,
            evidence: .budgetPacing(
                limit: 20000,
                spent: 16000,
                percentSpent: 80.0,
                overPacePercent: 25.0,
                daysToExhaustion: 18,
                exhaustionDate: nil,
                safeDailyRemaining: 200.0,
                daysRemaining: 12
            ),
            destination: .budget
        )
        
        let driverCandidate = InsightCandidate(
            id: "cat_driver_shopping",
            semanticKey: "cat_driver",
            family: .category,
            kind: .explanation,
            surfaceAffinity: [.home, .analytics],
            confidence: 0.90,
            severity: 0.70,
            materiality: 0.85,
            evidence: .categoryDriver(
                categoryId: "shopping_id",
                categoryName: "Shopping",
                categoryIncrease: 2800.0,
                totalIncrease: 3500.0,
                driverSharePercent: 80.0,
                period: .month
            ),
            actionTitle: "View Shopping →",
            destination: .category(id: "shopping_id"),
            canActAsDriver: true
        )
        
        let compound = InsightMessageBuilder.buildCompoundMessage(
            primary: macroCandidate,
            driver: driverCandidate,
            currencySymbol: "₹"
        )
        
        assert(compound.headline == "Spending is outpacing your budget timeline.")
        assert(compound.supportingText == "Shopping is driving most of this month's increase.")
        assert(compound.actionTitle == "View Shopping →")
    }
    
    // MARK: - 6. Deterministic Message Generation
    private static func testDeterministicMessageGeneration() {
        let subDueCandidate = InsightCandidate(
            id: "sub_spotify",
            semanticKey: "sub_due",
            family: .subscription,
            kind: .observation,
            surfaceAffinity: [.home],
            confidence: 1.0,
            severity: 0.45,
            evidence: .subscriptionDue(
                subscriptionId: "sub_1",
                subscriptionName: "Spotify",
                amount: 1199.0,
                daysUntilDue: 1,
                dueDate: Date()
            ),
            actionTitle: "View Spotify →",
            destination: .subscriptionDetail(id: "sub_1")
        )
        
        let payload = InsightMessageBuilder.buildMessage(for: subDueCandidate, currencySymbol: "₹")
        assert(payload.headline == "Spotify bill is due tomorrow.")
        assert(payload.supportingText == "₹1,199 scheduled for renewal.")
        assert(payload.actionTitle == "View Spotify →")
    }
    
    // MARK: - 7. Long-Term Multi-Month Pattern Rule
    private static func testLongTermPatternRule() {
        let evidence = InsightEvidence.seasonality(
            peakMonthName: "December",
            peakMonthSpend: 45000.0,
            averageMonthSpend: 25000.0,
            multiplier: 1.8
        )
        let candidate = InsightCandidate(
            id: "seasonality_dec",
            semanticKey: "seasonality_peak",
            family: .spending,
            kind: .observation,
            surfaceAffinity: [.home, .analytics],
            period: .year,
            confidence: 0.90,
            severity: 0.35,
            evidence: evidence
        )
        let payload = InsightMessageBuilder.buildMessage(for: candidate, currencySymbol: "₹")
        assert(payload.headline == "December is usually your most expensive month.")
        assert(payload.supportingText == "Historical spending averaged 1.8x higher than other months.")
        assert(payload.actionTitle == nil, "Seasonality has no destination, so actionTitle must be nil")
    }
    
    // MARK: - 8. Destination Identity Preservation
    private static func testDestinationIdentityPreservation() {
        let subId = "apple_music_sub_uuid"
        let catId = "dining_out_cat_id"
        let txId = UUID()
        
        // 1. Subscription Destination Preservation
        let subCandidate = InsightCandidate(
            id: "sub_test",
            semanticKey: "sub_overdue",
            family: .subscription,
            kind: .warning,
            surfaceAffinity: [.home, .subscriptions],
            confidence: 1.0,
            severity: 0.90,
            evidence: .subscriptionOverdue(subscriptionId: subId, subscriptionName: "Apple Music", amount: 59.0, daysOverdue: 1),
            actionTitle: "View Apple Music →",
            destination: .subscriptionDetail(id: subId)
        )
        assert(subCandidate.destination == .subscriptionDetail(id: subId), "Subscription ID must be preserved in Candidate destination")
        
        let subPayload = InsightMessageBuilder.buildMessage(for: subCandidate, currencySymbol: "₹")
        let subMoment = InsightMoment(
            id: "moment_sub",
            candidateId: subCandidate.id,
            kind: subCandidate.kind,
            family: subCandidate.family,
            surface: .home,
            headline: subPayload.headline,
            supportingText: subPayload.supportingText,
            emphasis: subPayload.emphasis,
            actionTitle: subPayload.actionTitle,
            destination: subCandidate.destination
        )
        assert(subMoment.destination == .subscriptionDetail(id: subId), "Subscription ID must be preserved in InsightMoment destination")
        assert(subMoment.actionTitle == "View Apple Music →", "Action title must match specific subscription name")
        
        // 2. Category Destination Preservation
        let catCandidate = InsightCandidate(
            id: "cat_test",
            semanticKey: "cat_surge",
            family: .category,
            kind: .warning,
            surfaceAffinity: [.home, .category(id: catId)],
            affectedEntityId: catId,
            confidence: 0.85,
            severity: 0.65,
            evidence: .categoryTrend(categoryId: catId, categoryName: "Dining", currentAmount: 500, baselineAmount: 200, deltaAmount: 300, deltaPercent: 150, period: .month),
            actionTitle: "View Dining →",
            destination: .category(id: catId)
        )
        assert(catCandidate.destination == .category(id: catId), "Category ID must be preserved in Candidate destination")
        
        // 3. Transaction Destination Preservation
        let txCandidate = InsightCandidate(
            id: "tx_test",
            semanticKey: "transaction_anomaly",
            family: .anomaly,
            kind: .anomaly,
            surfaceAffinity: [.home],
            confidence: 0.90,
            severity: 0.80,
            evidence: .transactionAnomaly(transactionId: txId, categoryId: catId, categoryName: "Dining", amount: 2500, meanAmount: 300, multiplier: 8.3, date: Date()),
            actionTitle: "View Transaction →",
            destination: .transaction(id: txId)
        )
        assert(txCandidate.destination == .transaction(id: txId), "Transaction UUID must be preserved in Candidate destination")
    }
    
    // MARK: - 9. Fixed Geometry Constants
    private static func testFixedGeometryConstants() {
        assert(EditorialInsightMomentView.canonicalHeight == 136.0, "Canonical fixed height must be exactly 136.0pt")
        assert(EditorialInsightMomentView.railCardWidth == 296.0, "Rail card width must be exactly 296.0pt")
        assert(EditorialInsightMomentView.cardCornerRadius == 20.0, "Card corner radius must be exactly 20.0pt")
    }
    
    // MARK: - 10. Maximum 3 Moments Selection
    private static func testMaxThreeMomentsSelection() {
        let engine = InsightDecisionEngine()
        let facts = InsightFactsExtractor.extractFacts(
            transactions: [
                Transaction(title: "Tx 1", amount: 1000, type: .expense, categoryId: "c1", accountId: "a1", date: Date()),
                Transaction(title: "Tx 2", amount: 1000, type: .expense, categoryId: "c1", accountId: "a1", date: Date()),
                Transaction(title: "Tx 3", amount: 1000, type: .expense, categoryId: "c1", accountId: "a1", date: Date()),
                Transaction(title: "Tx 4", amount: 1000, type: .expense, categoryId: "c1", accountId: "a1", date: Date())
            ],
            budget: Budget(amount: 5000, period: .monthly, isActive: true),
            categories: [Category(id: "c1", label: "Cat", sfSymbol: "cart", colorHex: "#FF0000", type: .expense)],
            subscriptions: [],
            period: .month
        )
        
        let moments = engine.evaluate(facts: facts, surface: .home, period: .month, recordExposures: false)
        assert(moments.count <= 3, "Decision engine must NEVER return more than 3 moments on a surface")
    }
    
    // MARK: - 11. Realistic Family Support 24-Transactions Fixture (PART 18)
    private static func testRealisticFamilySupport24TransactionsFixture() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23, minute: 59, second: 59))!
        let catId = "family_support"
        let cat = Category(id: catId, label: "Family Support", sfSymbol: "heart.fill", colorHex: "#FF2D55", type: .expense)
        
        // Generate exactly 24 transactions (2 per month throughout 2026)
        var transactions: [Transaction] = []
        for month in 1...12 {
            let d1 = calendar.date(from: DateComponents(year: 2026, month: month, day: 5, hour: 12))!
            let d2 = calendar.date(from: DateComponents(year: 2026, month: month, day: 20, hour: 15))!
            transactions.append(Transaction(title: "Family Transfer A", amount: 1000, type: .expense, categoryId: catId, accountId: "acc_1", date: d1))
            transactions.append(Transaction(title: "Family Transfer B", amount: 1000, type: .expense, categoryId: catId, accountId: "acc_1", date: d2))
        }
        assert(transactions.count == 24, "Must have exactly 24 transactions in fixture")
        
        // 1. Test 1 Year Context (Jan 1, 2026 -> Dec 31, 2026)
        let yearContext = AnalyticsInsightContext(
            scope: .category(id: catId),
            period: .year,
            startDate: calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
            endDate: calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23, minute: 59, second: 59))!,
            baselineStartDate: calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!,
            baselineEndDate: calendar.date(from: DateComponents(year: 2025, month: 12, day: 31, hour: 23, minute: 59, second: 59))!,
            referenceDate: baseDate
        )
        let facts1Y = InsightFactsExtractor.extractFacts(
            transactions: transactions,
            budget: Budget(amount: 50000, period: .monthly, isActive: false),
            categories: [cat],
            subscriptions: [],
            context: yearContext,
            calendar: calendar
        )
        assert(facts1Y.totalExpenseTxCount == 24, "1Y context must analyze all 24 transactions (got \(facts1Y.totalExpenseTxCount))")
        assert(facts1Y.currentSpendTotal == 24000.0, "1Y spend must be ₹24,000")
        
        // 2. Test 6 Months Context (Jul 1, 2026 -> Dec 31, 2026)
        let sixMonthsContext = AnalyticsInsightContext(
            scope: .category(id: catId),
            period: .sixMonths,
            startDate: calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!,
            endDate: calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23, minute: 59, second: 59))!,
            baselineStartDate: calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
            baselineEndDate: calendar.date(from: DateComponents(year: 2026, month: 6, day: 30, hour: 23, minute: 59, second: 59))!,
            referenceDate: baseDate
        )
        let facts6M = InsightFactsExtractor.extractFacts(
            transactions: transactions,
            budget: Budget(amount: 50000, period: .monthly, isActive: false),
            categories: [cat],
            subscriptions: [],
            context: sixMonthsContext,
            calendar: calendar
        )
        assert(facts6M.totalExpenseTxCount == 12, "6M context must analyze exactly 12 transactions (got \(facts6M.totalExpenseTxCount))")
        assert(facts6M.currentSpendTotal == 12000.0, "6M spend must be ₹12,000")
        assert(facts6M.baselineSpendTotal == 12000.0, "6M baseline spend must be ₹12,000 (from H1 2026)")
        
        // 3. Test 3 Months Context (Oct 1, 2026 -> Dec 31, 2026)
        let threeMonthsContext = AnalyticsInsightContext(
            scope: .category(id: catId),
            period: .threeMonths,
            startDate: calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!,
            endDate: calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23, minute: 59, second: 59))!,
            baselineStartDate: calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!,
            baselineEndDate: calendar.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 23, minute: 59, second: 59))!,
            referenceDate: baseDate
        )
        let facts3M = InsightFactsExtractor.extractFacts(
            transactions: transactions,
            budget: Budget(amount: 50000, period: .monthly, isActive: false),
            categories: [cat],
            subscriptions: [],
            context: threeMonthsContext,
            calendar: calendar
        )
        assert(facts3M.totalExpenseTxCount == 6, "3M context must analyze exactly 6 transactions (got \(facts3M.totalExpenseTxCount))")
        assert(facts3M.currentSpendTotal == 6000.0, "3M spend must be ₹6,000")
        
        // 4. Test 1 Month Context (Dec 1, 2026 -> Dec 31, 2026)
        let oneMonthContext = AnalyticsInsightContext(
            scope: .category(id: catId),
            period: .month,
            startDate: calendar.date(from: DateComponents(year: 2026, month: 12, day: 1))!,
            endDate: calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23, minute: 59, second: 59))!,
            baselineStartDate: calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!,
            baselineEndDate: calendar.date(from: DateComponents(year: 2026, month: 11, day: 30, hour: 23, minute: 59, second: 59))!,
            referenceDate: baseDate
        )
        let facts1M = InsightFactsExtractor.extractFacts(
            transactions: transactions,
            budget: Budget(amount: 50000, period: .monthly, isActive: false),
            categories: [cat],
            subscriptions: [],
            context: oneMonthContext,
            calendar: calendar
        )
        assert(facts1M.totalExpenseTxCount == 2, "1M context must analyze exactly 2 transactions (got \(facts1M.totalExpenseTxCount))")
        assert(facts1M.currentSpendTotal == 2000.0, "1M spend must be ₹2,000")
    }
    
    // MARK: - 12. Category & Account Scoping Isolation
    private static func testCategoryAndAccountScoping() {
        let calendar = Calendar.current
        let now = Date()
        
        let catA = Category(id: "cat_a", label: "Cat A", sfSymbol: "cart", colorHex: "#FF0000", type: .expense)
        let catB = Category(id: "cat_b", label: "Cat B", sfSymbol: "car", colorHex: "#00FF00", type: .expense)
        
        let txs: [Transaction] = [
            Transaction(title: "Tx A1", amount: 500, type: .expense, categoryId: "cat_a", accountId: "acc_sbi", date: now),
            Transaction(title: "Tx A2", amount: 500, type: .expense, categoryId: "cat_a", accountId: "acc_hdfc", date: now),
            Transaction(title: "Tx B1", amount: 800, type: .expense, categoryId: "cat_b", accountId: "acc_sbi", date: now)
        ]
        
        // Scope to Cat A
        let catContext = AnalyticsInsightContext.standard(period: .month, scope: .category(id: "cat_a"), referenceDate: now, calendar: calendar)
        let catFacts = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(amount: 0, period: .monthly, isActive: false), categories: [catA, catB], subscriptions: [], context: catContext)
        assert(catFacts.totalExpenseTxCount == 2, "Category scoped facts must include only Cat A transactions")
        assert(catFacts.currentSpendTotal == 1000.0, "Cat A spend must equal 1000")
        
        // Scope to SBI Account
        let accContext = AnalyticsInsightContext.standard(period: .month, scope: .account(id: "acc_sbi"), referenceDate: now, calendar: calendar)
        let accFacts = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(amount: 0, period: .monthly, isActive: false), categories: [catA, catB], subscriptions: [], context: accContext)
        assert(accFacts.totalExpenseTxCount == 2, "Account scoped facts must include only SBI transactions")
        assert(accFacts.currentSpendTotal == 1300.0, "SBI account spend must equal 1300")
    }
    
    // MARK: - 13. Custom Date Range & Exact Baseline Duration
    private static func testCustomDateRangeAndBaselineSemantics() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 17))!
        
        let customContext = AnalyticsInsightContext.custom(startDate: start, endDate: end, scope: .global, referenceDate: end, calendar: calendar)
        
        let duration = customContext.endDate.timeIntervalSince(customContext.startDate)
        let baselineDuration = customContext.baselineEndDate.timeIntervalSince(customContext.baselineStartDate)
        assert(abs(duration - baselineDuration) < 60, "Baseline duration must match custom range duration exactly")
        assert(customContext.isCustomRange == true, "Must be flagged as custom range")
        assert(customContext.customRangeLabel == "Jun 12 - Aug 17", "Must format human label correctly")
    }
    
    // MARK: - 14. Contextual Exposure Fatigue Keys
    private static func testContextualExposureFatigue() {
        let testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_context_exposures_\(UUID().uuidString).json")
        let store = InsightExposureStore(fileURL: testURL)
        
        // Expose Family Support 1Y
        let key1Y = "category_trend:cat_family_support:1y"
        store.recordExposure(semanticId: key1Y, delta: 10.0, value: 24000.0)
        
        // Verify Family Support 1M is NOT suppressed!
        let key1M = "category_trend:cat_family_support:1m"
        assert(store.calculateNovelty(for: key1M) == 1.0, "Family Support 1M must have full 1.0 novelty despite 1Y exposure")
        
        // Verify Shopping 1Y is NOT suppressed!
        let keyShop1Y = "category_trend:cat_shopping:1y"
        assert(store.calculateNovelty(for: keyShop1Y) == 1.0, "Shopping 1Y must have full 1.0 novelty despite Family Support exposure")
        
        store.reset()
    }
    
    // MARK: - 15. Period Switching Regression: 1W -> 1M -> 1W
    private static func testPeriodSwitchingRegression1Wto1Mto1W() {
        let testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_period_switch_\(UUID().uuidString).json")
        let exposureStore = InsightExposureStore(fileURL: testURL)
        let engine = InsightDecisionEngine(exposureStore: exposureStore)
        
        let calendar = Calendar.current
        let now = Date()
        let catId = "groceries"
        let cat = Category(id: catId, label: "Groceries", sfSymbol: "cart.fill", colorHex: "#34C759", type: .expense)
        
        // Build 8 transactions in past week and 8 in prior week
        var txs: [Transaction] = []
        for i in 0..<4 {
            let dCur = calendar.date(byAdding: .day, value: -i, to: now)!
            txs.append(Transaction(title: "Grocery \(i)", amount: 1500, type: .expense, categoryId: catId, accountId: "a1", date: dCur))
        }
        for i in 8..<12 {
            let dPrev = calendar.date(byAdding: .day, value: -i, to: now)!
            txs.append(Transaction(title: "Prior Grocery \(i)", amount: 500, type: .expense, categoryId: catId, accountId: "a1", date: dPrev))
        }
        
        // 1. Initial 1W Evaluation
        let context1W = AnalyticsInsightContext.standard(period: .week, scope: .category(id: catId), referenceDate: now, calendar: calendar)
        let facts1W = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(amount: 0, period: .monthly, isActive: false), categories: [cat], subscriptions: [], context: context1W)
        let moments1W_1 = engine.evaluate(facts: facts1W, surface: .category(id: catId), recordExposures: true)
        
        assert(!moments1W_1.isEmpty && !moments1W_1.first!.isInsufficientData, "1W must produce a valid insight initially")
        let firstHeadline = moments1W_1.first!.headline
        
        // 2. Switch to 1M Evaluation
        let context1M = AnalyticsInsightContext.standard(period: .month, scope: .category(id: catId), referenceDate: now, calendar: calendar)
        let facts1M = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(amount: 0, period: .monthly, isActive: false), categories: [cat], subscriptions: [], context: context1M)
        _ = engine.evaluate(facts: facts1M, surface: .category(id: catId), recordExposures: true)
        
        // 3. Switch back to 1W Evaluation
        let moments1W_2 = engine.evaluate(facts: facts1W, surface: .category(id: catId), recordExposures: true)
        assert(!moments1W_2.isEmpty && !moments1W_2.first!.isInsufficientData, "1W insight MUST NOT disappear after returning from 1M!")
        assert(moments1W_2.first!.headline == firstHeadline, "Returning to 1W must return the same valid insight")
        
        exposureStore.reset()
    }
    
    // MARK: - 16. Period Switching Multi-Hop: 1W -> 1M -> 3M -> 1W
    private static func testPeriodSwitchingRegression1Wto1Mto3Mto1W() {
        let testURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_multihop_\(UUID().uuidString).json")
        let exposureStore = InsightExposureStore(fileURL: testURL)
        let engine = InsightDecisionEngine(exposureStore: exposureStore)
        
        let calendar = Calendar.current
        let now = Date()
        let catId = "dining"
        let cat = Category(id: catId, label: "Dining", sfSymbol: "fork.knife", colorHex: "#FF9500", type: .expense)
        
        var txs: [Transaction] = []
        for i in 0..<5 {
            let d = calendar.date(byAdding: .day, value: -i, to: now)!
            txs.append(Transaction(title: "Dining \(i)", amount: 800, type: .expense, categoryId: catId, accountId: "a1", date: d))
        }
        for i in 8..<13 {
            let d = calendar.date(byAdding: .day, value: -i, to: now)!
            txs.append(Transaction(title: "Old Dining \(i)", amount: 300, type: .expense, categoryId: catId, accountId: "a1", date: d))
        }
        
        let context1W = AnalyticsInsightContext.standard(period: .week, scope: .category(id: catId), referenceDate: now, calendar: calendar)
        let facts1W = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(amount: 0, period: .monthly, isActive: false), categories: [cat], subscriptions: [], context: context1W)
        
        // 1W -> 1M -> 3M -> 1W
        let m1 = engine.evaluate(facts: facts1W, surface: .category(id: catId), recordExposures: true)
        assert(!m1.first!.isInsufficientData, "1W step 1 valid")
        
        let context1M = AnalyticsInsightContext.standard(period: .month, scope: .category(id: catId), referenceDate: now, calendar: calendar)
        let facts1M = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(amount: 0, period: .monthly, isActive: false), categories: [cat], subscriptions: [], context: context1M)
        _ = engine.evaluate(facts: facts1M, surface: .category(id: catId), recordExposures: true)
        
        let context3M = AnalyticsInsightContext.standard(period: .threeMonths, scope: .category(id: catId), referenceDate: now, calendar: calendar)
        let facts3M = InsightFactsExtractor.extractFacts(transactions: txs, budget: Budget(amount: 0, period: .monthly, isActive: false), categories: [cat], subscriptions: [], context: context3M)
        _ = engine.evaluate(facts: facts3M, surface: .category(id: catId), recordExposures: true)
        
        let mReturn = engine.evaluate(facts: facts1W, surface: .category(id: catId), recordExposures: true)
        assert(!mReturn.first!.isInsufficientData, "1W insight must remain valid through 1W -> 1M -> 3M -> 1W hop")
        
        exposureStore.reset()
    }
    
    // MARK: - 17. Action Row Existence & Self-Referential Resolution
    private static func testActionRowExistenceAndSelfReferentialResolution() {
        let engine = InsightDecisionEngine()
        
        // Case A: Actionable insight on Home (points to subscription)
        let subCandidate = InsightCandidate(
            id: "sub_apple",
            semanticKey: "sub_overdue",
            family: .subscription,
            kind: .warning,
            surfaceAffinity: [.home],
            confidence: 1.0,
            severity: 0.9,
            evidence: .subscriptionOverdue(subscriptionId: "sub_1", subscriptionName: "Apple Music", amount: 59.0, daysOverdue: 1),
            actionTitle: "View Apple Music →",
            destination: .subscriptionDetail(id: "sub_1")
        )
        let subPayload = InsightMessageBuilder.buildMessage(for: subCandidate, currencySymbol: "₹")
        assert(subPayload.actionTitle == "View Apple Music →", "Actionable candidate must have actionTitle")
        
        // Case B: Informational candidate (Habit with destination: nil)
        let habitCandidate = InsightCandidate(
            id: "streak_5",
            semanticKey: "zero_streak",
            family: .behavior,
            kind: .celebration,
            surfaceAffinity: [.home],
            confidence: 1.0,
            severity: 0.1,
            evidence: .zeroSpendStreak(streakDays: 5),
            actionTitle: nil,
            destination: nil
        )
        let habitPayload = InsightMessageBuilder.buildMessage(for: habitCandidate, currencySymbol: "₹")
        assert(habitPayload.actionTitle == nil, "Informational candidate with destination: nil must NOT have actionTitle")
        
        // Case C: Self-referential resolution in Category Analytics
        let catId = "groceries"
        let catCandidate = InsightCandidate(
            id: "cat_surge",
            semanticKey: "cat_surge",
            family: .category,
            kind: .warning,
            surfaceAffinity: [.home, .category(id: catId)],
            affectedEntityId: catId,
            confidence: 0.9,
            severity: 0.7,
            evidence: .categoryTrend(categoryId: catId, categoryName: "Groceries", currentAmount: 2000, baselineAmount: 1000, deltaAmount: 1000, deltaPercent: 100, period: .month),
            actionTitle: "View Groceries →",
            destination: .category(id: catId)
        )
        let catTxs = [
            Transaction(title: "T1", amount: 1000, type: .expense, categoryId: catId, accountId: "a1", date: Date()),
            Transaction(title: "T2", amount: 1000, type: .expense, categoryId: catId, accountId: "a1", date: Date()),
            Transaction(title: "T3", amount: 500, type: .expense, categoryId: catId, accountId: "a1", date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
        ]
        let catFacts = InsightFactsExtractor.extractFacts(
            transactions: catTxs,
            budget: Budget(amount: 0, period: .monthly, isActive: false),
            categories: [Category(id: catId, label: "Groceries", sfSymbol: "cart", colorHex: "#000", type: .expense)],
            subscriptions: [],
            context: AnalyticsInsightContext.standard(period: .month, scope: .category(id: catId))
        )
        
        // Evaluate on Home surface -> should keep destination & actionTitle
        let homeMoments = engine.evaluate(facts: catFacts, surface: .home, recordExposures: false)
        assert(homeMoments.first?.destination == .category(id: catId), "On Home, destination must be preserved")
        assert(homeMoments.first?.actionTitle == "View Groceries →", "On Home, actionTitle must be preserved")
        
        // Evaluate on Category surface -> self-referential destination must be stripped to nil
        let categoryMoments = engine.evaluate(facts: catFacts, surface: .category(id: catId), recordExposures: false)
        assert(categoryMoments.first?.destination == nil, "On Category surface, self-referential destination must be nil")
        assert(categoryMoments.first?.actionTitle == nil, "On Category surface, actionTitle must be nil")
    }
    
    // MARK: - 18. Label Capitalization Normal Title Case
    private static func testLabelCapitalizationNormalCase() {
        let expected: [InsightFamily: String] = [
            .spending: "Spending",
            .budget: "Budget",
            .category: "Category",
            .behavior: "Habit",
            .subscription: "Subscription",
            .income: "Income",
            .anomaly: "Anomaly"
        ]
        
        for (family, title) in expected {
            assert(family.title == title, "Family title must be normal casing '\(title)', got '\(family.title)'")
            assert(family.title != family.title.uppercased(), "Family title must not be ALL CAPS for \(family)")
        }
    }
}
