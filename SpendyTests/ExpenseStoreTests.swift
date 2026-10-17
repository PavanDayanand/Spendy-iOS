import XCTest
@testable import Spendy

final class ExpenseStoreTests: XCTestCase {
    @MainActor private func temporaryStore() throws -> (ExpenseStore, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("store.json")
        return (ExpenseStore(storageURL: url, startsServices: false), url)
    }

    @MainActor func testTransfersIgnoreStaleExpenseCategoryAndPreserveBalances() throws {
        let (store, url) = try temporaryStore()
        store.accounts = [
            Account(id: "bank", label: "Main Bank", openingBalance: 1000, type: .bank),
            Account(id: "savings", label: "Savings Bank", openingBalance: 500, type: .bank),
            Account(id: "cash", label: "Cash", type: .cash)
        ]
        let legacy = Transaction(title: "Groceries", amount: 100, type: .transfer,
            categoryId: "groceries", accountId: "bank", toAccountId: "savings")
        XCTAssertEqual(store.displayTitle(for: legacy), "Transfer")
        XCTAssertEqual(store.displayCategory(for: legacy).label, "Bank to bank")
        XCTAssertEqual(store.displayCategory(for: legacy).sfSymbol, SFIcons.transfer)
        XCTAssertEqual(store.transferAccountRoute(for: legacy), "Main Bank → Savings Bank")
        store.addTransaction(legacy)
        XCTAssertEqual(store.transactions[0].categoryId, "")
        XCTAssertEqual(store.transactions[0].title, "Transfer")
        XCTAssertEqual(store.totalBalance, 1500)
        XCTAssertEqual(store.balance(for: "bank"), 900)
        XCTAssertEqual(store.balance(for: "savings"), 600)
        var edited = store.transactions[0]
        edited.categoryId = "groceries"
        edited.notes = "Move spare cash"
        edited.title = "Move spare cash"
        edited.toAccountId = "cash"
        store.updateTransaction(edited)
        XCTAssertEqual(store.transactions[0].categoryId, "")
        XCTAssertEqual(store.displayTitle(for: store.transactions[0]), "Move spare cash")
        XCTAssertEqual(store.displayCategory(for: store.transactions[0]).label, "Bank to cash")
        store.flushPendingSave()
        let reloaded = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertEqual(reloaded.transactions[0].categoryId, "")
        XCTAssertEqual(reloaded.totalBalance, 1500)
        let expense = Transaction(title: "Groceries", amount: 10, categoryId: "groceries", accountId: "bank")
        XCTAssertEqual(store.displayCategory(for: expense).label, "Groceries")
        XCTAssertEqual(store.displayTitle(for: expense), "Groceries")
    }

    @MainActor func testAngolanKwanzaUsesSymbolForNewAndSavedCurrency() throws {
        XCTAssertEqual(CurrencyInfo.symbol(for: "AOA"), "Kz")
        let (store, url) = try temporaryStore()
        store.currencyCode = "AOA"
        store.currencySymbol = "AOA" // Symbol stored by older currency picker versions.
        store.flushPendingSave()

        let reloaded = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertEqual(reloaded.currencyCode, "AOA")
        XCTAssertEqual(reloaded.currencySymbol, "Kz")
        reloaded.updateCurrency(symbol: "AOA", code: "AOA")
        XCTAssertEqual(reloaded.currencySymbol, "Kz")
    }

