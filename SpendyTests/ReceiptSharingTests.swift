import XCTest
@testable import Spendy

final class ReceiptSharingTests: XCTestCase {
    @MainActor private func fixture() throws -> (ExpenseStore, URL, URL) {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let ledger = root.appending(path: "ledger.json")
        let store = ExpenseStore(storageURL: ledger, startsServices: false)
        store.currencySymbol = "₹"
        store.currencyCode = "INR"
        store.flushPendingSave()
        let queue = root.appending(path: "shared")
        try ReceiptShareStore.publish(ReceiptShareContext(currencySymbol: store.currencySymbol,
            currencyCode: store.currencyCode,
            categories: store.categories, accounts: store.accounts), at: queue)
        return (store, queue, ledger)
    }

    @MainActor private func entry(_ value: String = "receipt") -> SharedReceiptEntry {
        SharedReceiptEntry(sourceKey: ReceiptShareStore.sourceKey(data: Data(value.utf8), recognizedText: ""),
            title: "Corner Cafe", amount: 135, type: .expense, categoryId: "restaurants",
            accountId: "cash", date: Date(timeIntervalSince1970: 1_792_000_000), currencySymbol: "₹", currencyCode: "INR")
    }

    @MainActor func testConfirmedReceiptPersistsAndDeduplicatesAcrossRelaunch() throws {
        let (store, queue, ledger) = try fixture()
        let receipt = entry()
        try ReceiptShareStore.enqueue(receipt, at: queue)
        XCTAssertThrowsError(try ReceiptShareStore.enqueue(receipt, at: queue))
        store.ingestSharedReceipts(at: queue)
        XCTAssertNil(store.sharedReceiptImportError)
        XCTAssertTrue(try ReceiptShareStore.pending(at: queue).isEmpty)
        let reloaded = ExpenseStore(storageURL: ledger, startsServices: false)
        XCTAssertEqual(reloaded.transactions.filter { $0.id == receipt.id }.count, 1)
        XCTAssertEqual(reloaded.transactions.first { $0.id == receipt.id }?.accountId, "cash")
        XCTAssertThrowsError(try ReceiptShareStore.enqueue(receipt, at: queue))
    }

    @MainActor func testRetryAfterLedgerCommitDoesNotInsertTwice() throws {
        let (store, queue, _) = try fixture()
        let receipt = entry()
        try ReceiptShareStore.enqueue(receipt, at: queue)
        store.addTransactionFromIntent(Transaction(id: receipt.id, title: receipt.title, amount: receipt.amount,
            categoryId: receipt.categoryId, accountId: receipt.accountId, date: receipt.date))
        store.ingestSharedReceipts(at: queue)
        XCTAssertEqual(store.transactions.filter { $0.id == receipt.id }.count, 1)
        XCTAssertTrue(try ReceiptShareStore.pending(at: queue).isEmpty)
    }

    @MainActor func testChangedAccountAndCurrencyRetainReceiptWithoutFallback() throws {
        let (store, queue, _) = try fixture()
        let receipt = entry()
        try ReceiptShareStore.enqueue(receipt, at: queue)
        store.accounts.removeAll { $0.id == receipt.accountId }
        store.ingestSharedReceipts(at: queue)
        XCTAssertNotNil(store.sharedReceiptImportError)
        XCTAssertFalse(store.transactions.contains { $0.id == receipt.id })
        XCTAssertEqual(try ReceiptShareStore.pending(at: queue).count, 1)
        store.accounts = Account.defaultAccounts
        store.currencySymbol = "$"
        store.ingestSharedReceipts(at: queue)
        XCTAssertEqual(try ReceiptShareStore.pending(at: queue).count, 1)
        store.currencySymbol = "₹"
        store.ingestSharedReceipts(at: queue)
        XCTAssertNil(store.sharedReceiptImportError)
        XCTAssertTrue(try ReceiptShareStore.pending(at: queue).isEmpty)
    }

    @MainActor func testFailedLedgerSaveKeepsQueueForRetry() throws {
        let (store, queue, ledger) = try fixture()
        let receipt = entry()
        try ReceiptShareStore.enqueue(receipt, at: queue)
        try FileManager.default.removeItem(at: ledger)
        try FileManager.default.createDirectory(at: ledger, withIntermediateDirectories: true)
        store.ingestSharedReceipts(at: queue)
        XCTAssertNotNil(store.persistenceError)
        XCTAssertEqual(try ReceiptShareStore.pending(at: queue).count, 1)
        try FileManager.default.removeItem(at: ledger)
        store.ingestSharedReceipts(at: queue)
        XCTAssertNil(store.persistenceError)
        XCTAssertTrue(try ReceiptShareStore.pending(at: queue).isEmpty)
        XCTAssertEqual(store.transactions.filter { $0.id == receipt.id }.count, 1)
    }

    @MainActor func testInvalidEntriesAndStaleContextCannotBeQueued() throws {
        let (_, queue, _) = try fixture()
        var receipt = entry()
        receipt.amount = .infinity
        XCTAssertThrowsError(try ReceiptShareStore.enqueue(receipt, at: queue))
        receipt = entry(); receipt.sourceKey = "../ledger"
        XCTAssertThrowsError(try ReceiptShareStore.enqueue(receipt, at: queue))
        receipt = entry(); receipt.accountId = "deleted"
        XCTAssertThrowsError(try ReceiptShareStore.enqueue(receipt, at: queue))
        XCTAssertTrue(try ReceiptShareStore.pending(at: queue).isEmpty)
    }

    @MainActor func testAcknowledgementKeepsOtherReceiptAndClearResetsDeduplication() throws {
        let (_, queue, _) = try fixture()
        let first = entry("one"), second = entry("two")
        try ReceiptShareStore.enqueue(first, at: queue)
        try ReceiptShareStore.enqueue(second, at: queue)
        try ReceiptShareStore.acknowledge([first], at: queue)
        XCTAssertEqual(try ReceiptShareStore.pending(at: queue).map(\.id), [second.id])
        try ReceiptShareStore.clear(at: queue)
        XCTAssertTrue(try ReceiptShareStore.pending(at: queue).isEmpty)
        try ReceiptShareStore.enqueue(first, at: queue)
    }

    @MainActor func testTransactionReferenceDeduplicatesImageAndText() {
        let text = "UPI transaction ID\n628568399798"
        XCTAssertEqual(ReceiptShareStore.sourceKey(data: Data("image".utf8), recognizedText: text),
                       ReceiptShareStore.sourceKey(data: Data("text".utf8), recognizedText: text))
        XCTAssertNotEqual(ReceiptShareStore.sourceKey(data: Data("one".utf8), recognizedText: "UPI ID user@bank"),
                          ReceiptShareStore.sourceKey(data: Data("two".utf8), recognizedText: "UPI ID user@bank"))
    }

}
