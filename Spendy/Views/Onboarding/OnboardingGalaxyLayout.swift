//
//  OnboardingGalaxyLayout.swift
//  Spendy
//
//  Eight equal-size sticker slots with guaranteed gaps and a clear center hole.
//

import SwiftUI

enum OnboardingGalaxyLayout {
    struct Slot: Equatable, Sendable {
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var size: CGFloat

        var burstDelay: Double {
            let distance = hypot(Double(x), Double(y))
            return min(0.22, distance / 1200.0)
        }
    }

    /// Center-relative design positions on a 393 × 720 stage. Leaves a clear hole for the wordmark.
    private static let designAnchors: [(x: CGFloat, y: CGFloat, rotation: Double)] = [
        (-112, -248, -6),
        (112, -248, 5),
        (-118, -128, 6),
        (118, -128, -6),
        (-118, 128, -5),
        (118, 128, 6),
        (-96, 258, 5),
        (96, 258, -5)
    ]

    static func makeSlots(count: Int, canvas: CGSize, seed: UInt64) -> [Slot] {
        guard canvas.width > 40, canvas.height > 40, count > 0 else { return [] }

        var rng = SplitMix64(seed: seed)
        let density = min(1.04, max(0.84, canvas.width / 393.0))
        let size = 104 * density
        let wScale = canvas.width / 393.0
        let hScale = canvas.height / 720.0
        let center = CGPoint(x: canvas.width / 2, y: canvas.height * 0.44)

        var slots: [Slot] = []
        slots.reserveCapacity(count)

        for index in 0..<count {
            let anchor = designAnchors[index % designAnchors.count]
            let jitterX = CGFloat.random(in: -3...3, using: &rng)
            let jitterY = CGFloat.random(in: -4...4, using: &rng)
            slots.append(
                Slot(
                    x: anchor.x * wScale + jitterX,
                    y: anchor.y * hScale + jitterY,
                    rotation: anchor.rotation + Double.random(in: -1.5...1.5, using: &rng),
                    size: size
                )
            )
        }

        separate(&slots, minFactor: 0.58)
        clamp(&slots, canvas: canvas, center: center, inset: 22)

        return slots
    }

    static func stackJitter(for index: Int) -> (x: CGFloat, y: CGFloat, rotation: Double) {
        let table: [(CGFloat, CGFloat, Double)] = [
            (0, 0, -4),
            (-4, 3, 5),
            (5, -2, -3),
            (-3, 4, 6),
            (4, -3, -7),
            (-5, 2, 3),
            (3, -4, -5),
            (2, 3, 2)
        ]
        return table[index % table.count]
    }

    private static func separate(_ slots: inout [Slot], minFactor: CGFloat) {
        guard slots.count > 1 else { return }
        for _ in 0..<4 {
            for i in 0..<slots.count {
                for j in 0..<i {
                    let dx = slots[i].x - slots[j].x
                    let dy = slots[i].y - slots[j].y
                    var dist = hypot(dx, dy)
                    if dist < 1 { dist = 1 }
                    let minDist = (slots[i].size + slots[j].size) * minFactor
                    if dist < minDist {
                        let push = (minDist - dist) / 2
                        let nx = dx / dist
                        let ny = dy / dist
                        slots[i].x += nx * push
                        slots[i].y += ny * push
                        slots[j].x -= nx * push
                        slots[j].y -= ny * push
                    }
                }
            }
        }
    }

    private static func clamp(_ slots: inout [Slot], canvas: CGSize, center: CGPoint, inset: CGFloat) {
        for i in 0..<slots.count {
            let half = slots[i].size * 0.54
            let absX = min(max(center.x + slots[i].x, inset + half), canvas.width - inset - half)
            let absY = min(max(center.y + slots[i].y, inset + half), canvas.height - inset - half)
            slots[i].x = absX - center.x
            slots[i].y = absY - center.y
        }
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
