import CryptoKit
import Foundation

struct ReceiptShareContext: Codable {
    var currencySymbol: String
    var currencyCode: String
    var categories: [Category]
    var accounts: [Account]
}

struct SharedReceiptEntry: Codable {
    var id = UUID()
    var sourceKey: String
    var title: String
    var amount: Double
    var type: TransactionType
    var categoryId: String
    var accountId: String
    var date: Date
    var currencySymbol: String
    var currencyCode: String
}

enum ReceiptShareError: LocalizedError {
    case unavailable, duplicate, invalidEntry

    var errorDescription: String? {
        switch self {
        case .unavailable: "Open Spendy once to make your accounts and categories available, then share the receipt again."
        case .duplicate: "This receipt has already been added to Spendy."
        case .invalidEntry: "Check the amount, note, category, account, and date before adding."
        }
    }
}

/// One atomic file per confirmed entry. Extensions never overwrite the app's ledger.
enum ReceiptShareStore {
    static func directory() throws -> URL {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Spendy") else {
            throw ReceiptShareError.unavailable
        }
        return group.appending(path: "ReceiptSharing", directoryHint: .isDirectory)
    }

    static func sourceKey(data: Data, recognizedText: String) -> String {
        let pattern = #"(?i)\b(?:upi\s+(?:transaction\s+id|ref(?:erence)?(?:\s+no)?)|utr|rrn)\s*[:#-]?\s*([A-Z0-9]{8,40})\b"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let ns = recognizedText as NSString
        let reference = regex?.firstMatch(in: recognizedText, range: NSRange(location: 0, length: ns.length))
            .map { ns.substring(with: $0.range(at: 1)).uppercased() }
        let identity = reference.map { Data("upi:\($0)".utf8) } ?? data
        return SHA256.hash(data: identity).map { String(format: "%02x", $0) }.joined()
    }

    static func publish(_ context: ReceiptShareContext, at root: URL? = nil) throws {
        try coordinated(at: root) { directory in
            try JSONEncoder().encode(context).write(to: directory.appending(path: "context.json"), options: .atomic)
        }
    }

    static func context(at root: URL? = nil) throws -> ReceiptShareContext {
        try coordinated(at: root) { directory in
            let url = directory.appending(path: "context.json")
            guard let data = try? Data(contentsOf: url),
                  let context = try? JSONDecoder().decode(ReceiptShareContext.self, from: data),
                  !context.accounts.isEmpty, !context.categories.isEmpty else { throw ReceiptShareError.unavailable }
            return context
        }
    }

    static func enqueue(_ entry: SharedReceiptEntry, at root: URL? = nil) throws {
        guard entry.amount.isFinite, entry.amount > 0, entry.type != .transfer,
              !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !entry.categoryId.isEmpty, !entry.accountId.isEmpty, !entry.currencySymbol.isEmpty, !entry.currencyCode.isEmpty,
              entry.date.timeIntervalSince1970.isFinite,
              entry.sourceKey.range(of: #"^[a-f0-9]{64}$"#, options: .regularExpression) != nil else {
            throw ReceiptShareError.invalidEntry
        }
        try coordinated(at: root) { directory in
            let context = try JSONDecoder().decode(ReceiptShareContext.self,
                from: Data(contentsOf: directory.appending(path: "context.json")))
            guard context.currencySymbol == entry.currencySymbol, context.currencyCode == entry.currencyCode,
                  context.accounts.contains(where: { $0.id == entry.accountId }),
                  context.categories.contains(where: { $0.id == entry.categoryId && $0.type == entry.type && !$0.isHidden }) else {
                throw ReceiptShareError.unavailable
            }
            for folder in ["pending", "imported"] {
                let url = directory.appending(path: folder, directoryHint: .isDirectory)
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: url.appending(path: entry.sourceKey + ".json").path) {
                    throw ReceiptShareError.duplicate
                }
            }
            let url = directory.appending(path: "pending/" + entry.sourceKey + ".json")
            try JSONEncoder().encode(entry).write(to: url, options: .atomic)
        }
    }

    static func pending(at root: URL? = nil) throws -> [SharedReceiptEntry] {
        try coordinated(at: root) { directory in
            let folder = directory.appending(path: "pending", directoryHint: .isDirectory)
            guard FileManager.default.fileExists(atPath: folder.path) else { return [] }
            return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
                .map { try JSONDecoder().decode(SharedReceiptEntry.self, from: Data(contentsOf: $0)) }
        }
    }

    static func acknowledge(_ entries: [SharedReceiptEntry], at root: URL? = nil) throws {
        try coordinated(at: root) { directory in
            let imported = directory.appending(path: "imported", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: imported, withIntermediateDirectories: true)
            for entry in entries {
                let source = directory.appending(path: "pending/" + entry.sourceKey + ".json")
                guard FileManager.default.fileExists(atPath: source.path) else { continue }
                let target = imported.appending(path: entry.sourceKey + ".json")
                // Retain only a deduplication marker after the ledger has durably saved.
                try Data().write(to: target, options: .atomic)
                try FileManager.default.removeItem(at: source)
            }
        }
    }

    static func clear(at root: URL? = nil) throws {
        try coordinated(at: root) { directory in
            for name in ["pending", "imported"] {
                let url = directory.appending(path: name)
                if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            }
        }
    }

    private static func coordinated<T>(at root: URL?, _ operation: (URL) throws -> T) throws -> T {
        let root = try root ?? directory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var coordinationError: NSError?
        var result: Result<T, Error>?
        NSFileCoordinator().coordinate(writingItemAt: root, options: [], error: &coordinationError) { url in
            result = Result { try operation(url) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw ReceiptShareError.unavailable }
        return try result.get()
    }
}
