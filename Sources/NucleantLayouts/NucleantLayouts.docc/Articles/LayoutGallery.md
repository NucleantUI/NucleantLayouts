# Layout Gallery

Every layout in the package, live: pick one and the tiles travel into it.

@Metadata {
    @CallToAction(url: "/NucleantLayouts/gallery/", purpose: link, label: "Run in your browser")
    @PageImage(purpose: card, source: "gallery", alt: "The Layout Gallery: a sidebar of sixteen layouts, a stage of numbered coloured tiles on a sunflower spiral, and an inspector with the spiral's parameters and its code.")
}

## Overview

@Image(source: "gallery", alt: "The Layout Gallery: a sidebar of sixteen layouts, each with a small glyph drawn by the layout itself, a stage of numbered coloured tiles on a sunflower spiral, and an inspector with the spiral's parameters and its code.")

The gallery is the package's showcase app. Its sidebar lists the sixteen
layouts, each with a glyph that is that layout arranging a handful of dots.
The stage in the middle arranges two dozen tiles with whichever layout is
chosen, and the inspector on the right has that layout's parameters as live
controls, with the Swift that makes what the stage shows.

What it shows:

- One `AnyLayout` for every layout. Choosing another moves each tile from
  its place in the old arrangement to its place in the new one.
- A tile that is the same views in every layout, with only their values
  changing, so it reshapes as it travels: a disc on the circle rounds out
  into a card in the grid, a card on the arc straightens as it leaves.
- Parameters that animate: Spin turns the circle, Ripple sends a wave along
  the row, Twist winds the rings against each other, Reweigh reshapes the
  treemap.
- Subviews handing their layout a value: each tile's weight, proportions
  and span, read by the treemap, the justified rows and the bento grid.
- Clicking a tile removes it, or in the carousel brings it to the middle.

## Run it

The gallery runs in your browser from the button above: it is the same
Swift code, built for WebAssembly and drawn with WebGPU. You need a browser
with WebGPU: Chrome or Edge 113 or later, Safari 26, or Firefox 141 on
Windows.

To run it yourself, it is the package's `LayoutGallery` product:

```sh
git clone https://github.com/NucleantUI/NucleantLayouts
cd NucleantLayouts
swift run LayoutGallery
```

## See Also

- <doc:UsingTheLayouts>