    @MainActor func testBackupWithRetiredBackgroundColorsStillImports() throws {
        let (source, _) = try temporaryStore()
        source.appearanceMode = .light
        source.isGradientBackgroundEnabled = false
        source.userName = "Legacy user"
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(source.exportJSONData())) as? [String: Any])
        object["darkBackgroundHex"] = "#0033FF"
        object["lightBackgroundHex"] = "#0033FF"
        let (destination, _) = try temporaryStore()
        XCTAssertTrue(destination.importJSONData(data: try JSONSerialization.data(withJSONObject: object)))
        XCTAssertEqual(destination.userName, "Legacy user")
        XCTAssertEqual(destination.appearanceMode, .light)
        XCTAssertFalse(destination.isGradientBackgroundEnabled)
        let exported = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(destination.exportJSONData())) as? [String: Any])
        XCTAssertNil(exported["darkBackgroundHex"])
        XCTAssertNil(exported["lightBackgroundHex"])
    }

    @MainActor func testTransactionEditDeleteAndTransferConserveBalances() throws {
        let (store, _) = try temporaryStore()
        store.accounts = [Account(id: "cash", label: "Cash", openingBalance: 1000), Account(id: "bank", label: "Bank", openingBalance: 500)]
        let expense = Transaction(title: "Food", amount: 25, categoryId: "groceries", accountId: "cash")
        store.addTransaction(expense)
        store.addTransaction(Transaction(title: "Salary", amount: 100, type: .income, categoryId: "salary", accountId: "bank"))
        store.addTransaction(Transaction(title: "Move", amount: 200, type: .transfer, categoryId: "", accountId: "cash", toAccountId: "bank"))
        XCTAssertEqual(store.balance(for: "cash"), 775)
        XCTAssertEqual(store.balance(for: "bank"), 800)
        XCTAssertEqual(store.totalBalance, 1575)
        var edited = expense; edited.amount = 50
        store.updateTransaction(edited)
        XCTAssertEqual(store.totalBalance, 1550)
        store.deleteTransaction(id: expense.id)
        XCTAssertEqual(store.totalBalance, 1600)
        store.flushPendingSave()
    }

    @MainActor func testFlushAndRelaunchKeepLatestSnapshot() throws {
        let (store, url) = try temporaryStore()
        for value in 0..<100 { store.userName = "User \(value)"; store.flushPendingSave() }
        XCTAssertNil(store.persistenceError)
        let reloaded = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertEqual(reloaded.userName, "User 99")
        XCTAssertNil(reloaded.loadError)
    }

    @MainActor func testUnreadablePrimaryIsNeverReplacedByDefaults() throws {
        let (_, url) = try temporaryStore()
        let corrupt = Data("broken financial data".utf8)
        try corrupt.write(to: url)
        let store = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertNotNil(store.loadError)
        store.userName = "Must not overwrite"
        store.flushPendingSave()
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }

    @MainActor func testBackupRecoveryPreservesUnreadableOriginal() throws {
        let (store, url) = try temporaryStore()
        store.userName = "Recover me"; store.flushPendingSave()
        store.userName = "Latest"; store.flushPendingSave()
        let corrupt = Data("unreadable".utf8); try corrupt.write(to: url)
        let recovered = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertNotNil(recovered.loadError)
        recovered.restoreRecoveryBackup()
        XCTAssertNil(recovered.loadError)
        XCTAssertEqual(recovered.userName, "Recover me")
        let files = try FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil)
        let preserved = try XCTUnwrap(files.first { $0.lastPathComponent.contains("unreadable-") })
        XCTAssertEqual(try Data(contentsOf: preserved), corrupt)
    }

    @MainActor func testWriteFailureIsVisibleAndRetrySucceeds() throws {
        let (store, url) = try temporaryStore()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        store.flushPendingSave()
        XCTAssertNotNil(store.persistenceError)
        try FileManager.default.removeItem(at: url)
        store.flushPendingSave()
        XCTAssertNil(store.persistenceError)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    @MainActor func testImportRoundTripAndInvalidImportsLeaveDataUntouched() throws {
        let (source, _) = try temporaryStore()
        source.addTransaction(Transaction(title: "Dinner", amount: 42.5, categoryId: "groceries", accountId: "cash", date: Date(timeIntervalSince1970: 1_700_000_000)))
        let data = try XCTUnwrap(source.exportJSONData())
        let (destination, _) = try temporaryStore()
        XCTAssertTrue(destination.importJSONData(data: data))
        XCTAssertEqual(destination.transactions, source.transactions)
        XCTAssertFalse(destination.importJSONData(data: Data("{}".utf8)))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var transactions = try XCTUnwrap(object["transactions"] as? [[String: Any]])
        transactions[0]["date"] = "not a date"; object["transactions"] = transactions
        XCTAssertFalse(destination.importJSONData(data: try JSONSerialization.data(withJSONObject: object)))
        transactions[0]["date"] = "2026-10-10T00:00:00Z"
        transactions[0]["accountId"] = "missing"; object["transactions"] = transactions
        XCTAssertFalse(destination.importJSONData(data: try JSONSerialization.data(withJSONObject: object)))
        XCTAssertEqual(destination.transactions, source.transactions)
        source.flushPendingSave(); destination.flushPendingSave()
    }

    @MainActor func testSubscriptionPaymentLogsExpenseAndAdvancesEachCycle() throws {
        let (store, _) = try temporaryStore()
        let calendar = Calendar.current
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31)))
        for cycle in BillingCycle.allCases {
            let subscription = Subscription(name: "Service", amount: 10, cycle: cycle, nextBillingDate: date, isTrial: true)
            store.addSubscription(subscription)
            store.markSubscriptionAsPaid(id: subscription.id)
            let paid = try XCTUnwrap(store.subscriptions.first { $0.id == subscription.id })
            let expected = calendar.date(byAdding: cycle == .weekly ? .day : cycle == .monthly ? .month : .year, value: cycle == .weekly ? 7 : 1, to: date)
            XCTAssertEqual(paid.nextBillingDate, expected)
            XCTAssertFalse(paid.isTrial)
        }
        XCTAssertEqual(store.transactions.count, BillingCycle.allCases.count)
        XCTAssertEqual(store.balance(for: "bank"), -30)
        store.flushPendingSave()
    }
    @MainActor func testMonthlyAndWeeklyBudgetBoundaries() throws {
        let (store, _) = try temporaryStore()
        let calendar = Calendar.current
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 5)))
        store.setBudget(amount: 1000, period: .monthly, startDay: 10)
        XCTAssertEqual(calendar.component(.month, from: store.budgetCycleStart(for: date)), 12)
        XCTAssertEqual(calendar.component(.year, from: store.budgetCycleStart(for: date)), 2025)
        XCTAssertEqual(calendar.component(.day, from: store.budgetCycleEnd(for: date)), 10)
        store.setBudget(amount: 100, period: .weekly, startDay: 2)
        XCTAssertEqual(calendar.component(.weekday, from: store.budgetCycleStart(for: date)), 2)
        XCTAssertEqual(calendar.dateComponents([.day], from: store.budgetCycleStart(for: date), to: store.budgetCycleEnd(for: date)).day, 7)
        store.flushPendingSave()
    }

    @MainActor func testInsightsRegressions() { SmartInsightsUnitTests.runAllTests() }

    func testQueuedWritesCannotOverwriteLatestFlush() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("store.json")
        let writer = LocalStoreWriter()
        for index in 0..<100 { writer.enqueue(Data("\(index)".utf8), to: url) { _ in } }
        XCTAssertNil(writer.flush(Data("latest".utf8), to: url))
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "latest")
        XCTAssertEqual(try String(contentsOf: url.appendingPathExtension("backup"), encoding: .utf8), "99")
    }

    @MainActor func testLargeLedgerBalancePerformance() {
        let accounts = Account.defaultAccounts
        let transactions = (0..<10_000).map { _ in Transaction(title: "Expense", amount: 1, categoryId: "groceries", accountId: "cash") }
        measure {
            XCTAssertEqual(ExpenseStore.calculateAccountBalances(accounts: accounts, transactions: transactions)["cash"], -10_000)
        }
    }

    @MainActor func testEraseAlsoRemovesRecoveryCopies() throws {
        let (store, url) = try temporaryStore()
        store.addTransaction(Transaction(title: "Private expense", amount: 10, categoryId: "groceries", accountId: "cash"))
        store.flushPendingSave(); store.flushPendingSave()
        let copy = url.appendingPathExtension("unreadable-test")
        try FileManager.default.copyItem(at: url, to: copy)
        store.eraseAllData()
        XCTAssertNil(store.persistenceError)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.appendingPathExtension("backup").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: copy.path))
        let reloaded = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertTrue(reloaded.transactions.isEmpty)
    }

    @MainActor func testInvalidRecoveryBackupKeepsBothFiles() throws {
        let (_, url) = try temporaryStore()
        let primary = Data("broken primary".utf8), backup = Data("broken backup".utf8)
        try primary.write(to: url); try backup.write(to: url.appendingPathExtension("backup"))
        let store = ExpenseStore(storageURL: url, startsServices: false)
        store.restoreRecoveryBackup()
        XCTAssertNotNil(store.loadError)
        XCTAssertEqual(try Data(contentsOf: url), primary)
        XCTAssertEqual(try Data(contentsOf: url.appendingPathExtension("backup")), backup)
    }

    @MainActor func testSupportedBackupDateFormatsAndInvalidDates() throws {
        struct Value: Decodable { let date: Date }
        for value in ["\"2026-10-10T00:00:00Z\"", "\"2026-10-10T00:00:00.123Z\"", "\"2026-10-10\"", "1700000000", "1700000000000"] {
            XCTAssertNoThrow(try ExpenseStore.jsonDecoder.decode(Value.self, from: Data("{\"date\":\(value)}".utf8)))
        }
        XCTAssertThrowsError(try ExpenseStore.jsonDecoder.decode(Value.self, from: Data("{\"date\":\"invalid\"}".utf8)))
    }

    @MainActor func testDeletingAccountKeepsHistoryRecoverable() throws {
        let (store, url) = try temporaryStore()
        store.addTransaction(Transaction(title: "Transfer", amount: 25, type: .transfer, categoryId: "", accountId: "cash", toAccountId: "bank"))
        store.deleteAccount(id: "cash")
        store.deleteAccount(id: "bank") // The last account must remain.
        XCTAssertEqual(store.accounts.count, 1)
        XCTAssertEqual(store.totalBalance, 0)
        store.flushPendingSave()
        XCTAssertNil(ExpenseStore(storageURL: url, startsServices: false).loadError)
    }

    @MainActor func testCancelledSubscriptionsDoNotCountAsCommittedSpending() throws {
        let (store, _) = try temporaryStore()
        let sub = Subscription(name: "Cancelled service", amount: 25)
        store.addSubscription(sub)
        XCTAssertEqual(store.totalMonthlySubscriptionCommitted, 25)
        store.cancelSubscription(id: sub.id)
        XCTAssertEqual(store.totalMonthlySubscriptionCommitted, 0)
        store.flushPendingSave()
    }

    @MainActor func testLargeLedgerPersistencePerformance() throws {
        let (store, _) = try temporaryStore()
        store.transactions = (0..<10_000).map { _ in Transaction(title: "Expense", amount: 1, categoryId: "groceries", accountId: "cash") }
        measure { store.flushPendingSave() }
        XCTAssertNil(store.persistenceError)
    }

    @MainActor func testOfflineRateRefreshKeepsCachedRatesAndLedger() async throws {
        let (store, _) = try temporaryStore()
        store.ratesToUSD = ["USD": 1, "INR": 84]
        store.addTransaction(Transaction(title: "Offline expense", amount: 12, categoryId: "groceries", accountId: "cash"))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OfflineURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        await store.refreshExchangeRates(force: true, session: session)
        XCTAssertEqual(store.ratesToUSD, ["USD": 1, "INR": 84])
        XCTAssertNotNil(store.ratesError)
        XCTAssertFalse(store.isRefreshingRates)
        XCTAssertEqual(store.balance(for: "cash"), -12)
        store.flushPendingSave()
    }

}


nonisolated final class OfflineURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)) }
    override func stopLoading() {}
}
