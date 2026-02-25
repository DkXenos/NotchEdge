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
            
            // 1. Start at top-left (Sharp)
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            
            // 2. Line to top-right (Sharp)
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            
            // 3. Line to bottom-right (Rounded)
            // We stop just before the corner to start the arc
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            p.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                     radius: radius,
                     startAngle: .degrees(0),
                     endAngle: .degrees(90),
                     clockwise: false)
            
            // 4. Line to bottom-left (Sharp)
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            
            // 5. Close back to start
            p.closeSubpath()
            
            return p
        }
}
