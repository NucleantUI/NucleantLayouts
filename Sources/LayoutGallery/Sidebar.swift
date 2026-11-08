//
//  Sidebar.swift
//  LayoutGallery
//
//  The layouts, each with a glyph that is that layout itself arranging a
//  handful of dots. Choosing one morphs the stage into it.
//

import NucleantLayouts
import NucleantUI

@View
struct Sidebar {
    let gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Layouts")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 10)
                ForEach(LayoutKind.allCases) { kind in
                    SidebarRow(kind: kind, isSelected: gallery.kind == kind) {
                        withAnimation(.spring(duration: 0.7, bounce: 0.15)) { gallery.show(kind) }
                    }
                }
            }
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

@View
struct SidebarRow {
    let kind: LayoutKind
    let isSelected: Bool
    let choose: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            LayoutGlyph(kind: kind, isSelected: isSelected)
                .frame(width: 32, height: 32)
            Text(kind.name)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isSelected ? .color(Theme.accent.opacity(0.18)) : (isHovered ? .fill : .color(.clear)))
        )
        .padding(.horizontal, 8)
        .onHover { isHovered = $0 }
        .onTapGesture { choose() }
    }
}

/// A layout drawn by itself, small.
@View
struct LayoutGlyph {
    let kind: LayoutKind
    let isSelected: Bool

    var body: some View {
        let ink = isSelected ? Theme.accent : Theme.glyph
        switch kind {
        case .circular:
            CircularLayout(radius: 11) {
                ForEach(0..<8) { _ in
                    Circle().fill(ink).frame(width: 5, height: 5)
                }
            }
        case .grid:
            GridLayout(columns: 3, horizontalSpacing: 2, verticalSpacing: 2) {
                ForEach(0..<9) { _ in
                    RoundedRectangle(cornerRadius: 1.5).fill(ink).frame(width: 7, height: 7)
                }
            }
        case .flow:
            FlowLayout(spacing: 2, lineSpacing: 2) {
                ForEach(0..<7) { index in
                    Capsule().fill(ink).frame(width: [10, 7, 12, 8, 6, 11, 9][index], height: 5)
                }
            }
            .frame(width: 28)
        case .masonry:
            MasonryLayout(columns: 3, spacing: 2) {
                ForEach(0..<7) { index in
                    RoundedRectangle(cornerRadius: 1.5).fill(ink).frame(height: [10, 6, 13, 8, 12, 7, 5][index])
                }
            }
            .frame(width: 26)
        case .honeycomb:
            HoneycombLayout(columns: 3, spacing: 1) {
                ForEach(0..<8) { _ in
                    Hexagon().fill(ink).frame(width: 7, height: 7 * Hexagon.heightPerWidth)
                }
            }
        case .spiral:
            SpiralLayout(spacing: 3.4) {
                ForEach(0..<16) { _ in
                    Circle().fill(ink).frame(width: 4, height: 4)
                }
            }
        case .wave:
            WaveLayout(amplitude: 6, waves: 1, spacing: 0.5) {
                ForEach(0..<7) { _ in
                    Circle().fill(ink).frame(width: 3.5, height: 3.5)
                }
            }
        case .arc:
            ArcLayout(radius: 13) {
                ForEach(0..<5) { _ in
                    Circle().fill(ink).frame(width: 5, height: 5)
                }
            }
        case .rings:
            RingsLayout(spacing: 0.5) {
                ForEach(0..<7) { _ in
                    Circle().fill(ink).frame(width: 4, height: 4)
                }
            }
        case .cascade:
            CascadeLayout(horizontalOffset: 4, verticalOffset: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ink.opacity(0.35 + 0.2 * Double(index)))
                        .frame(width: 15, height: 12)
                }
            }
        case .treemap:
            TreemapLayout(spacing: 1.5) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 1.5).fill(ink)
                        .treemapWeight([5, 3, 2, 1.2, 1][index])
                }
            }
            .frame(width: 26, height: 22)
        case .justified:
            JustifiedLayout(rowHeight: 7, spacing: 1.5) {
                ForEach(0..<8) { index in
                    RoundedRectangle(cornerRadius: 1).fill(ink)
                        .justifiedAspectRatio([1.5, 0.8, 1.2, 1, 1.8, 0.7, 1.3, 1.6][index])
                }
            }
            .frame(width: 28)
        case .bento:
            BentoLayout(columns: 3, spacing: 1.5) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 1.5).fill(ink)
                        .bentoSpan(columns: [2, 1, 1, 1, 2][index], rows: [2, 1, 1, 1, 1][index])
                }
            }
            .frame(width: 26)
        case .equalWidth:
            EqualWidthHStack(spacing: 2) {
                ForEach(0..<3) { _ in
                    Capsule().fill(ink).frame(height: 5)
                }
            }
            .frame(width: 28)
        case .carousel:
            CarouselLayout(selection: 2, spacing: 1.5, falloff: 0.7) {
                ForEach(0..<5) { _ in
                    RoundedRectangle(cornerRadius: 1.5).fill(ink)
                }
            }
            .frame(width: 30, height: 14)
            .clipped()
        case .pyramid:
            PyramidLayout(spacing: 1.5) {
                ForEach(0..<6) { _ in
                    Circle().fill(ink).frame(width: 5, height: 5)
                }
            }
        }
    }
}
