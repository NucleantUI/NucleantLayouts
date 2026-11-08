//
//  Gallery.swift
//  LayoutGallery
//
//  The gallery's model: the tiles on the stage, which layout arranges
//  them, and every layout's parameters.
//

import Foundation
import NucleantLayouts
import NucleantUI
import Observation

/// One of the package's layouts.
enum LayoutKind: CaseIterable, Identifiable {
    case circular, grid, flow, masonry, honeycomb, spiral
    case wave, arc, rings, cascade, treemap, justified, bento, equalWidth, carousel, pyramid

    var id: Self { self }

    var name: String {
        switch self {
        case .circular:  return "Circular"
        case .grid:      return "Grid"
        case .flow:      return "Flow"
        case .masonry:   return "Masonry"
        case .honeycomb: return "Honeycomb"
        case .spiral:    return "Spiral"
        case .wave:       return "Wave"
        case .arc:        return "Arc"
        case .rings:      return "Rings"
        case .cascade:    return "Cascade"
        case .treemap:    return "Treemap"
        case .justified:  return "Justified"
        case .bento:      return "Bento"
        case .equalWidth: return "Equal width"
        case .carousel:   return "Carousel"
        case .pyramid:    return "Pyramid"
        }
    }

    var summary: String {
        switch self {
        case .circular:
            return "Evenly spaced round a circle, fitted to the space or of a set radius. The start angle animates, so Spin swings every tile round the ring."
        case .grid:
            return "Rows of a fixed number of columns. Each column is as wide as its widest cell; smaller cells sit in their slot by the alignment."
        case .flow:
            return "Left to right, wrapping to a new line when the next tile won't fit. Lines align leading, centred or trailing."
        case .masonry:
            return "Equal columns, each tile dropped into the shortest one. Tiles take the column width and choose their own height."
        case .honeycomb:
            return "Interlocking rows of hexagons: every other row is one shorter and pushed in by half a cell."
        case .spiral:
            return "A sunflower spiral: each tile turned by the divergence angle and a little further out. Change the angle to wind it into arms."
        case .wave:
            return "A row that rises and falls along a sine wave. Amplitude, waves and phase animate; Ripple turns the phase once round."
        case .arc:
            return "Spread along part of a circle, as big as the stage allows. Fan turns each card to stand out from the centre, like a hand of cards."
        case .rings:
            return "One in the middle and rings of 6, 12, 18 round it. Twist turns the rings against each other like a combination lock."
        case .cascade:
            return "Each card moved right and down from the one before and drawn over it. Pile stacks them squarely; Deal spreads them out again."
        case .treemap:
            return "Fills the stage, each tile's area in proportion to its weight, laid out squarified so cells stay near square. Reweigh deals new weights."
        case .justified:
            return "Rows that fill the width exactly, each tile keeping its proportions — the rows of a photo library."
        case .bento:
            return "A grid of equal cells where a tile can cover several columns and rows; small tiles fill the gaps left earlier."
        case .equalWidth:
            return "A row where every tile is as wide as the widest wants to be, or an even share of the width when that won't fit."
        case .carousel:
            return "A row centred on the selected tile, each step away smaller. Click a tile to bring it to the middle."
        case .pyramid:
            return "Centred rows of one, two, three and so on. Inverted stands it on its point."
        }
    }
}

/// A tile on the stage.
struct Tile: Identifiable {
    let id: Int
    let word: String
    let color: Color
    /// 0…1, the tile's own variation: its height on the masonry wall, its
    /// proportions in the grid and the justified rows, its share of the
    /// treemap and its span in the bento grid.
    var weight: Double

    var number: String { "\(id + 1)" }

    /// The cells the tile covers in the bento grid: the heaviest two by
    /// two, the next two across, then two down.
    var bentoSpan: (columns: Int, rows: Int) {
        weight >= 0.9 ? (2, 2) : weight >= 0.6 ? (2, 1) : weight >= 0.4 ? (1, 2) : (1, 1)
    }
}

@MainActor
@Observable
final class Gallery {
    private(set) var tiles: [Tile] = []
    private(set) var kind: LayoutKind = .circular
    private var nextID = 0

    // Circular
    /// The circle fills the stage; off, it has `radius`.
    var fitCircle = true
    var radius = 210.0
    private(set) var startAngle = -90.0

    // Grid
    var gridColumns = 6
    var gridSpacing = 12.0
    var gridHorizontal = HorizontalAlignment.center
    var gridVertical = VerticalAlignment.center

    // Flow
    var flowAlignment = HorizontalAlignment.leading
    var flowSpacing = 8.0
    var flowLineSpacing = 8.0

    // Masonry
    var masonryColumns = 4
    var masonrySpacing = 10.0

    // Honeycomb
    var honeycombColumns = 7
    var honeycombSpacing = 4.0

    // Spiral
    var divergence = SpiralLayout.goldenAngle.degrees
    var spiralSpacing = 34.0

