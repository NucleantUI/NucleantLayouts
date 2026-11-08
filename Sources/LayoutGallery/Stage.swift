//
//  Stage.swift
//  LayoutGallery
//
//  The tiles, arranged by whichever layout the gallery shows. It is one
//  `AnyLayout` throughout, so choosing another layout keeps every tile and
//  moves it from its place in the old arrangement to its place in the new
//  one; changing the same layout's parameters animates its
//  `animatableData` instead (Spin turns the circle).
//
//  A tile is the same views in every layout — only their values change —
//  so it travels and reshapes on the way: a disc rounds out into a card, a
//  card turns as it fans. Were it different views per layout, switching
//  would take the old ones away and bring new ones in instead.
//

import NucleantLayouts
import NucleantUI

@View
struct Stage {
    let gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        let arrangement = gallery.layout
        ScrollView {
            arrangement {
                ForEach(gallery.tiles) { tile in
                    TileView(tile: tile, look: TileLook(tile: tile, kind: gallery.kind), tilt: gallery.tilt(of: tile))
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.45, bounce: 0.2)) { gallery.tapped(tile) }
                        }
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
    }
}

/// One tile, in the look its layout gives it.
@View
struct TileView {
    let tile: Tile
    let look: TileLook
    /// How far the arc turns this tile.
    let tilt: Angle

    var body: some View {
        let look = self.look
        VStack(alignment: look.textAlignment, spacing: look.subtitle == nil ? 0 : 2) {
            Text(look.title)
                .font(.system(size: look.titleSize, weight: look.titleWeight))
                .lineLimit(1)
            // Always there, folded away when unused: an `if` would bring it
            // in at its new place rather than travel with the tile.
            Text(look.subtitle ?? "")
                .font(.system(size: look.subtitleSize))
                .lineLimit(1)
                .frame(height: look.subtitle == nil ? 0 : nil)
                .opacity(look.subtitle == nil ? 0 : 1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, look.padding.width)
        .padding(.vertical, look.padding.height)
        .frame(width: look.width, height: look.height, alignment: look.alignment)
        .frame(
            maxWidth: look.fillsWidth ? .infinity : nil,
            maxHeight: look.fillsHeight ? .infinity : nil,
            alignment: look.alignment
        )
        .background(
            ZStack {
                TileShape(cornerRadius: look.cornerRadius, roundness: look.roundness)
                    .fill(tile.color)
                    .opacity(look.isHexagon ? 0 : 1)
                Hexagon()
                    .fill(tile.color)
                    .opacity(look.isHexagon ? 1 : 0)
                TileShape(cornerRadius: look.cornerRadius, roundness: look.roundness)
                    .stroke(.white, lineWidth: 1.5)
                    .opacity(look.isOutlined ? 1 : 0)
            }
        )
        .rotationEffect(tilt)
        // Read only by the layouts they belong to.
        .treemapWeight(0.2 + tile.weight * 3)
        .justifiedAspectRatio(0.6 + tile.weight * 1.4)
        .bentoSpan(columns: tile.bentoSpan.columns, rows: tile.bentoSpan.rows)
    }
}

/// How a tile looks in one layout: a disc on the circle and the spiral, a
/// card in the grid, a chip in the flow, a card of its own height on the
/// masonry wall, a hexagon in the honeycomb, a playing card on the arc —
/// and a flexible cell in the layouts that size their subviews themselves.
struct TileLook {
    /// A fixed size; `nil` sizes to the label, or with `fillsWidth` /
    /// `fillsHeight`, to what the layout offers.
    var width: Double?
    var height: Double?
    var fillsWidth = false
    var fillsHeight = false
    var cornerRadius = 0.0
    /// 1 rounds the corners all the way: a disc, a capsule.
    var roundness = 0.0
    var isHexagon = false
    /// A white edge, so overlapping cards stay apart.
    var isOutlined = false
    /// Where the label sits.
    var alignment = Alignment.center
    var textAlignment = HorizontalAlignment.center
    var title: String
    var titleSize = 15.0
    var titleWeight = FontWeight.semibold
    var subtitle: String?
    var subtitleSize = 11.0
    var padding = Size(width: 0, height: 0)

    @MainActor
    init(tile: Tile, kind: LayoutKind) {
        title = tile.number
        switch kind {
        case .circular, .spiral:
            width = 46
            height = 46
            roundness = 1
        case .grid:
            // Not all the same shape, so the grid's alignment shows.
            width = 60 + 30 * tile.weight
            height = 60 + 30 * (1 - tile.weight)
            cornerRadius = 12
            titleSize = 17
            titleWeight = .bold
            subtitle = tile.word
            subtitleSize = 10
        case .flow:
            title = tile.word
            titleSize = 14
            titleWeight = .medium
            roundness = 1
            padding = Size(width: 14, height: 7)
        case .masonry:
            height = 70 + 140 * tile.weight
            fillsWidth = true
            cornerRadius = 12
            alignment = .topLeading
            textAlignment = .leading
            title = tile.word
            subtitle = "#\(tile.number)"
            subtitleSize = 12
            padding = Size(width: 12, height: 12)
        case .honeycomb:
            width = 58
            height = 58 * Hexagon.heightPerWidth
            isHexagon = true
        case .wave, .rings, .pyramid:
            fillsWidth = true
            fillsHeight = true
            roundness = 1
            titleSize = 12
        case .arc:
            width = 52
            height = 76
            cornerRadius = 7
            isOutlined = true
            alignment = .topLeading
            textAlignment = .leading
            titleSize = 14
            titleWeight = .bold
            padding = Size(width: 6, height: 6)
        case .cascade:
            width = 200
            height = 130
            cornerRadius = 10
            isOutlined = true
            alignment = .topLeading
            textAlignment = .leading
            title = tile.word
            titleSize = 14
            subtitle = "#\(tile.number)"
            padding = Size(width: 10, height: 10)
        case .treemap, .justified, .bento, .carousel:
            fillsWidth = true
            fillsHeight = true
            cornerRadius = kind == .treemap ? 6 : kind == .justified ? 4 : kind == .bento ? 14 : 18
            alignment = .topLeading
            textAlignment = .leading
            titleWeight = .bold
            subtitle = tile.word
            padding = Size(width: 8, height: 8)
        case .equalWidth:
            // The number stays legible when every tile shares a narrow
            // width; the word shows once there is room for the widest.
            fillsWidth = true
            cornerRadius = 10
            titleSize = 13
            titleWeight = .bold
            subtitle = tile.word
            padding = Size(width: 3, height: 8)
        }
    }
}

/// A rectangle with corners `cornerRadius` round, or rounder: at
/// `roundness` 1 they are round all the way — a disc in a square, a capsule
/// in anything wider. Both animate, so a disc rounds out into a card.
@View
struct TileShape: Shape {
    var cornerRadius: Double
    var roundness: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(cornerRadius, roundness) }
        set {
            cornerRadius = newValue.first
            roundness = newValue.second
        }
    }

    func path(in rect: Rect) -> Path {
        let full = min(rect.width, rect.height) / 2
        let radius = cornerRadius + (full - cornerRadius) * min(1, max(0, roundness))
        var path = Path()
        path.addRect(rect, cornerRadius: min(full, max(0, radius)))
        return path
    }
}
