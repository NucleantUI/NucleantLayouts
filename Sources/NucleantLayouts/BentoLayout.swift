//
//  BentoLayout.swift
//  NucleantLayouts
//

import NucleantUI

/// How many columns and rows a subview of a `BentoLayout` covers.
struct BentoSpan: Equatable, Sendable {
    var columns: Int
    var rows: Int
}

struct BentoSpanKey: LayoutValueKey {
    static let defaultValue = BentoSpan(columns: 1, rows: 1)
}

extension View {
    /// How many columns and rows of a `BentoLayout` this view covers. Every
    /// subview covers one cell unless told otherwise.
    public func bentoSpan(columns: Int = 1, rows: Int = 1) -> some View {
        layoutValue(key: BentoSpanKey.self, value: BentoSpan(columns: columns, rows: rows))
    }
}

/// A grid of equal cells in which a subview can cover several columns and
/// rows — the tiles of a dashboard or a feature page.
///
/// ```swift
/// BentoLayout(columns: 4, spacing: 12) {
///     Revenue().bentoSpan(columns: 2, rows: 2)
///     Visitors()
///     Signups()
///     Activity().bentoSpan(columns: 2)
/// }
/// ```
///
/// Each subview takes the first place, row by row from the top, where its
/// span fits — so a small one later on fills a gap left earlier rather
/// than leaving it empty. A span wider than the grid is cut to its
/// columns. Each subview is offered its whole span, so it should be
/// flexible: a `Color`, a card with a `maxWidth` and `maxHeight`.
///
/// Columns share the width offered; offered none, they are `rowHeight`
/// wide (100 without one). Rows are `rowHeight` tall, or as tall as a
/// column is wide when it is `nil`.
public struct BentoLayout: Layout {
    public var columns: Int
    /// Between cells; `nil` is the gap the subviews ask for.
    public var spacing: Double?
    /// Each row's height; `nil` makes cells square.
    public var rowHeight: Double?

    public init(columns: Int = 4, spacing: Double? = nil, rowHeight: Double? = nil) {
        self.columns = columns
        self.spacing = spacing
        self.rowHeight = rowHeight
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let gaps = gaps(subviews)
        return arrangement(of: subviews.map { $0[BentoSpanKey.self] }, cell: cell(width: proposal.width, gap: gaps.width), gaps: gaps).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let gaps = gaps(subviews)
        let arrangement = arrangement(
            of: subviews.map { $0[BentoSpanKey.self] },
            cell: cell(width: bounds.width, gap: gaps.width),
            gaps: gaps
        )
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

    /// One cell: an even share of `width`, `rowHeight` tall.
    private func cell(width: Double?, gap: Double) -> Size {
        let cellWidth: Double
        if let width, width.isFinite {
            cellWidth = max(0, (width - gap * Double(columnCount - 1)) / Double(columnCount))
        } else {
            cellWidth = rowHeight ?? 100
        }
        return Size(width: cellWidth, height: rowHeight ?? cellWidth)
    }

    /// Where each span goes: its top-leading cell's column and row.
    func placements(of spans: [BentoSpan]) -> [(column: Int, row: Int)] {
        var taken: [[Bool]] = []
        func isFree(column: Int, row: Int, span: BentoSpan) -> Bool {
            for r in row..<(row + span.rows) where r < taken.count {
                for c in column..<(column + span.columns) where taken[r][c] { return false }
            }
            return true
        }
        return spans.map { span in
            let span = clamped(span)
            var row = 0
            while true {
                for column in 0...(columnCount - span.columns) where isFree(column: column, row: row, span: span) {
                    while taken.count < row + span.rows {
                        taken.append([Bool](repeating: false, count: columnCount))
                    }
                    for r in row..<(row + span.rows) {
                        for c in column..<(column + span.columns) { taken[r][c] = true }
                    }
                    return (column, row)
                }
                row += 1
            }
        }
    }

    private func clamped(_ span: BentoSpan) -> BentoSpan {
        BentoSpan(columns: min(max(1, span.columns), columnCount), rows: max(1, span.rows))
    }

    /// Each subview's frame from the layout's top-leading corner, and the
    /// layout's size.
    func arrangement(of spans: [BentoSpan], cell: Size, gaps: Size) -> (frames: [Rect], size: Size) {
        guard !spans.isEmpty else { return ([], .zero) }
        var rows = 0
        let frames = zip(spans, placements(of: spans)).map { span, place in
            let span = clamped(span)
            rows = max(rows, place.row + span.rows)
            return Rect(
                x: Double(place.column) * (cell.width + gaps.width),
                y: Double(place.row) * (cell.height + gaps.height),
                width: Double(span.columns) * cell.width + Double(span.columns - 1) * gaps.width,
                height: Double(span.rows) * cell.height + Double(span.rows - 1) * gaps.height
            )
        }
        let size = Size(
            width: Double(columnCount) * cell.width + Double(columnCount - 1) * gaps.width,
            height: Double(rows) * cell.height + Double(rows - 1) * gaps.height
        )
        return (frames, size)
    }
}
