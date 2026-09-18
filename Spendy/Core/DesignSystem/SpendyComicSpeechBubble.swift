//
//  SpendyComicSpeechBubble.swift
//  Spendy
//
//  Comic book style speech / thought bubble with die-cut white fill,
//  black ink stroke, and directional pointer tail.
//

import SwiftUI

public struct SpendyComicSpeechBubble: View {
    public enum TailDirection {
        case bottomLeading
        case bottomTrailing
        case topLeading
        case topTrailing
        case leading
        case trailing
        case none
    }
    
    let text: String
    var tailDirection: TailDirection = .bottomTrailing
    var fontSize: CGFloat = 15
    var maxWidth: CGFloat = 240
    
    public init(
        _ text: String,
        tailDirection: TailDirection = .bottomTrailing,
        fontSize: CGFloat = 15,
        maxWidth: CGFloat = 240
    ) {
        self.text = text
        self.tailDirection = tailDirection
        self.fontSize = fontSize
        self.maxWidth = maxWidth
    }
    
    public var body: some View {
        VStack(alignment: tailAlignment, spacing: 0) {
            if tailDirection == .topLeading || tailDirection == .topTrailing {
                speechTail(isPointingUp: true)
            }
            
            Text(text)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: maxWidth, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black, lineWidth: 2.2)
                )
            
            if tailDirection == .bottomLeading || tailDirection == .bottomTrailing {
                speechTail(isPointingUp: false)
            }
        }
    }
    
    private var tailAlignment: HorizontalAlignment {
        switch tailDirection {
        case .bottomLeading, .topLeading: return .leading
        case .bottomTrailing, .topTrailing: return .trailing
        default: return .center
        }
    }
    
    private func speechTail(isPointingUp: Bool) -> some View {
        ComicSpeechTailShape(isPointingUp: isPointingUp)
            .fill(Color.white)
            .frame(width: 14, height: 10)
            .overlay(
                ComicSpeechTailOutlineShape(isPointingUp: isPointingUp)
                    .stroke(Color.black, lineWidth: 2.2)
            )
            .padding(.horizontal, 18)
            .offset(y: isPointingUp ? 2 : -2)
            .zIndex(2)
    }
}

// MARK: - Speech Tail Shapes
private struct ComicSpeechTailShape: Shape {
    let isPointingUp: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isPointingUp {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
        return path
    }
}

private struct ComicSpeechTailOutlineShape: Shape {
    let isPointingUp: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isPointingUp {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        return path
    }
}
