//
//  NucleantLayouts.swift
//  NucleantLayouts
//
//  Containers built on NucleantUI's `Layout` protocol: `CircularLayout`,
//  `GridLayout`, `FlowLayout`, `MasonryLayout`, `HoneycombLayout`,
//  `SpiralLayout`, `WaveLayout`, `ArcLayout`, `RingsLayout`,
//  `CascadeLayout`, `TreemapLayout`, `JustifiedLayout`, `BentoLayout`,
//  `EqualWidthHStack`, `CarouselLayout` and `PyramidLayout`. Each is used
//  like a stack — `GridLayout(columns: 4) { … }` — or behind an
//  `AnyLayout`, so a container can switch between them and its subviews
//  move from one arrangement to the other.
//

import NucleantUI

extension LayoutSubviews {
    /// The widest gap any of these subviews ask for along `axis` — what a
    /// layout uses when it is given no spacing of its own.
    @MainActor
    func widestGap(along axis: Axis) -> Double {
        guard !isEmpty else { return 0 }
        let union = reduce(ViewSpacing.zero) { $0.union($1.spacing) }
        return union.distance(to: union, along: axis)
    }
}
