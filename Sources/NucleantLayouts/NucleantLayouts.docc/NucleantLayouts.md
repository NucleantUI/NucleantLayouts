# ``NucleantLayouts``

Sixteen layouts for NucleantUI, from a circle to a treemap, that a view can switch between and animate into one another.

@Metadata {
    @DisplayName("NucleantLayouts")
}

## Overview

@Image(source: "gallery", alt: "The Layout Gallery: a sidebar of sixteen layouts, each with a small glyph drawn by the layout itself, a stage of numbered coloured tiles on a sunflower spiral, and an inspector with the spiral's parameters and its code.")

NucleantLayouts is a collection of containers built on NucleantUI's `Layout`
protocol. Each one is used like a stack, with its subviews in a trailing
closure:

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

Behind an `AnyLayout`, one container can switch from one layout to another.
Its subviews keep their identity and state, and under an animation each
moves from its place in the old arrangement to its place in the new one.
Every layout's parameters animate too: a circle turns, a wave ripples,
rings twist against each other.

The fastest way to see what they do is the Layout Gallery, which runs in
your browser: <doc:LayoutGallery>.

## Topics

### Essentials

- <doc:UsingTheLayouts>
- <doc:LayoutGallery>

### Round a centre

- ``CircularLayout``
- ``ArcLayout``
- ``RingsLayout``
- ``SpiralLayout``

### Rows and columns

- ``GridLayout``
- ``FlowLayout``
- ``MasonryLayout``
- ``HoneycombLayout``
- ``PyramidLayout``
- ``EqualWidthHStack``

### Filling the space

- ``TreemapLayout``
- ``JustifiedLayout``
- ``BentoLayout``

### In motion

- ``WaveLayout``
- ``CascadeLayout``
- ``CarouselLayout``

### Values a subview hands its layout

- ``TreemapWeight``
- ``JustifiedAspectRatio``

### Shapes

- ``Hexagon``
