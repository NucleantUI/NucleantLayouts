//
//  MasonryLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// Columns of one width, each subview dropped into whichever column is
/// shortest so far — a Pinterest-style wall of cards of different heights.
///
/// ```swift
/// MasonryLayout(columns: 3, spacing: 10) {
///     ForEach(pins) { pin in
///         PinCard(pin)
///     }
/// }
/// ```
///
/// Offered a width, the columns share it out; offered none, each column is
/// as wide as the widest subview. Every subview is offered the column width
/// and chooses its own height. A `nil` spacing is the gap the subviews ask
/// for.
public struct MasonryLayout: Layout {
    public var columns: Int
    /// Between columns, and between subviews in a column.
    public var spacing: Double?

    public init(columns: Int = 3, spacing: Double? = nil) {
        self.columns = columns
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let gaps = gaps(subviews)
        let width = columnWidth(subviews, offered: proposal.width, gap: gaps.width)
        return arrangement(of: heights(subviews, width: width), columnWidth: width, gaps: gaps).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let gaps = gaps(subviews)
        let width = columnWidth(subviews, offered: bounds.width, gap: gaps.width)
        let arrangement = arrangement(of: heights(subviews, width: width), columnWidth: width, gaps: gaps)
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: bounds.origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    private var columnCount: Int { max(1, columns) }

    private func gaps(_ subviews: Subviews) -> Size {
        Size(
            width: spacing ?? subviews.widestGap(along: .horizontal),
            height: spacing ?? subviews.widestGap(along: .vertical)
        )
    }

    private func columnWidth(_ subviews: Subviews, offered: Double?, gap: Double) -> Double {
        if let offered, offered.isFinite {
            return max(0, (offered - gap * Double(columnCount - 1)) / Double(columnCount))
        }
        return subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
    }

    private func heights(_ subviews: Subviews, width: Double) -> [Double] {
        subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }
    }

    /// Each subview's frame from the wall's top-leading corner, and the
    /// wall's size.
    func arrangement(of heights: [Double], columnWidth: Double, gaps: Size) -> (frames: [Rect], size: Size) {
        var tops = [Double](repeating: 0, count: columnCount)
        let frames = heights.map { height in
            // The shortest column; the leftmost of equals.
            let column = tops.indices.min { tops[$0] < tops[$1] } ?? 0
            let frame = Rect(
                x: Double(column) * (columnWidth + gaps.width),
                y: tops[column],
                width: columnWidth,
                height: height
            )
            tops[column] += height + gaps.height
            return frame
        }
        let width = Double(columnCount) * columnWidth + Double(columnCount - 1) * gaps.width
        let height = heights.isEmpty ? 0 : (tops.max() ?? 0) - gaps.height
        return (frames, Size(width: width, height: height))
    }
}
