//
//  PyramidLayout.swift
//  NucleantLayouts
//

import NucleantUI

/// Subviews in centred rows of one, two, three and so on — a pyramid, or
/// stood on its point, a funnel.
///
/// ```swift
/// PyramidLayout(spacing: 6) {
///     ForEach(pins) { pin in
///         Circle().fill(.white).frame(width: 24, height: 24)
///     }
/// }
/// ```
///
/// The last row takes what is left over, centred. `inverted` turns the
/// whole pyramid upside down, so the first subview is at the bottom point.
/// Every subview has a cell as big as the largest one.
///
/// Offered space, flexible subviews — a `Color`, a `Circle` — are offered
/// the biggest square with which the pyramid fits in it.
public struct PyramidLayout: Layout {
    /// Between neighbours and rows; `nil` is the gap the subviews ask for.
    public var spacing: Double?
    /// Point down instead of up.
    public var inverted: Bool

    public init(spacing: Double? = nil, inverted: Bool = false) {
        self.spacing = spacing
        self.inverted = inverted
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

    /// How many subviews are in each row, top row first, for `count`.
    static func rows(for count: Int) -> [Int] {
        var rows: [Int] = []
        var left = count
        while left > 0 {
            let row = min(rows.count + 1, left)
            rows.append(row)
            left -= row
        }
        return rows
    }

    /// The biggest square with which the pyramid fits in `offered`;
    /// unspecified when nothing is offered.
    func itemProposal(count: Int, offered: ProposedViewSize, gap: Double) -> ProposedViewSize {
        guard count > 0 else { return .unspecified }
        let rows = Self.rows(for: count)
        let widest = Double(rows.max()!), tall = Double(rows.count)
        var limits: [Double] = []
        if let width = offered.width, width.isFinite {
            limits.append((width - gap * (widest - 1)) / widest)
        }
        if let height = offered.height, height.isFinite {
            limits.append((height - gap * (tall - 1)) / tall)
        }
        guard let side = limits.min() else { return .unspecified }
        return ProposedViewSize(width: max(0, side), height: max(0, side))
    }

    /// Each subview's frame from the top-leading corner of the pyramid's
    /// box, and the box's size.
    func arrangement(of sizes: [Size], gap: Double) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let cell = sizes.reduce(Size.zero) { Size(width: max($0.width, $1.width), height: max($0.height, $1.height)) }
        let rows = Self.rows(for: sizes.count)
        let widest = Double(rows.max()!)
        let size = Size(
            width: widest * cell.width + (widest - 1) * gap,
            height: Double(rows.count) * cell.height + Double(rows.count - 1) * gap
        )
        var frames: [Rect] = []
        var index = 0
        for (row, count) in rows.enumerated() {
            let rowWidth = Double(count) * cell.width + Double(count - 1) * gap
            let line = inverted ? rows.count - 1 - row : row
            let y = Double(line) * (cell.height + gap)
            for slot in 0..<count {
                let x = (size.width - rowWidth) / 2 + Double(slot) * (cell.width + gap)
                let itemSize = sizes[index]
                // Centred in its cell.
                frames.append(Rect(origin: Point(x: x, y: y) + (cell - itemSize) / 2, size: itemSize))
                index += 1
            }
        }
        return (frames, size)
    }
}
