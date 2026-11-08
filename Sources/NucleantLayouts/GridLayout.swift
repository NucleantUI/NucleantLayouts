//
//  GridLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// Subviews in rows of `columns`, filled left to right, top to bottom.
///
/// ```swift
/// GridLayout(columns: 4, horizontalSpacing: 12, verticalSpacing: 12) {
///     ForEach(photos) { photo in
///         Thumbnail(photo)
///     }
/// }
/// ```
///
/// Each column is as wide as its widest cell and each row as tall as its
/// tallest, and a smaller cell sits in its slot by `alignment`. Offered a
/// width (or height), the grid shares it out evenly between the columns
/// (or rows), so a flexible cell — a `Color`, a view with a `maxWidth` —
/// fills its share. A `nil` spacing is the gap the cells ask for.
public struct GridLayout: Layout {
    public var columns: Int
    /// Where a cell smaller than its slot sits in it.
    public var alignment: Alignment
    public var horizontalSpacing: Double?
    public var verticalSpacing: Double?

    public init(
        columns: Int = 3,
        alignment: Alignment = .center,
        horizontalSpacing: Double? = nil,
        verticalSpacing: Double? = nil
    ) {
        self.columns = columns
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let gaps = gaps(subviews)
        return arrangement(of: cellSizes(subviews, proposal: proposal, gaps: gaps), gaps: gaps).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let gaps = gaps(subviews)
        let sizes = cellSizes(subviews, proposal: ProposedViewSize(bounds.size), gaps: gaps)
        let arrangement = arrangement(of: sizes, gaps: gaps)
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: bounds.origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    private var columnCount: Int { max(1, columns) }

    private func gaps(_ subviews: Subviews) -> Size {
        Size(
            width: horizontalSpacing ?? subviews.widestGap(along: .horizontal),
            height: verticalSpacing ?? subviews.widestGap(along: .vertical)
        )
    }

    /// Every cell measured at its even share of what was offered.
    private func cellSizes(_ subviews: Subviews, proposal: ProposedViewSize, gaps: Size) -> [Size] {
        let columns = min(columnCount, max(1, subviews.count))
        let rows = (subviews.count + columnCount - 1) / columnCount
        func share(_ length: Double?, _ count: Int, _ gap: Double) -> Double? {
            guard let length, length.isFinite, count > 0 else { return nil }
            return max(0, (length - gap * Double(count - 1)) / Double(count))
        }
        let cell = ProposedViewSize(
            width: share(proposal.width, columns, gaps.width),
            height: share(proposal.height, rows, gaps.height)
        )
        return subviews.map { $0.sizeThatFits(cell) }
    }

    /// Each cell's frame from the grid's top-leading corner, and the grid's
    /// size.
    func arrangement(of sizes: [Size], gaps: Size) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let columns = min(columnCount, sizes.count)
        let rows = (sizes.count + columns - 1) / columns

        var widths = [Double](repeating: 0, count: columns)
        var heights = [Double](repeating: 0, count: rows)
        for (index, size) in sizes.enumerated() {
            widths[index % columns] = max(widths[index % columns], size.width)
            heights[index / columns] = max(heights[index / columns], size.height)
        }

        var xs = [Double](repeating: 0, count: columns)
        for column in 1..<max(1, columns) {
            xs[column] = xs[column - 1] + widths[column - 1] + gaps.width
        }
        var ys = [Double](repeating: 0, count: rows)
        for row in 1..<max(1, rows) {
            ys[row] = ys[row - 1] + heights[row - 1] + gaps.height
        }

        let frames = sizes.enumerated().map { index, size in
            let column = index % columns, row = index / columns
            let slot = Rect(x: xs[column], y: ys[row], width: widths[column], height: heights[row])
            return alignment.position(size, in: slot)
        }
        let size = Size(
            width: xs[columns - 1] + widths[columns - 1],
            height: ys[rows - 1] + heights[rows - 1]
        )
        return (frames, size)
    }
}
