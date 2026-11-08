//
//  EqualWidthHStack.swift
//  NucleantLayouts
//

import NucleantUI

/// A row in which every subview is as wide as the widest one wants to be —
/// a row of buttons that line up whatever their titles.
///
/// ```swift
/// EqualWidthHStack {
///     Button("OK") { … }
///     Button("Cancel") { … }
///     Button("Don't Save") { … }
/// }
/// ```
///
/// Every subview is offered the width the widest asks for, and the row's
/// height. Offered less width than that, they share what there is evenly
/// instead. Subviews that ask for no width of their own — a `Color` — share
/// the offered width. A subview shorter than the row sits in it by
/// `alignment`.
public struct EqualWidthHStack: Layout {
    public var alignment: VerticalAlignment
    /// Between neighbours; `nil` is the gap each pair asks for.
    public var spacing: Double?

    public init(alignment: VerticalAlignment = .center, spacing: Double? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let gaps = gaps(subviews)
        let width = cellWidth(subviews, offered: proposal.width, gaps: gaps)
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: proposal.height)) }
        return arrangement(of: sizes, cellWidth: width, gaps: gaps).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let gaps = gaps(subviews)
        let width = cellWidth(subviews, offered: bounds.width, gaps: gaps)
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: bounds.height)) }
        let arrangement = arrangement(of: sizes, cellWidth: width, gaps: gaps)
        let origin = Point(x: bounds.midX - arrangement.size.width / 2, y: bounds.minY)
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    /// The gap after each subview but the last.
    private func gaps(_ subviews: Subviews) -> [Double] {
        guard subviews.count > 1 else { return [] }
        return (0..<(subviews.count - 1)).map { index in
            spacing ?? subviews[index].spacing.distance(to: subviews[index + 1].spacing, along: .horizontal)
        }
    }

    /// The widest ideal width, no more than an even share of `offered`.
    private func cellWidth(_ subviews: Subviews, offered: Double?, gaps: [Double]) -> Double {
        guard !subviews.isEmpty else { return 0 }
        let widest = subviews.reduce(0.0) { max($0, $1.sizeThatFits(.unspecified).width) }
        guard let offered, offered.isFinite else { return widest }
        let share = max(0, (offered - gaps.reduce(0, +)) / Double(subviews.count))
        return widest > 0 ? min(widest, share) : share
    }

    /// Each subview's frame from the row's top-leading corner, and the
    /// row's size.
    func arrangement(of sizes: [Size], cellWidth: Double, gaps: [Double]) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let height = sizes.reduce(0) { max($0, $1.height) }
        let place = Alignment(horizontal: .center, vertical: alignment)
        var x = 0.0
        let frames = sizes.enumerated().map { index, size in
            let slot = Rect(x: x, y: 0, width: cellWidth, height: height)
            x += cellWidth + (index < gaps.count ? gaps[index] : 0)
            return place.position(Size(width: cellWidth, height: size.height), in: slot)
        }
        return (frames, Size(width: x, height: height))
    }
}
