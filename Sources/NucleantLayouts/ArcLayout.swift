//
//  ArcLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// Subviews spread evenly along part of a circle, from `startAngle` to
/// `endAngle` — a speed dial, or with each turned to match, a hand of
/// cards.
///
/// ```swift
/// ArcLayout(startAngle: .degrees(-150), endAngle: .degrees(-30)) {
///     ForEach(cards.indices, id: \.self) { index in
///         CardView(cards[index])
///     }
/// }
/// ```
///
/// The first subview sits at `startAngle`, the last at `endAngle`, the
/// rest evenly between. Zero is to the right (3 o'clock) and angles grow
/// clockwise, so the default runs over the top. An arc of a whole turn
/// spreads its subviews round it like `CircularLayout`. The layout is as
/// big as the arc's subviews; the rest of the circle takes no space.
///
/// A layout only places subviews; to fan cards, turn each one with
/// `rotationEffect` by `angle(ofSubviewAt:count:)` plus 90°, so it stands
/// out from the centre.
///
/// With no `radius`, the arc is as big as the space the layout is given
/// allows; offered no space, it is the smallest whose subviews don't
/// overlap. A flexible subview — a `Color`, a `Circle` — is offered the
/// biggest square that clears its neighbours and fits. Both angles and
/// `radius` animate (a radius only from one radius to another).
public struct ArcLayout: Layout {
    /// From the centre of the circle to the centre of each subview; `nil`
    /// fits the arc to the space the layout is given.
    public var radius: Double?
    /// Where the first subview sits.
    public var startAngle: Angle
    /// Where the last subview sits.
    public var endAngle: Angle

    public init(radius: Double? = nil, startAngle: Angle = .degrees(-150), endAngle: Angle = .degrees(-30)) {
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
    }

    public var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { AnimatablePair(radius ?? 0, AnimatablePair(startAngle.radians, endAngle.radians)) }
        set {
            // A fitted arc's radius comes from its space, not from here.
            if radius != nil { radius = newValue.first }
            startAngle = .radians(newValue.second.first)
            endAngle = .radians(newValue.second.second)
        }
    }

    /// Where on the circle the subview at `index` of `count` sits.
    public func angle(ofSubviewAt index: Int, count: Int) -> Angle {
        .radians(startAngle.radians + step(count: count) * Double(index) + (count == 1 ? span / 2 : 0))
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let item = itemProposal(count: subviews.count, offered: proposal)
        return arrangement(of: subviews.map { $0.sizeThatFits(item) }, in: proposal).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let offered = ProposedViewSize(bounds.size)
        let item = itemProposal(count: subviews.count, offered: offered)
        let arrangement = arrangement(of: subviews.map { $0.sizeThatFits(item) }, in: offered)
        let origin = bounds.center - arrangement.size / 2
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    private var span: Double { endAngle.radians - startAngle.radians }

    /// A whole turn or more: the last subview would land on the first.
    private var isFullTurn: Bool { abs(span) >= 2 * Double.pi - 1e-9 }

    /// The turn from one subview to the next.
    private func step(count: Int) -> Double {
        if isFullTurn { return span / Double(max(1, count)) }
        return count > 1 ? span / Double(count - 1) : 0
    }

    /// The side of the biggest square that clears its neighbours, per unit
    /// of radius: the chord between the closest two over √2, the closest
    /// two squares that far apart come in any direction. The closest two
    /// are neighbours, or on an arc of nearly a whole turn, the last and
    /// the first, round the gap the arc leaves. Unbounded for a lone
    /// subview.
    func clearance(count: Int) -> Double {
        guard count > 1 else { return .infinity }
        var closest = abs(step(count: count))
        if !isFullTurn { closest = min(closest, 2 * Double.pi - abs(span)) }
        return 2.0.squareRoot() * abs(sin(closest / 2))
    }

    /// How far the subviews' centres reach across and down, per unit of
    /// radius.
    func extent(count: Int) -> Size {
        guard count > 1 else { return .zero }
        let points = (0..<count).map { index -> Point in
            let angle = angle(ofSubviewAt: index, count: count).radians
            return Point(x: cos(angle), y: sin(angle))
        }
        let xs = points.map(\.x), ys = points.map(\.y)
        return Size(width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
    }

    /// The biggest square that clears its neighbours on the arc and, with
    /// the arc, fits in `offered`; unspecified when nothing is offered.
    func itemProposal(count: Int, offered: ProposedViewSize) -> ProposedViewSize {
        guard count > 0 else { return .unspecified }
        let width = offered.width.flatMap { $0.isFinite ? $0 : nil }
        let height = offered.height.flatMap { $0.isFinite ? $0 : nil }
        guard width != nil || height != nil else { return .unspecified }
        let clearance = clearance(count: count)
        let extent = extent(count: count)
        var size = Double.infinity
        if let radius {
            let radius = max(0, radius)
            if let width { size = min(size, width - radius * extent.width) }
            if let height { size = min(size, height - radius * extent.height) }
            if clearance.isFinite { size = min(size, clearance * radius) }
        } else if clearance.isFinite {
            // Grow the arc until the squares on it just clear each other or
            // it meets an edge.
            var radius = Double.infinity
            if let width { radius = min(radius, width / (extent.width + clearance)) }
            if let height { radius = min(radius, height / (extent.height + clearance)) }
            size = clearance * radius
        } else {
            // One subview has no neighbours: it takes the space.
            size = min(width ?? .infinity, height ?? .infinity)
        }
        return ProposedViewSize(width: max(0, size), height: max(0, size))
    }

    /// The radius of an arc with no `radius` of its own: as big as keeps
    /// every subview inside `offered`; offered nothing, the smallest whose
    /// subviews don't overlap.
    func fittedRadius(count: Int, largest: Size, offered: ProposedViewSize) -> Double {
        let extent = extent(count: count)
        var room: [Double] = []
        if let width = offered.width, width.isFinite, extent.width > 1e-9 {
            room.append((width - largest.width) / extent.width)
        }
        if let height = offered.height, height.isFinite, extent.height > 1e-9 {
            room.append((height - largest.height) / extent.height)
        }
        if let fit = room.min() { return max(0, fit) }
        let clearance = clearance(count: count)
        guard clearance.isFinite, clearance > 0 else { return 0 }
        return max(largest.width, largest.height) / clearance
    }

    /// Each subview's frame from the top-leading corner of the box round
    /// them all, and the box's size.
    func arrangement(of sizes: [Size], in offered: ProposedViewSize) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let largest = sizes.reduce(Size.zero) { Size(width: max($0.width, $1.width), height: max($0.height, $1.height)) }
        let radius = max(0, self.radius ?? fittedRadius(count: sizes.count, largest: largest, offered: offered))
        let frames = sizes.enumerated().map { index, itemSize in
            let angle = angle(ofSubviewAt: index, count: sizes.count).radians
            let point = Point(x: cos(angle) * radius, y: sin(angle) * radius)
            return Rect(origin: point - itemSize / 2, size: itemSize)
        }
        let minX = frames.map(\.minX).min()!, minY = frames.map(\.minY).min()!
        let maxX = frames.map(\.maxX).max()!, maxY = frames.map(\.maxY).max()!
        let shifted = frames.map { $0.offsetBy(dx: -minX, dy: -minY) }
        return (shifted, Size(width: maxX - minX, height: maxY - minY))
    }
}
