//
//  CascadeLayout.swift
//  NucleantLayouts
//

import NucleantUI

/// Subviews stacked like cascaded windows or a dealt deck: each one moved
/// right and down from the one before, and drawn over it.
///
/// ```swift
/// CascadeLayout(horizontalOffset: 24, verticalOffset: 18) {
///     ForEach(documents) { document in
///         DocumentCard(document)
///     }
/// }
/// ```
///
/// Negative offsets cascade left or up instead. Both animate: from zero
/// the subviews sit squarely on each other, a single pile, and growing the
/// offsets under `withAnimation` deals them out.
///
/// Offered space, a flexible subview — a `Color`, a card with a
/// `maxWidth` — is offered what is left once the cascade's offsets are
/// taken out of it, so the whole pile fills the space.
public struct CascadeLayout: Layout {
    /// How far each subview is moved right of the one before.
    public var horizontalOffset: Double
    /// How far each subview is moved down from the one before.
    public var verticalOffset: Double

    public init(horizontalOffset: Double = 24, verticalOffset: Double = 24) {
        self.horizontalOffset = horizontalOffset
        self.verticalOffset = verticalOffset
    }

    public var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(horizontalOffset, verticalOffset) }
        set {
            horizontalOffset = newValue.first
            verticalOffset = newValue.second
        }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let item = itemProposal(count: subviews.count, offered: proposal)
        return arrangement(of: subviews.map { $0.sizeThatFits(item) }).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let item = itemProposal(count: subviews.count, offered: ProposedViewSize(bounds.size))
        let arrangement = arrangement(of: subviews.map { $0.sizeThatFits(item) })
        let origin = bounds.center - arrangement.size / 2
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    /// What is left of `offered` along each axis once the offsets are
    /// taken out; an axis offered nothing stays unspecified.
    func itemProposal(count: Int, offered: ProposedViewSize) -> ProposedViewSize {
        let steps = Double(max(0, count - 1))
        func left(_ length: Double?, _ offset: Double) -> Double? {
            guard let length, length.isFinite else { return nil }
            return max(0, length - abs(offset) * steps)
        }
        return ProposedViewSize(
            width: left(offered.width, horizontalOffset),
            height: left(offered.height, verticalOffset)
        )
    }

    /// Each subview's frame from the top-leading corner of the box round
    /// the cascade, and the box's size.
    func arrangement(of sizes: [Size]) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let frames = sizes.enumerated().map { index, itemSize in
            Rect(
                x: horizontalOffset * Double(index),
                y: verticalOffset * Double(index),
                width: itemSize.width,
                height: itemSize.height
            )
        }
        let minX = frames.map(\.minX).min()!, minY = frames.map(\.minY).min()!
        let maxX = frames.map(\.maxX).max()!, maxY = frames.map(\.maxY).max()!
        let shifted = frames.map { $0.offsetBy(dx: -minX, dy: -minY) }
        return (shifted, Size(width: maxX - minX, height: maxY - minY))
    }
}
