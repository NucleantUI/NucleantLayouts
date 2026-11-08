//
//  FlowLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// Subviews left to right, wrapping onto a new line when the next one
/// wouldn't fit — tags, chips, words.
///
/// ```swift
/// FlowLayout(alignment: .center, spacing: 6, lineSpacing: 6) {
///     ForEach(tags, id: \.self) { tag in
///         TagChip(tag)
///     }
/// }
/// ```
///
/// Offered a width, the flow takes all of it and lines up each line in it
/// by `alignment`; offered none, it is one line. Each subview is centred on
/// its line, and one too wide for any line gets a line of its own at the
/// width. A `nil` spacing is the gap the subviews ask for.
public struct FlowLayout: Layout {
    /// Where each line sits across the width.
    public var alignment: HorizontalAlignment
    /// Between subviews on a line.
    public var spacing: Double?
    /// Between lines.
    public var lineSpacing: Double?

    public init(alignment: HorizontalAlignment = .leading, spacing: Double? = nil, lineSpacing: Double? = nil) {
        self.alignment = alignment
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        return arrangement(of: sizes(subviews, width: width), width: width, gaps: gaps(subviews)).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrangement(of: sizes(subviews, width: bounds.width), width: bounds.width, gaps: gaps(subviews))
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: bounds.origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    private func gaps(_ subviews: Subviews) -> Size {
        Size(
            width: spacing ?? subviews.widestGap(along: .horizontal),
            height: lineSpacing ?? subviews.widestGap(along: .vertical)
        )
    }

    /// Each subview at its own size, or at `width` if it is wider.
    private func sizes(_ subviews: Subviews, width: Double?) -> [Size] {
        subviews.map { subview in
            let size = subview.sizeThatFits(.unspecified)
            guard let width, size.width > width else { return size }
            return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
        }
    }

    /// Each subview's frame from the flow's top-leading corner, and the
    /// flow's size. `width` nil is no wrapping.
    func arrangement(of sizes: [Size], width: Double?, gaps: Size) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], Size(width: width ?? 0, height: 0)) }
        let limit = width ?? .infinity

        // Break into lines: the indices on each, and how wide and tall it is.
        var lines: [(range: Range<Int>, width: Double, height: Double)] = []
        var start = 0, lineWidth = 0.0, lineHeight = 0.0
        for (index, size) in sizes.enumerated() {
            let widened = index == start ? size.width : lineWidth + gaps.width + size.width
            // Half a point of slack, so a flow offered exactly the width it
            // asked for doesn't break a line over a rounding error.
            if widened > limit + 0.5, index > start {
                lines.append((start..<index, lineWidth, lineHeight))
                start = index
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth = widened
                lineHeight = max(lineHeight, size.height)
            }
        }
        lines.append((start..<sizes.count, lineWidth, lineHeight))

        let containerWidth = width ?? lines.map(\.width).max() ?? 0
        var frames = [Rect](repeating: .zero, count: sizes.count)
        var y = 0.0
        for line in lines {
            var x: Double
            switch alignment {
            case .leading:  x = 0
            case .center:   x = (containerWidth - line.width) / 2
            case .trailing: x = containerWidth - line.width
            }
            for index in line.range {
                let size = sizes[index]
                frames[index] = Rect(x: x, y: y + (line.height - size.height) / 2, width: size.width, height: size.height)
                x += size.width + gaps.width
            }
            y += line.height + gaps.height
        }
        return (frames, Size(width: containerWidth, height: y - gaps.height))
    }
}
