# Using the layouts

Arrange subviews with a layout, switch between layouts, and size subviews to the space.

## Overview

Each layout in this package conforms to NucleantUI's `Layout` protocol, so
it works wherever a stack does.

### Add the package

Add NucleantLayouts to your package's dependencies, beside NucleantUI:

```swift
dependencies: [
    .package(url: "https://github.com/NucleantUI/NucleantUI", from: "0.1.0"),
    .package(url: "https://github.com/NucleantUI/NucleantLayouts", branch: "master"),
],
targets: [
    .executableTarget(
        name: "MyApp",
        dependencies: [
            .product(name: "NucleantUI", package: "NucleantUI"),
            .product(name: "NucleantLayouts", package: "NucleantLayouts"),
        ]
    ),
]
```

### Lay out subviews

Call a layout with its subviews in a trailing closure, as you would a
`VStack`:

```swift
GridLayout(columns: 4, horizontalSpacing: 12, verticalSpacing: 12) {
    ForEach(photos) { photo in
        Thumbnail(photo)
    }
}
```

Where a layout's `spacing` is `nil`, most use the gap their subviews ask
for, as a stack does; each layout's documentation says what it does.

### Switch between layouts

Wrap layouts in `AnyLayout` to choose one at run time. The container stays
the same view, so its subviews keep their identity and their `@State`, and
under an animation each one moves from its old place to its new one:

```swift
@View
struct Tiles {
    @State private var isRound = false
    let tiles: [Tile]

    var body: some View {
        let layout = isRound ? AnyLayout(CircularLayout()) : AnyLayout(GridLayout(columns: 4))
        layout {
            ForEach(tiles) { tile in
                TileView(tile: tile)
            }
        }
        .onTapGesture {
            withAnimation(.spring(duration: 0.6, bounce: 0.2)) { isRound.toggle() }
        }
    }
}
```

The subviews travel only if they are the same views in every layout.
A subview that is a different view in each — one branch of a `switch` for
the grid, another for the circle — is taken away and replaced with a
transition instead. To give a subview a different look per layout, keep its
views and change their values: a corner radius, a size, an opacity.

### Animate a layout's parameters

Changing the parameters of the same kind of layout under an animation
animates the layout itself, not just where its subviews end up. Turning a
``CircularLayout``'s `startAngle` swings every subview round the circle;
changing a ``WaveLayout``'s `phase` sends a ripple along the row:

```swift
CircularLayout(startAngle: .degrees(angle)) { … }

Button("Spin") {
    withAnimation(.smooth(duration: 0.9)) { angle += 90 }
}
```

Each layout's documentation lists which of its parameters animate.

### Size subviews to the space

A subview with a size of its own, such as text, an image, or a view with a
fixed `frame`, keeps it. A flexible subview, such as a `Color`, a `Circle`,
or a card with a `maxWidth`, takes the size its layout offers. Each layout
offers the biggest size with which its whole arrangement fits in the space
it is given:

- ``CircularLayout``, ``ArcLayout``, ``RingsLayout`` and ``SpiralLayout``
  offer a square that clears its neighbours, whichever way the arrangement
  is turned.
- ``GridLayout``, ``PyramidLayout`` and ``HoneycombLayout`` share the space
  between their columns and rows.
- ``WaveLayout``, ``EqualWidthHStack`` and ``CascadeLayout`` share the width,
  less what the wave's swing or the cascade's offsets take.
- ``TreemapLayout``, ``JustifiedLayout`` and ``BentoLayout`` give each
  subview its cell, so their subviews should be flexible.

So four bare colours fill a window in any of them:

```swift
SpiralLayout {
    Color.blue
    Color.red
    Color.green
    Color.yellow
}
```

Offered no space, as along a `ScrollView`'s scrolling axis, a layout sizes
to what its subviews ask for.

### Hand the layout a value from a subview

Some layouts read a value that each subview sets with a modifier:

- `treemapWeight(_:)` sets a subview's share of a ``TreemapLayout``.
- `justifiedAspectRatio(_:)` sets a subview's proportions in a
  ``JustifiedLayout``.
- `bentoSpan(columns:rows:)` sets how many cells of a ``BentoLayout`` a
  subview covers.

```swift
TreemapLayout(spacing: 2) {
    ForEach(folders) { folder in
        FolderTile(folder)
            .treemapWeight(folder.bytes)
    }
}
```

A layout ignores the others' values, so a subview can carry all of them and
be switched between those layouts.