    // Wave
    var waveAmplitude = 90.0
    var waveCount = 1.5
    private(set) var wavePhase = 0.0
    var waveSpacing = 6.0

    // Arc
    var arcSpan = 140.0
    var fanCards = true

    // Rings
    var ringsSpacing = 6.0
    var ringsTwist = 0.0

    // Cascade
    var cascadeHorizontal = 18.0
    var cascadeVertical = 14.0

    // Treemap
    var treemapSpacing = 4.0

    // Justified
    var justifiedRowHeight = 110.0
    var justifiedSpacing = 6.0

    // Bento
    var bentoColumns = 6
    var bentoSpacing = 10.0

    // Equal width
    var equalWidthSpacing = 2.0

    // Carousel
    var carouselSelection = 0
    var carouselFalloff = 0.78

    // Pyramid
    var pyramidSpacing = 8.0
    var pyramidInverted = false

    static let maximumTiles = 80

    init() {
        for _ in 0..<24 { addTile() }
    }

    func show(_ kind: LayoutKind) {
        self.kind = kind
    }

    func addTile() {
        guard tiles.count < Self.maximumTiles else { return }
        let id = nextID
        nextID += 1
        tiles.append(Tile(
            id: id,
            word: Self.words[id % Self.words.count],
            color: Self.palette[id % Self.palette.count],
            weight: Double((id * 7 + 3) % 11) / 10
        ))
    }

    func removeLastTile() {
        guard !tiles.isEmpty else { return }
        tiles.removeLast()
    }

    func remove(_ tile: Tile) {
        tiles.removeAll { $0.id == tile.id }
    }

    func shuffle() {
        tiles.shuffle()
    }

    /// A click on a tile: in the carousel it comes to the middle; anywhere
    /// else it goes.
    func tapped(_ tile: Tile) {
        if kind == .carousel {
            if let index = tiles.firstIndex(where: { $0.id == tile.id }) { carouselSelection = index }
        } else {
            remove(tile)
        }
    }

    /// New weights for every tile; the treemap reshapes to match.
    func reweigh() {
        for index in tiles.indices {
            tiles[index].weight = Double.random(in: 0...1)
        }
    }

    /// Sends one ripple along the wave.
    func ripple() {
        wavePhase -= 360
    }

    /// Steps the carousel's selection by `offset`, staying on a tile.
    func stepCarousel(by offset: Int) {
        carouselSelection = min(max(0, carouselSelection + offset), max(0, tiles.count - 1))
    }

    /// The arc the stage uses: `arcSpan` wide, centred on the top.
    var arc: ArcLayout {
        ArcLayout(startAngle: .degrees(-90 - arcSpan / 2), endAngle: .degrees(-90 + arcSpan / 2))
    }

    /// How far to turn `tile` so it stands out from the arc's centre, when
    /// fanning on the arc; upright anywhere else.
    func tilt(of tile: Tile) -> Angle {
        guard kind == .arc, fanCards, let index = tiles.firstIndex(where: { $0.id == tile.id }) else { return .zero }
        return .degrees(arc.angle(ofSubviewAt: index, count: tiles.count).degrees + 90)
    }

    /// Turns the circle by `degrees`; under an animation the tiles travel
    /// round it.
    func spin(by degrees: Double) {
        startAngle += degrees
    }

    /// The layout the stage uses now, with its current parameters.
    var layout: AnyLayout {
        switch kind {
        case .circular:
            return AnyLayout(CircularLayout(radius: fitCircle ? nil : radius, startAngle: .degrees(startAngle)))
        case .grid:
            return AnyLayout(GridLayout(
                columns: gridColumns,
                alignment: Alignment(horizontal: gridHorizontal, vertical: gridVertical),
                horizontalSpacing: gridSpacing,
                verticalSpacing: gridSpacing
            ))
        case .flow:
            return AnyLayout(FlowLayout(alignment: flowAlignment, spacing: flowSpacing, lineSpacing: flowLineSpacing))
        case .masonry:
            return AnyLayout(MasonryLayout(columns: masonryColumns, spacing: masonrySpacing))
        case .honeycomb:
            return AnyLayout(HoneycombLayout(columns: honeycombColumns, spacing: honeycombSpacing))
        case .spiral:
            return AnyLayout(SpiralLayout(divergence: .degrees(divergence), spacing: spiralSpacing))
        case .wave:
            return AnyLayout(WaveLayout(amplitude: waveAmplitude, waves: waveCount, phase: .degrees(wavePhase), spacing: waveSpacing))
        case .arc:
            return AnyLayout(arc)
        case .rings:
            return AnyLayout(RingsLayout(spacing: ringsSpacing, twist: .degrees(ringsTwist)))
        case .cascade:
            return AnyLayout(CascadeLayout(horizontalOffset: cascadeHorizontal, verticalOffset: cascadeVertical))
        case .treemap:
            return AnyLayout(TreemapLayout(spacing: treemapSpacing))
        case .justified:
            return AnyLayout(JustifiedLayout(rowHeight: justifiedRowHeight, spacing: justifiedSpacing))
        case .bento:
            return AnyLayout(BentoLayout(columns: bentoColumns, spacing: bentoSpacing))
        case .equalWidth:
            return AnyLayout(EqualWidthHStack(spacing: equalWidthSpacing))
        case .carousel:
            return AnyLayout(CarouselLayout(selection: carouselSelection, falloff: carouselFalloff))
        case .pyramid:
            return AnyLayout(PyramidLayout(spacing: pyramidSpacing, inverted: pyramidInverted))
        }
    }

