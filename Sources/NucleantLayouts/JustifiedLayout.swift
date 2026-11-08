//
//  JustifiedLayout.swift
//  NucleantLayouts
//

import NucleantUI

/// A subview's width over its height in a `JustifiedLayout`. Set it with
/// `justifiedAspectRatio(_:)`.
public struct JustifiedAspectRatio: LayoutValueKey {
    public static let defaultValue: Double? = nil
}

extension View {
    /// This view's width over its height in a `JustifiedLayout` — a
    /// photo's proportions. Without it, the layout uses the proportions of
    /// the size the view asks for, or a square when it asks for none.
    public func justifiedAspectRatio(_ ratio: Double) -> some View {
        layoutValue(key: JustifiedAspectRatio.self, value: ratio)
    }
}

/// Rows of subviews that each keep their proportions and together fill
/// the width exactly, like a photo library.
///
/// ```swift
/// JustifiedLayout(rowHeight: 140, spacing: 4) {
///     ForEach(photos) { photo in
///         Image(photo.name)
///             .resizable()
///             .justifiedAspectRatio(photo.width / photo.height)
///     }
/// }
/// ```
///
/// Subviews go into a row until it is full at `rowHeight`; the row then
/// grows or shrinks to the height at which it is exactly as wide as the
/// layout — ending before or after the subview that filled it, whichever
/// brings that height closer to `rowHeight`. The last row, not full, stays
/// at `rowHeight`. Each subview is offered its cell, so it should be
/// flexible: a `Color`, a resizable image.
///
/// Offered no width, every subview is on one row at `rowHeight`.
/// `rowHeight` animates.
public struct JustifiedLayout: Layout {
    /// The height rows aim for.
    public var rowHeight: Double
    /// Between neighbours and between rows; `nil` is the gap the subviews
    /// ask for.
    public var spacing: Double?

    public init(rowHeight: Double = 120, spacing: Double? = nil) {
        self.rowHeight = rowHeight
        self.spacing = spacing
    }

    public var animatableData: Double {
        get { rowHeight }
        set { rowHeight = newValue }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        arrangement(of: aspectRatios(subviews), width: proposal.width, gaps: gaps(subviews)).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrangement(of: aspectRatios(subviews), width: bounds.width, gaps: gaps(subviews))
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: bounds.origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    private func gaps(_ subviews: Subviews) -> Size {
        Size(
            width: spacing ?? subviews.widestGap(along: .horizontal),
            height: spacing ?? subviews.widestGap(along: .vertical)
        )
    }

    private func aspectRatios(_ subviews: Subviews) -> [Double] {
        subviews.map { subview in
            if let ratio = subview[JustifiedAspectRatio.self], ratio.isFinite, ratio > 0 { return ratio }
            let size = subview.sizeThatFits(.unspecified)
            guard size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else { return 1 }
            return size.width / size.height
        }
    }

    /// Each subview's frame from the layout's top-leading corner, and the
    /// layout's size.
    func arrangement(of ratios: [Double], width: Double?, gaps: Size) -> (frames: [Rect], size: Size) {
        guard !ratios.isEmpty else { return ([], .zero) }
        let target = max(1, rowHeight)
        var rows: [(range: Range<Int>, height: Double)] = []

        if let width, width.isFinite, width > 0 {
            /// The height at which `range` is exactly `width` wide.
            func fullHeight(_ range: Range<Int>) -> Double {
                let ratios = ratios[range].reduce(0, +)
                let room = width - gaps.width * Double(range.count - 1)
                return ratios > 0 ? max(0, room) / ratios : target
            }
            var start = 0
            var end = 0
            while end < ratios.count {
                end += 1
                let height = fullHeight(start..<end)
                guard height <= target else { continue }
                // Full: end here or one before, whichever is nearer the aim.
                if end - start > 1 {
                    let shorter = fullHeight(start..<(end - 1))
                    if abs(shorter - target) < abs(height - target) {
                        rows.append((start..<(end - 1), shorter))
                        start = end - 1
                        continue
                    }
                }
                rows.append((start..<end, height))
                start = end
            }
            if start < ratios.count { rows.append((start..<ratios.count, target)) }
        } else {
            rows = [(0..<ratios.count, target)]
        }

        var frames: [Rect] = []
        var y = 0.0
        var widest = 0.0
        for row in rows {
            var x = 0.0
            for index in row.range {
                let cell = ratios[index] * row.height
                frames.append(Rect(x: x, y: y, width: cell, height: row.height))
                x += cell + gaps.width
            }
            widest = max(widest, x - gaps.width)
            y += row.height + gaps.height
        }
        let size = Size(width: width.flatMap { $0.isFinite ? $0 : nil } ?? widest, height: y - gaps.height)
        return (frames, size)
    }
}
