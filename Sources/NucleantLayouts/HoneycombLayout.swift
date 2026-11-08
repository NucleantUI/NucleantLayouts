//
//  HoneycombLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// Subviews in interlocking rows, like the cells of a honeycomb: every
/// other row has one cell fewer and is pushed in by half a cell, and rows
/// overlap by a quarter of a cell's height, so pointy-top hexagons fit
/// together.
///
/// ```swift
/// HoneycombLayout(columns: 3) {
///     ForEach(colors, id: \.self) { color in
///         color.clipShape(Hexagon())
///     }
/// }
/// ```
///
/// The rows overlap, so the subviews should be hexagons — a `Hexagon`
/// shape, or anything clipped to one; plain rectangles overlap by that
/// quarter.
///
/// Every cell is the size of the largest subview. A subview with a size of
/// its own keeps it; a flexible one — a `Color`, a shape — is offered the
/// biggest hexagon cell that lets the whole comb fit in the space the
/// layout is given. `spacing` is the gap between neighbouring cells, and
/// animates.
public struct HoneycombLayout: Layout {
    /// Cells on the long rows; the rows between have one fewer.
    public var columns: Int
    public var spacing: Double

    public init(columns: Int = 5, spacing: Double = 4) {
        self.columns = columns
        self.spacing = spacing
    }

    public var animatableData: Double {
        get { spacing }
        set { spacing = newValue }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        arrangement(count: subviews.count, cell: cell(subviews, offered: proposal)).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrangement(count: subviews.count, cell: cell(subviews, offered: ProposedViewSize(bounds.size)))
        let origin = bounds.center - arrangement.size / 2
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    /// The largest subview, each offered the cell that fits in `offered`.
    private func cell(_ subviews: Subviews, offered: ProposedViewSize) -> Size {
        let proposal = cellProposal(count: subviews.count, offered: offered)
        return subviews.reduce(Size.zero) { largest, subview in
            let size = subview.sizeThatFits(proposal)
            return Size(width: max(largest.width, size.width), height: max(largest.height, size.height))
        }
    }

    private var long: Int { max(1, columns) }
    private var short: Int { max(1, long - 1) }

    /// How many cells each row holds, and whether it is a short row.
    private func rows(count: Int) -> [(cells: Int, isShort: Bool)] {
        var rows: [(cells: Int, isShort: Bool)] = []
        var placed = 0
        while placed < count {
            let isShort = !rows.count.isMultiple(of: 2)
            let cells = min(isShort ? short : long, count - placed)
            rows.append((cells, isShort))
            placed += cells
        }
        return rows
    }

    private func rowStep(cellHeight: Double) -> Double {
        cellHeight * 0.75 + spacing * 0.866
    }

    /// The biggest hexagon cell — `Hexagon.heightPerWidth` as tall as it is
    /// wide — with which `count` cells fit in `offered`; unspecified when
    /// nothing is offered.
    func cellProposal(count: Int, offered: ProposedViewSize) -> ProposedViewSize {
        guard count > 0 else { return .unspecified }
        let rows = rows(count: count)
        var width = Double.infinity
        if let offeredWidth = offered.width, offeredWidth.isFinite {
            // A row is `cells` steps of a cell and a gap, less the last gap,
            // and half a step more when it is pushed in.
            let steps = rows.map { Double($0.cells) + ($0.isShort ? 0.5 : 0) }.max() ?? 1
            width = (offeredWidth + spacing) / steps - spacing
        }
        if let offeredHeight = offered.height, offeredHeight.isFinite {
            let between = Double(rows.count - 1)
            let height = (offeredHeight - between * spacing * 0.866) / (between * 0.75 + 1)
            width = min(width, height / Hexagon.heightPerWidth)
        }
        guard width.isFinite else { return .unspecified }
        let cellWidth = max(0, width)
        return ProposedViewSize(width: cellWidth, height: cellWidth * Hexagon.heightPerWidth)
    }

    /// Each cell's frame from the comb's top-leading corner, and the comb's
    /// size.
    func arrangement(count: Int, cell: Size) -> (frames: [Rect], size: Size) {
        guard count > 0 else { return ([], .zero) }
        let step = Size(width: cell.width + spacing, height: rowStep(cellHeight: cell.height))
        let rows = rows(count: count)

        var frames: [Rect] = []
        var width = 0.0
        for (index, row) in rows.enumerated() {
            let inset = row.isShort ? step.width / 2 : 0
            for column in 0..<row.cells {
                frames.append(Rect(
                    x: inset + Double(column) * step.width,
                    y: Double(index) * step.height,
                    width: cell.width,
                    height: cell.height
                ))
            }
            width = max(width, inset + Double(row.cells - 1) * step.width + cell.width)
        }
        return (frames, Size(width: width, height: Double(rows.count - 1) * step.height + cell.height))
    }
}
