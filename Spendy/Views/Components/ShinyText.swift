//
//  ShinyText.swift
//  Spendy
//
//  SwiftUI port of React Bits ShinyText: a moving highlight band
//  clipped to glyphs (background-clip: text).
//

import SwiftUI

struct ShinyText: View {
    enum Direction {
        case left
        case right
    }
    
    let text: String
    var font: Font = .body
    var color: Color = Color(hex: "#b5b5b5")
    var shineColor: Color = Color.white
    var speed: Double = 2.4
    var delay: Double = 0.7
    var spread: Double = 90
    var direction: Direction = .right
    var yoyo: Bool = false
    var phaseOffset: Double = 0
    var disabled: Bool = false
    var alignment: TextAlignment = .leading
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        let label = Text(text)
            .font(font)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
        
        if disabled || reduceMotion || scenePhase != .active {
            label
                .foregroundStyle(color)
        } else {
            label
                .foregroundStyle(color)
                .overlay {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        let p = shineProgress(at: context.date) / 100.0
                        GeometryReader { geo in
                            angledShineGradient
                                .frame(width: geo.size.width * 2, height: geo.size.height * 2)
                                .offset(
                                    x: (1.0 - p * 2.0) * geo.size.width,
                                    y: -geo.size.height * 0.5
                                )
                        }
                    }
                    .mask(label)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
                .mask(label)
        }
    }
    
    private var angledShineGradient: LinearGradient {
        let radians = spread * .pi / 180.0
        let dx = CGFloat(sin(radians))
        let dy = CGFloat(-cos(radians))
        let start = UnitPoint(x: 0.5 - dx * 0.5, y: 0.5 - dy * 0.5)
        let end = UnitPoint(x: 0.5 + dx * 0.5, y: 0.5 + dy * 0.5)
        
        return LinearGradient(
            stops: [
                .init(color: color, location: 0),
                .init(color: color, location: 0.42),
                .init(color: shineColor.opacity(0.35), location: 0.47),
                .init(color: shineColor, location: 0.50),
                .init(color: shineColor.opacity(0.35), location: 0.53),
                .init(color: color, location: 0.58),
                .init(color: color, location: 1)
            ],
            startPoint: start,
            endPoint: end
        )
    }
    
    static func progress(
        at date: Date,
        speed: Double = 2.4,
        delay: Double = 0.7,
        direction: Direction = .right,
        phaseOffset: Double = 0,
        yoyo: Bool = false
    ) -> Double {
        let elapsed = max(0, date.timeIntervalSinceReferenceDate - phaseOffset) * 1000
        let animationDuration = speed * 1000
        let delayDuration = delay * 1000
        let goingLeft = direction == .left
        
        func easeInOut(_ percent: Double) -> Double {
            let t = min(100, max(0, percent)) / 100.0
            return t * t * (3 - 2 * t) * 100
        }
        
        if yoyo {
            let cycleDuration = animationDuration + delayDuration
            let fullCycle = cycleDuration * 2
            let cycleTime = elapsed.truncatingRemainder(dividingBy: fullCycle)
            
            if cycleTime < animationDuration {
                let p = easeInOut((cycleTime / animationDuration) * 100)
                return goingLeft ? p : 100 - p
            } else if cycleTime < cycleDuration {
                return goingLeft ? 100 : 0
            } else if cycleTime < cycleDuration + animationDuration {
                let reverseTime = cycleTime - cycleDuration
                let p = easeInOut(100 - (reverseTime / animationDuration) * 100)
                return goingLeft ? p : 100 - p
            } else {
                return goingLeft ? 0 : 100
            }
        } else {
            let cycleDuration = animationDuration + delayDuration
            let cycleTime = elapsed.truncatingRemainder(dividingBy: max(cycleDuration, 1))
            if cycleTime < animationDuration {
                let p = easeInOut((cycleTime / animationDuration) * 100)
                return goingLeft ? p : 100 - p
            }
            return goingLeft ? 100 : 0
        }
    }
    
    private func shineProgress(at date: Date) -> Double {
        Self.progress(
            at: date,
            speed: speed,
            delay: delay,
            direction: direction,
            phaseOffset: phaseOffset,
            yoyo: yoyo
        )
    }
}

struct InsightShineBand: View {
    var color: Color
    var shineColor: Color
    var spread: Double = 90
    var progress: Double
    
    var body: some View {
        GeometryReader { geo in
            let radians = spread * .pi / 180.0
            let dx = CGFloat(sin(radians))
            let dy = CGFloat(-cos(radians))
            LinearGradient(
                stops: [
                    .init(color: color, location: 0),
                    .init(color: color, location: 0.42),
                    .init(color: shineColor.opacity(0.35), location: 0.47),
                    .init(color: shineColor, location: 0.50),
                    .init(color: shineColor.opacity(0.35), location: 0.53),
                    .init(color: color, location: 0.58),
                    .init(color: color, location: 1)
                ],
                startPoint: UnitPoint(x: 0.5 - dx * 0.5, y: 0.5 - dy * 0.5),
                endPoint: UnitPoint(x: 0.5 + dx * 0.5, y: 0.5 + dy * 0.5)
            )
            .frame(width: geo.size.width * 2, height: geo.size.height * 2)
            .offset(
                x: (1.0 - progress * 2.0) * geo.size.width,
                y: -geo.size.height * 0.5
            )
        }
    }
}
