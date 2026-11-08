//
//  RingsLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// One subview in the middle and the rest in rings round it: 6 in the
/// first ring, 12 in the second, 18 in the third, and so on.
///
/// ```swift
/// RingsLayout(spacing: 8) {
///     ForEach(team) { member in
///         Avatar(member)
///     }
/// }
/// ```
///
/// The outermost ring takes what is left over and spreads it evenly round
/// itself. Rings are one subview apart, measured along a diagonal, so
/// square subviews clear each other however the rings are turned.
///
/// `twist` turns the rings alternately — the first by `twist`, the second
/// back by as much, the third forward again — and it animates, so changing
/// it under `withAnimation` winds the rings against each other like a
/// combination lock.
///
/// Offered space, flexible subviews — a `Color`, a `Circle` — are offered
/// the biggest square with which every ring fits in it.
public struct RingsLayout: Layout {
    /// The least gap between subviews; `nil` is the gap they ask for.
    public var spacing: Double?
    /// How far odd rings are turned one way and even rings the other.
    public var twist: Angle

    public init(spacing: Double? = nil, twist: Angle = .zero) {
        self.spacing = spacing
        self.twist = twist
    }

    public var animatableData: Double {
        get { twist.radians }
        set { twist = .radians(newValue) }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let gap = spacing ?? subviews.widestGap(along: .horizontal)
        let item = itemProposal(count: subviews.count, offered: proposal, gap: gap)
        return arrangement(of: subviews.map { $0.sizeThatFits(item) }, gap: gap).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let gap = spacing ?? subviews.widestGap(along: .horizontal)
        let item = itemProposal(count: subviews.count, offered: ProposedViewSize(bounds.size), gap: gap)
        let arrangement = arrangement(of: subviews.map { $0.sizeThatFits(item) }, gap: gap)
        let origin = bounds.center - arrangement.size / 2
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    /// How many rings `count` subviews need round the middle one.
    static func rings(for count: Int) -> Int {
        var rings = 0
        // The middle one, then 6 in ring 1, 12 in ring 2, …: 1 + 3k(k + 1).
        while 1 + 3 * rings * (rings + 1) < count { rings += 1 }
        return rings
    }

    /// The biggest square with which every ring fits in `offered`;
    /// unspecified when nothing is offered.
    func itemProposal(count: Int, offered: ProposedViewSize, gap: Double) -> ProposedViewSize {
        let sides = [offered.width, offered.height].compactMap { $0 }.filter(\.isFinite)
        guard count > 0, let side = sides.min() else { return .unspecified }
        // Across: the outer ring's radius twice, plus one subview, where a
        // ring is √2 × (subview + gap) further out than the one inside it.
        let across = 2 * Double(Self.rings(for: count)) * 2.0.squareRoot()
        let size = (side - across * max(0, gap)) / (across + 1)
        return ProposedViewSize(width: max(0, size), height: max(0, size))
    }

    /// Each subview's frame from the top-leading corner of the box round
    /// the rings, and the box's size.
    func arrangement(of sizes: [Size], gap: Double) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let largest = sizes.reduce(Size.zero) { Size(width: max($0.width, $1.width), height: max($0.height, $1.height)) }
        // Two squares this far apart clear each other along any direction.
        let step = 2.0.squareRoot() * (max(largest.width, largest.height) + max(0, gap))
        let rings = Self.rings(for: sizes.count)
        let size = Size(width: 2 * Double(rings) * step + largest.width, height: 2 * Double(rings) * step + largest.height)
        let center = size / 2

        var points = [center]
        var ring = 1
        while points.count < sizes.count {
            let count = min(6 * ring, sizes.count - points.count)
            let radius = Double(ring) * step
            let turn = -Double.pi / 2 + twist.radians * (ring % 2 == 1 ? 1 : -1)
            for index in 0..<count {
                let angle = turn + 2 * Double.pi * Double(index) / Double(count)
                points.append(Point(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
            }
            ring += 1
        }
        let frames = zip(points, sizes).map { point, itemSize in
            Rect(origin: point - itemSize / 2, size: itemSize)
        }
        return (frames, size)
    }
}
