//
//  CircularLayout.swift
//  NucleantLayouts
//
//  Created by CodeBuilder on 08/11/2026.
//

import Foundation
import NucleantUI

/// Subviews spaced evenly round a circle, the first at `startAngle`
/// (straight up by default) and the rest following clockwise.
///
/// ```swift
/// // As big a circle as the space allows.
/// CircularLayout {
///     ForEach(hours, id: \.self) { hour in
///         Text("\(hour)")
///     }
/// }
///
/// // Or a circle of a set size.
/// CircularLayout(radius: 120) { ... }
/// ```
///
/// With no `radius`, the circle fits the space the layout is given: the
/// subviews round it reach its edges. Offered no space, as along a
/// `ScrollView`'s scrolling axis, it is the smallest circle whose
/// subviews don't overlap. With a `radius`, the circle is that size, and
/// the layout is as big as the circle plus the largest subview.
///
/// A subview with a size of its own keeps it; a flexible one — a `Color`,
/// a `Circle` — is offered the biggest square that clears its neighbours,
/// however the circle is turned, and fits in the space the layout is
/// given.
///
/// `startAngle` animates: turning it under `withAnimation` swings every
/// subview round the circle. `radius` animates from one radius to another.
public struct CircularLayout: Layout {
    /// From the centre of the circle to the centre of each subview; `nil`
    /// fits the circle to the space the layout is given.
    public var radius: Double?
    /// Where the first subview sits. Zero is to the right (3 o'clock);
    /// angles grow clockwise.
    public var startAngle: Angle

    public init(radius: Double? = nil, startAngle: Angle = .degrees(-90)) {
        self.radius = radius
        self.startAngle = startAngle
    }

    public var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(radius ?? 0, startAngle.radians) }
        set {
            // A fitted circle's radius comes from its space, not from here.
            if radius != nil { radius = newValue.first }
            startAngle = .radians(newValue.second)
        }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let item = itemProposal(count: subviews.count, offered: proposal)
        return arrangement(of: subviews.map { $0.sizeThatFits(item) }, in: proposal).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let offered = ProposedViewSize(bounds.size)
        let item = itemProposal(count: subviews.count, offered: offered)
        let arrangement = arrangement(of: subviews.map { $0.sizeThatFits(item) }, in: offered)
        // Centred in whatever it was given.
        let origin = bounds.center - arrangement.size / 2
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    /// The biggest square that clears its neighbours on the circle and,
    /// with the circle, fits in `offered`; unspecified when nothing is
    /// offered.
    func itemProposal(count: Int, offered: ProposedViewSize) -> ProposedViewSize {
        let sides = [offered.width, offered.height].compactMap { $0 }.filter(\.isFinite)
        guard count > 0, let side = sides.min() else { return .unspecified }
        let clearance = Self.clearance(count: count)
        let size: Double
        if let radius {
            let radius = max(0, radius)
            let room = side - radius * 2
            size = clearance.isFinite ? min(room, clearance * radius) : room
        } else if clearance.isFinite {
            // Across the circle: a subview, two radii, the subview opposite.
            // Grow the circle until the squares on it just clear each other.
            size = side * clearance / (2 + clearance)
        } else {
            // One subview has no neighbours: it takes the whole space.
            size = side
        }
        return ProposedViewSize(width: max(0, size), height: max(0, size))
    }

    /// The side of the biggest square that clears its neighbours, per unit
    /// of radius. Neighbours' centres are `2 sin(π / count)` radii apart,
    /// and two squares that far apart in any direction clear each other
    /// if their side is no more than that over √2 — the distance along a
    /// diagonal, the closest they come as the circle turns. Unbounded
    /// for a lone subview.
    static func clearance(count: Int) -> Double {
        guard count > 1 else { return .infinity }
        return 2.0.squareRoot() * sin(Double.pi / Double(count))
    }

    /// The radius of a circle with no `radius` of its own: as big as keeps
    /// every subview inside `offered`; offered nothing, the smallest whose
    /// subviews don't overlap.
    func fittedRadius(count: Int, largest: Size, offered: ProposedViewSize) -> Double {
        let room = [
            offered.width.map { ($0 - largest.width) / 2 },
            offered.height.map { ($0 - largest.height) / 2 },
        ].compactMap { $0 }.filter(\.isFinite)
        if let fit = room.min() { return max(0, fit) }
        let clearance = Self.clearance(count: count)
        guard clearance.isFinite else { return 0 }
        return max(largest.width, largest.height) / clearance
    }

    /// Each subview's frame, from the top-leading corner of a box that holds
    /// the whole circle, and the box's size.
    func arrangement(of sizes: [Size], in offered: ProposedViewSize) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let largest = sizes.reduce(Size.zero) { Size(width: max($0.width, $1.width), height: max($0.height, $1.height)) }
        let radius = max(0, self.radius ?? fittedRadius(count: sizes.count, largest: largest, offered: offered))
        let size = Size(width: radius * 2 + largest.width, height: radius * 2 + largest.height)
        let center = size / 2
        let step = 2 * Double.pi / Double(sizes.count)
        let frames = sizes.enumerated().map { index, itemSize in
            let angle = startAngle.radians + step * Double(index)
            let point = Point(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            return Rect(origin: point - itemSize / 2, size: itemSize)
        }
        return (frames, size)
    }
}
