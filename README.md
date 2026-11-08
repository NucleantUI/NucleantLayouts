# NucleantLayouts

Sixteen layouts for [NucleantUI](https://github.com/NucleantUI/NucleantUI), from a circle to a treemap, that a view can switch between and animate into one another.

**[Try the Layout Gallery in your browser](https://nucleantui.github.io/NucleantLayouts/gallery/)** · **[Documentation](https://nucleantui.github.io/NucleantLayouts/)**

The gallery needs a browser with WebGPU: Chrome or Edge 113 or later, Safari 26, or Firefox 141 on Windows.

## The layouts

| Layout | Arranges its subviews |
|---|---|
| `CircularLayout` | evenly round a circle, fitted to the space or of a set radius |
| `ArcLayout` | along part of a circle, like a hand of cards or a speed dial |
| `RingsLayout` | one in the middle, then rings of 6, 12, 18… round it |
| `SpiralLayout` | on a sunflower spiral, turned by the golden angle |
| `GridLayout` | in rows of a fixed number of columns |
| `FlowLayout` | left to right, wrapping when the next won't fit |
| `MasonryLayout` | in equal columns, each dropped into the shortest |
| `HoneycombLayout` | in interlocking rows of hexagons |
| `PyramidLayout` | in centred rows of one, two, three… |
| `EqualWidthHStack` | in a row, each as wide as the widest wants to be |
| `TreemapLayout` | tiling the space, each area in proportion to its weight |
| `JustifiedLayout` | in rows that fill the width exactly, like a photo library |
| `BentoLayout` | in a grid where one can cover several columns and rows |
| `WaveLayout` | in a row that rises and falls along a sine wave |
| `CascadeLayout` | stacked like cascaded windows or a dealt deck |
| `CarouselLayout` | in a row centred on the selected one, the rest smaller with distance |

## Use

Add the package beside NucleantUI:

```swift
dependencies: [
    .package(url: "https://github.com/NucleantUI/NucleantUI", from: "0.1.0"),
    .package(url: "https://github.com/NucleantUI/NucleantLayouts", branch: "master"),
],
```

with `.product(name: "NucleantLayouts", package: "NucleantLayouts")` in your target's dependencies. A layout is used like a stack:

```swift
import NucleantLayouts
import NucleantUI

@View
struct Team {
    let members: [Member]

    var body: some View {
        CircularLayout {
            ForEach(members) { member in
                Avatar(member)
            }
        }
    }
}
```

Behind an `AnyLayout`, one container switches between layouts, and under an animation its subviews move from one arrangement to the other:

```swift
let layout = isRound ? AnyLayout(CircularLayout()) : AnyLayout(GridLayout(columns: 4))
layout {
    ForEach(tiles) { tile in
        TileView(tile: tile)
    }
}
```

Each layout's parameters animate as well: a circle turns, a wave ripples, rings twist against each other. Flexible subviews such as a bare `Color` are offered the biggest size with which the whole arrangement fits its space.

## The gallery

`LayoutGallery` is the package's showcase app: every layout, its parameters as live controls, and the code for what it shows.

```sh
swift run LayoutGallery
```

## Documentation

The documentation is a DocC catalog in `Sources/NucleantLayouts/NucleantLayouts.docc`, published with the gallery on GitHub Pages by `.github/workflows/docs.yml`. `Scripts/build-docs.sh` builds the same site locally.