    /// How to write `layout` in an app.
    var code: String {
        switch kind {
        case .circular:
            if fitCircle {
                return "CircularLayout(\n    startAngle: .degrees(\(format(startAngle)))\n)"
            }
            return "CircularLayout(\n    radius: \(format(radius)),\n    startAngle: .degrees(\(format(startAngle)))\n)"
        case .grid:
            return "GridLayout(\n    columns: \(gridColumns),\n    alignment: Alignment(horizontal: .\(gridHorizontal), vertical: .\(gridVertical)),\n    horizontalSpacing: \(format(gridSpacing)),\n    verticalSpacing: \(format(gridSpacing))\n)"
        case .flow:
            return "FlowLayout(\n    alignment: .\(flowAlignment),\n    spacing: \(format(flowSpacing)),\n    lineSpacing: \(format(flowLineSpacing))\n)"
        case .masonry:
            return "MasonryLayout(\n    columns: \(masonryColumns),\n    spacing: \(format(masonrySpacing))\n)"
        case .honeycomb:
            return "HoneycombLayout(\n    columns: \(honeycombColumns),\n    spacing: \(format(honeycombSpacing))\n)"
        case .spiral:
            return "SpiralLayout(\n    divergence: .degrees(\(format(divergence, places: 1))),\n    spacing: \(format(spiralSpacing))\n)"
        case .wave:
            return "WaveLayout(\n    amplitude: \(format(waveAmplitude)),\n    waves: \(format(waveCount, places: 1)),\n    phase: .degrees(\(format(wavePhase))),\n    spacing: \(format(waveSpacing))\n)"
        case .arc:
            let card = fanCards ? "\n\n// Each card:\n.rotationEffect(.degrees(\n    arc.angle(ofSubviewAt: i, count: n)\n        .degrees + 90\n))" : ""
            return "let arc = ArcLayout(\n    startAngle: .degrees(\(format(-90 - arcSpan / 2))),\n    endAngle: .degrees(\(format(-90 + arcSpan / 2)))\n)" + card
        case .rings:
            return "RingsLayout(\n    spacing: \(format(ringsSpacing)),\n    twist: .degrees(\(format(ringsTwist)))\n)"
        case .cascade:
            return "CascadeLayout(\n    horizontalOffset: \(format(cascadeHorizontal)),\n    verticalOffset: \(format(cascadeVertical))\n)"
        case .treemap:
            return "TreemapLayout(spacing: \(format(treemapSpacing)))\n\n// Each tile:\n.treemapWeight(tile.weight)"
        case .justified:
            return "JustifiedLayout(\n    rowHeight: \(format(justifiedRowHeight)),\n    spacing: \(format(justifiedSpacing))\n)\n\n// Each tile:\n.justifiedAspectRatio(width / height)"
        case .bento:
            return "BentoLayout(\n    columns: \(bentoColumns),\n    spacing: \(format(bentoSpacing))\n)\n\n// A big tile:\n.bentoSpan(columns: 2, rows: 2)"
        case .equalWidth:
            return "EqualWidthHStack(spacing: \(format(equalWidthSpacing)))"
        case .carousel:
            return "CarouselLayout(\n    selection: \(carouselSelection),\n    falloff: \(format(carouselFalloff, places: 2))\n)"
        case .pyramid:
            return "PyramidLayout(\n    spacing: \(format(pyramidSpacing)),\n    inverted: \(pyramidInverted)\n)"
        }
    }

    private func format(_ value: Double, places: Int = 0) -> String {
        String(format: "%.\(places)f", value)
    }

    private static let palette: [Color] = [
        Color(hex: 0xE0663D), Color(hex: 0x3D8BE0), Color(hex: 0x37B37E), Color(hex: 0xB45CD6),
        Color(hex: 0xE8A93B), Color(hex: 0x2BB3C0), Color(hex: 0xE04F7A), Color(hex: 0x6C72E0),
    ]

    private static let words = [
        "Swift", "layout", "Grid", "flow", "honeycomb", "spiral", "circle", "masonry",
        "proposal", "subviews", "place", "bounds", "AnyLayout", "spacing", "align", "wrap",
        "column", "row", "radius", "angle", "golden", "Vulkan", "Skia", "ThorVG",
        "animate", "spring", "tile", "measure", "size", "fit", "NucleantUI", "frame",
        "centre", "edge", "leading", "trailing", "gap", "cell", "line", "stack",
    ]
}
