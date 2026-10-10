import Foundation

/// One queue owns all file writes, including the lifecycle flush.
nonisolated final class LocalStoreWriter: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.Spendy.local-store", qos: .utility)

    func enqueue(_ data: Data, to url: URL, completion: @escaping @Sendable (String?) -> Void) {
        queue.async { completion(Self.write(data, to: url)) }
    }

    func flush(_ data: Data, to url: URL, clearRecovery: Bool = false) -> String? {
        queue.sync { Self.write(data, to: url, clearRecovery: clearRecovery) }
    }

    private static func write(_ data: Data, to url: URL, clearRecovery: Bool = false) -> String? {
        do {
            // Keep the previous successful snapshot before atomically replacing the primary.
            if !clearRecovery && FileManager.default.fileExists(atPath: url.path) {
                let previous = try Data(contentsOf: url)
                try previous.write(to: url.appendingPathExtension("backup"), options: .atomic)
            }
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            if clearRecovery {
                let files = try FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil)
                for file in files where file.lastPathComponent == url.lastPathComponent + ".backup"
                    || file.lastPathComponent.hasPrefix(url.lastPathComponent + ".unreadable-") {
                    try FileManager.default.removeItem(at: file)
                }
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
