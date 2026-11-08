//
//  WaveLayout.swift
//  NucleantLayouts
//

import Foundation
import NucleantUI

/// Subviews in a row that rises and falls along a sine wave.
///
/// ```swift
/// WaveLayout(amplitude: 30, waves: 1.5) {
///     ForEach(letters, id: \.self) { letter in
///         Text(letter)
///     }
/// }
/// ```
///
/// Left to right, each subview's centre is lifted by
/// `amplitude × sin(2π × waves × t + phase)`, where `t` runs from 0 at the
/// row's leading edge to 1 at its trailing edge — so `waves` is how many
/// crests fit across the row, however many subviews it has. The layout is
/// as wide as the row and as tall as its tallest subview plus the wave's
/// swing.
///
/// `amplitude`, `waves` and `phase` all animate. Turning `phase` by a whole
/// turn under a linear animation sends a ripple along the row:
///
/// ```swift
/// WaveLayout(phase: .degrees(360 * turns)) { … }
///
/// withAnimation(.linear(duration: 1.6)) { turns += 1 }
/// ```
///
/// Offered a width, flexible subviews — a `Color`, a `Circle` — share it
/// evenly as squares, no taller than the height left after the swing.
public struct WaveLayout: Layout {
    /// How far a subview at a crest is lifted above the middle.
    public var amplitude: Double
    /// How many whole waves span the row.
    public var waves: Double
    /// Where along its wave the row starts. Zero starts at the middle,
    /// rising.
    public var phase: Angle
    /// Between neighbours; `nil` is the gap the subviews ask for.
    public var spacing: Double?

    public init(amplitude: Double = 40, waves: Double = 1, phase: Angle = .zero, spacing: Double? = nil) {
        self.amplitude = amplitude
        self.waves = waves
        self.phase = phase
        self.spacing = spacing
    }

    public var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { AnimatablePair(amplitude, AnimatablePair(waves, phase.radians)) }
        set {
            amplitude = newValue.first
            waves = newValue.second.first
            phase = .radians(newValue.second.second)
        }
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

    /// An even share of the offered width, as a square no taller than the
    /// height leaves after the swing; unspecified when nothing is offered.
    func itemProposal(count: Int, offered: ProposedViewSize, gap: Double) -> ProposedViewSize {
        guard count > 0 else { return .unspecified }
        var limits: [Double] = []
        if let width = offered.width, width.isFinite {
            limits.append((width - gap * Double(count - 1)) / Double(count))
        }
        if let height = offered.height, height.isFinite {
            limits.append(height - abs(amplitude) * 2)
        }
        guard let side = limits.min() else { return .unspecified }
        return ProposedViewSize(width: max(0, side), height: max(0, side))
    }

    /// Each subview's frame from the top-leading corner of the wave's box,
    /// and the box's size.
    func arrangement(of sizes: [Size], gap: Double) -> (frames: [Rect], size: Size) {
        guard !sizes.isEmpty else { return ([], .zero) }
        let width = sizes.reduce(0) { $0 + $1.width } + gap * Double(sizes.count - 1)
        let tallest = sizes.reduce(0) { max($0, $1.height) }
        let swing = abs(amplitude)
        let size = Size(width: width, height: tallest + swing * 2)
        let middle = size.height / 2
        var x = 0.0
        let frames = sizes.map { itemSize in
            let t = width > 0 ? (x + itemSize.width / 2) / width : 0.5
            let lift = amplitude * sin(2 * Double.pi * waves * t + phase.radians)
            let frame = Rect(x: x, y: middle - lift - itemSize.height / 2, width: itemSize.width, height: itemSize.height)
            x += itemSize.width + gap
            return frame
        }
        return (frames, size)
    }
}
