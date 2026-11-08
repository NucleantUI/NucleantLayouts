//
//  SpiralLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// Subviews on a sunflower spiral: the first by the centre, each next one
/// turned by `divergence` and a little further out, so they spread evenly
/// over a disc.
///
/// ```swift
/// SpiralLayout(spacing: 30) {
///     ForEach(seeds) { seed in
///         Circle().fill(seed.color).frame(width: 24, height: 24)
///     }
/// }
/// ```
///
/// The n-th subview (from 0) is `spacing × √(n + ½)` from the centre. At
/// the golden angle, the default, no two line up; other angles curl the
/// subviews into arms. `divergence` animates, so changing it under
/// `withAnimation` winds the subviews from one pattern into the other. A
/// `nil` spacing is worked out from the largest subview, so neighbours
/// don't overlap.
///
/// A subview with a size of its own keeps it; a flexible one — a `Color`,
/// a `Circle` — is offered the biggest square that lets the whole spiral
/// fit in the space the layout is given.
public struct SpiralLayout: Layout {
    /// The golden angle, 137.5°.
    public static let goldenAngle = Angle.degrees(137.50776405)

    /// How far each subview is turned from the one before.
    public var divergence: Angle
    public var spacing: Double?

    public init(divergence: Angle = SpiralLayout.goldenAngle, spacing: Double? = nil) {
        self.divergence = divergence
        self.spacing = spacing
    }

    public var animatableData: Double {
        get { divergence.radians }
        set { divergence = .radians(newValue) }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let seed = seedProposal(count: subviews.count, offered: proposal)
        return arrangement(of: subviews.map { $0.sizeThatFits(seed) }).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let seed = seedProposal(count: subviews.count, offered: ProposedViewSize(bounds.size))
        let arrangement = arrangement(of: subviews.map { $0.sizeThatFits(seed) })
        let origin = bounds.center - arrangement.size / 2
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    /// A nil `spacing` is this much of the largest subview.
    private static let spacingPerSize = 0.72

    /// The biggest square with which `count` subviews of that size fit in
    /// `offered`; unspecified when nothing is offered.
    func seedProposal(count: Int, offered: ProposedViewSize) -> ProposedViewSize {
        let sides = [offered.width, offered.height].compactMap { $0 }.filter(\.isFinite)
        guard count > 0, let side = sides.min() else { return .unspecified }
        // The outermost is `spacing × turns` out, plus half its own size.
        let turns = (Double(count - 1) + 0.5).squareRoot()
        let size: Double
        if let spacing {
            size = side - 2 * max(0, spacing) * turns
        } else {
            size = side / (2 * (Self.spacingPerSize * turns + 0.5))
        }
        return ProposedViewSize(width: max(0, size), height: max(0, size))
    }

    /// Each subview's frame from the top-leading corner of a square round
    /// the spiral, and the square's size.
    func arrangement(of sizes: [Size]) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let largest = sizes.reduce(0.0) { max($0, $1.width, $1.height) }
        let spacing = max(0, self.spacing ?? largest * Self.spacingPerSize)
        let reach = distance(of: sizes.count - 1, spacing: spacing) + largest / 2
        let size = Size(width: reach * 2, height: reach * 2)
        let center = size / 2
        let frames = sizes.enumerated().map { index, itemSize in
            let distance = distance(of: index, spacing: spacing)
            let angle = divergence.radians * Double(index)
            let point = Point(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            return Rect(origin: point - itemSize / 2, size: itemSize)
        }
        return (frames, size)
    }

    /// How far the subview at `index` is from the centre. Half a step out,
    /// so the first few don't crowd onto the centre and each other: at
    /// exactly √n the first sits on the centre and the second only one
    /// `spacing` from it, closer than neighbours anywhere else on the disc.
    private func distance(of index: Int, spacing: Double) -> Double {
        spacing * (Double(index) + 0.5).squareRoot()
    }
}
