//
//  Hexagon.swift
//  NucleantLayouts
//

import NucleantUI

/// A hexagon standing on a point, filling its rect — the cell
/// `HoneycombLayout` interlocks.
///
/// ```swift
/// Color.orange.clipShape(Hexagon())
/// Hexagon().fill(Color.orange).frame(width: 58, height: 58 * Hexagon.heightPerWidth)
/// ```
///
/// In a rect `heightPerWidth` as tall as it is wide, it is regular — every
/// side the same length — which is the size `HoneycombLayout` offers.
@View
public struct Hexagon: Shape {
    /// A regular pointy-top hexagon is 2/√3 as tall as it is wide.
    public static let heightPerWidth = 2 / 3.0.squareRoot()

    public init() {}

    public func path(in rect: Rect) -> Path {
        var path = Path()
        let quarter = rect.height / 4
        path.move(to: Point(x: rect.midX, y: rect.minY))
        path.addLine(to: Point(x: rect.maxX, y: rect.minY + quarter))
        path.addLine(to: Point(x: rect.maxX, y: rect.maxY - quarter))
        path.addLine(to: Point(x: rect.midX, y: rect.maxY))
        path.addLine(to: Point(x: rect.minX, y: rect.maxY - quarter))
        path.addLine(to: Point(x: rect.minX, y: rect.minY + quarter))
        path.closeSubpath()
        return path
    }
}
