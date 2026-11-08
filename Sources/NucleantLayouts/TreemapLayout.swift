//
//  TreemapLayout.swift
//  NucleantLayouts
//

import NucleantUI

/// How much of a `TreemapLayout` a subview takes, against the others. Set
/// it with `treemapWeight(_:)`.
public struct TreemapWeight: LayoutValueKey {
    public static let defaultValue = 1.0
}

extension View {
    /// The share of a `TreemapLayout` this view takes: its area against the
    /// others' is its weight against theirs. Every subview weighs 1 unless
    /// told otherwise.
    public func treemapWeight(_ weight: Double) -> some View {
        layoutValue(key: TreemapWeight.self, value: weight)
    }
}

/// Subviews that tile the whole space, each with an area in proportion to
/// its weight — disk usage, a budget, a portfolio.
///
/// ```swift
/// TreemapLayout(spacing: 2) {
///     ForEach(folders) { folder in
///         FolderTile(folder)
///             .treemapWeight(folder.bytes)
///     }
/// }
/// ```
///
/// Cells are laid out squarified (Bruls, Huizing and van Wijk), heaviest
/// first: each strip along the shorter side takes subviews as long as that
/// keeps its cells closer to square, so cells stay near square rather than
/// thin slivers. Each subview is offered its cell; one of a size of its own
/// is centred in it.
///
/// The layout takes the space it is offered. Offered only a width or a
/// height, it is square; offered neither, it is the square whose area is
/// what its subviews ask for.
public struct TreemapLayout: Layout {
    /// Between neighbouring cells; `nil` is the gap the subviews ask for.
    public var spacing: Double?

    public init(spacing: Double? = nil) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        region(offered: proposal, subviews: subviews)
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let gap = spacing ?? subviews.widestGap(along: .horizontal)
        let frames = arrangement(weights: subviews.map { $0[TreemapWeight.self] }, in: bounds.size, gap: gap)
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: bounds.origin + frame.center,
                anchor: .center,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    /// The space offered, square along an axis offered nothing.
    private func region(offered: ProposedViewSize, subviews: Subviews) -> Size {
        let width = offered.width.flatMap { $0.isFinite ? $0 : nil }
        let height = offered.height.flatMap { $0.isFinite ? $0 : nil }
        if let width, let height { return Size(width: width, height: height) }
        if let side = width ?? height { return Size(width: side, height: side) }
        let area = subviews.reduce(0.0) { total, subview in
            let size = subview.sizeThatFits(.unspecified)
            return total + size.width * size.height
        }
        return Size(width: area.squareRoot(), height: area.squareRoot())
    }

    /// Each weight's cell in a box of `size`, cells `gap` apart and flush
    /// with the box's edges.
    func arrangement(weights: [Double], in size: Size, gap: Double) -> [Rect] {
        guard !weights.isEmpty else { return [] }
        let gap = max(0, gap)
        var weights = weights.map { $0.isFinite ? max(0, $0) : 0 }
        if weights.allSatisfy({ $0 == 0 }) { weights = weights.map { _ in 1 } }

        // Lay out in a box one gap bigger, then take half a gap off every
        // side of every cell: neighbours end a gap apart, edges flush.
        let box = Rect(x: 0, y: 0, width: max(0, size.width) + gap, height: max(0, size.height) + gap)
        let scale = box.width * box.height / weights.reduce(0, +)
        let areas = weights.map { $0 * scale }
        let order = areas.indices.sorted { areas[$0] != areas[$1] ? areas[$0] > areas[$1] : $0 < $1 }

        var cells = [Rect](repeating: .zero, count: areas.count)
        var remaining = box
        var row: [Int] = []

        /// The longest-to-shortest side of the worst cell in a strip of
        /// these areas along `side`.
        func worst(_ row: [Int], along side: Double) -> Double {
            let total = row.reduce(0) { $0 + areas[$1] }
            guard total > 0, side > 0 else { return .infinity }
            let largest = row.map { areas[$0] }.max()!
            let smallest = row.map { areas[$0] }.min()!
            guard smallest > 0 else { return .infinity }
            return max(side * side * largest / (total * total), total * total / (side * side * smallest))
        }

        /// Lays `row` out as a strip along the shorter side of `remaining`
        /// and takes the strip off it.
        func place(_ row: [Int]) {
            let total = row.reduce(0) { $0 + areas[$1] }
            if remaining.width >= remaining.height {
                // A column down the leading side.
                let thickness = remaining.height > 0 ? total / remaining.height : 0
                var y = remaining.minY
                for index in row {
                    let length = thickness > 0 ? areas[index] / thickness : 0
                    cells[index] = Rect(x: remaining.minX, y: y, width: thickness, height: length)
                    y += length
                }
                remaining = Rect(
                    x: remaining.minX + thickness, y: remaining.minY,
                    width: max(0, remaining.width - thickness), height: remaining.height
                )
            } else {
                // A row along the top.
                let thickness = remaining.width > 0 ? total / remaining.width : 0
                var x = remaining.minX
                for index in row {
                    let length = thickness > 0 ? areas[index] / thickness : 0
                    cells[index] = Rect(x: x, y: remaining.minY, width: length, height: thickness)
                    x += length
                }
                remaining = Rect(
                    x: remaining.minX, y: remaining.minY + thickness,
                    width: remaining.width, height: max(0, remaining.height - thickness)
                )
            }
        }

        for index in order {
            let side = min(remaining.width, remaining.height)
            if row.isEmpty || worst(row + [index], along: side) <= worst(row, along: side) {
                row.append(index)
            } else {
                place(row)
                row = [index]
            }
        }
        if !row.isEmpty { place(row) }

        return cells.map { cell in
            Rect(
                x: cell.minX,
                y: cell.minY,
                width: max(0, cell.width - gap),
                height: max(0, cell.height - gap)
            )
        }
    }
}
