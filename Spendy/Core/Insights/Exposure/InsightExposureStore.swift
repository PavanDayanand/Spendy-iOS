//
//  InsightExposureStore.swift
//  Spendy
//
//  Lightweight, privacy-first local exposure tracking and fatigue manager.
//  Prevents nagging while intelligently re-triggering on material delta shifts or critical warnings.
//  Ensures insights remain available during active period switching.
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
    
    // MARK: - Novelty Calculation
    
    /// Computes deterministic novelty score based on exposure history and material shifts
    func calculateNovelty(
        for semanticId: String,
        currentDelta: Double? = nil,
        currentValue: Double? = nil
    ) -> Double {
        lock.lock()
        defer { lock.unlock() }
        
        guard let record = records[semanticId] else {
            return 1.0 // Unseen candidate: maximum novelty
        }
        
        // If material shift occurred since last surfaced, novelty resets high
        if let curDelta = currentDelta, let prevDelta = record.lastDeltaPercentage, abs(curDelta - prevDelta) >= 10.0 {
            return 0.90
        }
        if let curVal = currentValue, let prevVal = record.lastNumericValue, prevVal > 0, (abs(curVal - prevVal) / prevVal) >= 0.20 {
            return 0.90
        }
        
        switch record.exposureCount {
        case 0: return 1.0
        case 1: return 0.70
        case 2: return 0.40
        default: return 0.15
        }
    }
    
    // MARK: - Fatigue & Suppression Evaluation
    
    /// Evaluates whether an insight candidate should be suppressed due to excessive fatigue.
    /// Does NOT suppress active insights simply because they were viewed earlier in the current session.
    func shouldSuppress(
        semanticId: String,
        isCritical: Bool,
        currentDelta: Double? = nil,
        currentValue: Double? = nil,
        maxExposures: Int = 4,
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
        
        // Material shift unconditionally bypasses suppression
        if let curDelta = currentDelta, let prevDelta = record.lastDeltaPercentage, abs(curDelta - prevDelta) >= 10.0 {
            return false
        }
        if let curVal = currentValue, let prevVal = record.lastNumericValue, prevVal > 0, (abs(curVal - prevVal) / prevVal) >= 0.20 {
            return false
        }
        
        // Suppress only if exposure count has reached the multi-session fatigue ceiling
        return record.exposureCount >= maxExposures
    }
    
    /// Records that an insight was surfaced to the user.
    /// Debounces rapid redraws / period-switching within the same active session.
    func recordExposure(
        semanticId: String,
        delta: Double? = nil,
        value: Double? = nil,
        now: Date = Date()
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        if var existing = records[semanticId] {
            let elapsed = now.timeIntervalSince(existing.lastSurfacedAt)
            let isMaterialShift: Bool = {
                if let d = delta, let prevD = existing.lastDeltaPercentage, abs(d - prevD) >= 10.0 { return true }
                if let v = value, let prevV = existing.lastNumericValue, prevV > 0, (abs(v - prevV) / prevV) >= 0.20 { return true }
                return false
            }()
            
            // Only increment count if at least 1 hour has elapsed or a material shift occurred
            if elapsed >= 3600.0 || isMaterialShift {
                existing.exposureCount += 1
            }
            existing.lastSurfacedAt = now
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
