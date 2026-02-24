//
//  NotchShape.swift
//  Notch
//
//  Custom SwiftUI Shape with a sharp top-left corner and rounded corners
//  everywhere else, so the panel sits flush against the screen corner.

import SwiftUI

struct NotchShape: Shape {
    var radius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Top-left: sharp corner (flush with screen edge)
        p.move(to: .init(x: rect.minX, y: rect.minY))
        // Top-right: rounded
        p.addLine(to: .init(x: rect.maxX - radius, y: rect.minY))
        p.addArc(center: .init(x: rect.maxX - radius, y: rect.minY + radius),
                 radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0),   clockwise: false)
        // Bottom-right: rounded
        p.addLine(to: .init(x: rect.maxX, y: rect.maxY - radius))
        p.addArc(center: .init(x: rect.maxX - radius, y: rect.maxY - radius),
                 radius: radius, startAngle: .degrees(0),   endAngle: .degrees(90),  clockwise: false)
        // Bottom-left: rounded
        p.addLine(to: .init(x: rect.minX + radius, y: rect.maxY))
        p.addArc(center: .init(x: rect.minX + radius, y: rect.maxY - radius),
                 radius: radius, startAngle: .degrees(90),  endAngle: .degrees(180), clockwise: false)
        // Back to top-left sharp
        p.addLine(to: .init(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
