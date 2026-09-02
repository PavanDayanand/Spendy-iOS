//
//  InsightExposureStore.swift
//  Spendy
//
//  Lightweight, privacy-first local exposure tracking and fatigue manager.
//  Prevents nagging while intelligently re-triggering on material delta shifts or critical warnings.
//

import Foundation

struct InsightExposureRecord: Codable, Sendable {
    let semanticId: String
    var firstSurfacedAt: Date
    var lastSurfacedAt: Date
    var exposureCount: Int
    var lastNumericValue: Double?
    var lastDeltaPercentage: Double?
}

final class InsightExposureStore: @unchecked Sendable {
    static let shared = InsightExposureStore()
    
    private let lock = NSLock()
    private var records: [String: InsightExposureRecord] = [:]
    private let fileURL: URL
    
    init(fileURL: URL? = nil) {
        if let customURL = fileURL {
            self.fileURL = customURL
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let base = paths.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.fileURL = base.appendingPathComponent("spendy_insight_exposures.json")
        }
        loadFromDisk()
    }
    
    // MARK: - Fatigue & Cooldown Evaluation
    
    /// Evaluates whether an insight candidate should be suppressed due to recent exposure
    func shouldSuppress(
        semanticId: String,
        isCritical: Bool,
        currentDelta: Double? = nil,
        currentValue: Double? = nil,
        cooldownHours: Double = 24.0,
        now: Date = Date()
    ) -> Bool {
        // Critical alerts (e.g. budget exceeded, overdue bill) unconditionally bypass fatigue
        if isCritical {
            return false
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        guard let record = records[semanticId] else {
            return false
        }
        
        let elapsedSeconds = now.timeIntervalSince(record.lastSurfacedAt)
        let cooldownSeconds = cooldownHours * 3600.0
        
        if elapsedSeconds < cooldownSeconds {
            // Check for material change since last exposure
            if let curDelta = currentDelta, let prevDelta = record.lastDeltaPercentage {
                let deltaShift = abs(curDelta - prevDelta)
                if deltaShift >= 10.0 { // e.g. grew from +15% to +26%
                    return false
                }
            }
            if let curVal = currentValue, let prevVal = record.lastNumericValue, prevVal > 0 {
                let valueShiftPct = abs(curVal - prevVal) / prevVal
                if valueShiftPct >= 0.20 { // 20% shift in underlying metric
                    return false
                }
            }
            return true
        }
        
        return false
    }
    
    /// Records that an insight was surfaced to the user
    func recordExposure(
        semanticId: String,
        delta: Double? = nil,
        value: Double? = nil,
        now: Date = Date()
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        if var existing = records[semanticId] {
            existing.lastSurfacedAt = now
            existing.exposureCount += 1
            existing.lastDeltaPercentage = delta
            existing.lastNumericValue = value
            records[semanticId] = existing
        } else {
            let record = InsightExposureRecord(
                semanticId: semanticId,
                firstSurfacedAt: now,
                lastSurfacedAt: now,
                exposureCount: 1,
                lastNumericValue: value,
                lastDeltaPercentage: delta
            )
            records[semanticId] = record
        }
        
        saveToDisk()
    }
    
    /// Clear all records (useful for testing and debug resets)
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        records.removeAll()
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: InsightExposureRecord].self, from: data)
            self.records = decoded
        } catch {
            print("InsightExposureStore failed to load: \(error.localizedDescription)")
        }
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("InsightExposureStore failed to save: \(error.localizedDescription)")
        }
    }
}
