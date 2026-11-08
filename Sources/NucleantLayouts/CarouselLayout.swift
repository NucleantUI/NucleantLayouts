//
//  CarouselLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// A row centred on the selected subview, which is the biggest; the
/// further a subview is from it, the smaller.
///
/// ```swift
/// CarouselLayout(selection: selected) {
///     ForEach(albums.indices, id: \.self) { index in
///         AlbumCover(albums[index])
///             .onTapGesture { withAnimation { selected = index } }
///     }
/// }
/// ```
///
/// Each step away from the selection, a subview is `falloff` times the
/// size of the one before it. `selection` animates: changing it under
/// `withAnimation` slides the row along and grows the new selection as
/// the old one shrinks. Subviews past the layout's edges are still placed,
/// outside them.
///
/// The selected subview is offered a square as tall as the space and no
/// wider than half of it; the others, that square scaled down. A subview
/// with a size of its own keeps it. Offered a width, the layout takes it.
public struct CarouselLayout: Layout {
    /// The index of the subview in the middle. Between two indices while
    /// animating from one to the other.
    public var selection: Double
    /// Between neighbours.
    public var spacing: Double
    /// How much smaller each step away from the selection makes a subview.
    public var falloff: Double

    public init(selection: Int = 0, spacing: Double = 16, falloff: Double = 0.75) {
        self.selection = Double(selection)
        self.spacing = spacing
        self.falloff = falloff
    }

    public var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(selection, falloff) }
        set {
            selection = newValue.first
            falloff = newValue.second
        }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> Size {
        let sizes = measure(subviews, offered: proposal)
        return arrangement(of: sizes, width: proposal.width).size
    }

    public func placeSubviews(in bounds: Rect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = measure(subviews, offered: ProposedViewSize(bounds.size))
        let arrangement = arrangement(of: sizes, width: bounds.width)
        let origin = Point(x: bounds.minX, y: bounds.midY - arrangement.size.height / 2)
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(at: origin + frame.origin, proposal: ProposedViewSize(frame.size))
        }
    }

    private func measure(_ subviews: Subviews, offered: ProposedViewSize) -> [Size] {
        let side = selectedSide(offered: offered)
        return subviews.indices.map { index in
            guard let side else { return subviews[index].sizeThatFits(.unspecified) }
            let scaled = side * scale(of: index)
            return subviews[index].sizeThatFits(ProposedViewSize(width: scaled, height: scaled))
        }
    }

    /// The selected subview's square: as tall as `offered`, no wider than
    /// half of it; `nil` when nothing is offered.
    func selectedSide(offered: ProposedViewSize) -> Double? {
        var limits: [Double] = []
        if let width = offered.width, width.isFinite { limits.append(width / 2) }
        if let height = offered.height, height.isFinite { limits.append(height) }
        return limits.min().map { max(0, $0) }
    }

    /// How big the subview at `index` is against the selected one.
    func scale(of index: Int) -> Double {
        pow(min(1, max(0, falloff)), abs(Double(index) - selection))
    }

    /// Each subview's frame from the layout's top-leading corner, and the
    /// layout's size: `width` wide when given, with the selection at its
    /// middle.
    func arrangement(of sizes: [Size], width: Double?) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let height = sizes.reduce(0) { max($0, $1.height) }
        var xs: [Double] = []
        var x = 0.0
        for size in sizes {
            xs.append(x)
            x += size.width + spacing
        }
        let rowWidth = x - spacing
        let centers = zip(xs, sizes).map { $0 + $1.width / 2 }

        var shift = 0.0
        let width = width.flatMap { $0.isFinite ? $0 : nil }
        if let width {
            // The selection — or the point between two, mid-animation — at
            // the middle.
            let clamped = min(max(0, selection), Double(sizes.count - 1))
            let lower = Int(clamped.rounded(.down))
            let upper = min(lower + 1, sizes.count - 1)
            let t = clamped - Double(lower)
            let focus = centers[lower] + (centers[upper] - centers[lower]) * t
            shift = width / 2 - focus
        }
        let frames = zip(xs, sizes).map { x, size in
            Rect(x: x + shift, y: (height - size.height) / 2, width: size.width, height: size.height)
        }
        return (frames, Size(width: width ?? rowWidth, height: height))
    }
}
