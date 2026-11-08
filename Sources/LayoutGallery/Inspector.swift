//
//  Inspector.swift
//  LayoutGallery
//
//  The chosen layout: what it does, its parameters as live controls, the
//  tiles, and the code that makes what the stage shows.
//

import Foundation
import NucleantLayouts
import NucleantUI

@View
struct Inspector {
    let gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 14) {
                Text(gallery.kind.name)
                    .font(.system(size: 20, weight: .semibold))
                Text(gallery.kind.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Divider()
                SectionTitle(title: "PARAMETERS")
                switch gallery.kind {
                case .circular:  CircularControls(gallery: gallery)
                case .grid:      GridControls(gallery: gallery)
                case .flow:      FlowControls(gallery: gallery)
                case .masonry:   MasonryControls(gallery: gallery)
                case .honeycomb: HoneycombControls(gallery: gallery)
                case .spiral:    SpiralControls(gallery: gallery)
                case .wave:       WaveControls(gallery: gallery)
                case .arc:        ArcControls(gallery: gallery)
                case .rings:      RingsControls(gallery: gallery)
                case .cascade:    CascadeControls(gallery: gallery)
                case .treemap:    TreemapControls(gallery: gallery)
                case .justified:  JustifiedControls(gallery: gallery)
                case .bento:      BentoControls(gallery: gallery)
                case .equalWidth: EqualWidthControls(gallery: gallery)
                case .carousel:   CarouselControls(gallery: gallery)
                case .pyramid:    PyramidControls(gallery: gallery)
                }

                Divider()
                SectionTitle(title: "TILES")
                HStack(spacing: 8) {
                    Button("Add") {
                        withAnimation(.spring(duration: 0.45, bounce: 0.2)) { gallery.addTile() }
                    }
                    Button("Remove") {
                        withAnimation(.spring(duration: 0.45, bounce: 0.2)) { gallery.removeLastTile() }
                    }
                    Button("Shuffle") {
                        withAnimation(.spring(duration: 0.7, bounce: 0.15)) { gallery.shuffle() }
                    }
                }
                Text("\(gallery.tiles.count) tiles. Click one to \(gallery.kind == .carousel ? "bring it to the middle" : "remove it").")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Divider()
                SectionTitle(title: "CODE")
                Text(gallery.code)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.fill))
            }
            .padding(18)
        }
    }
}

@View
struct SectionTitle {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

/// A slider under its name and value.
@View
struct ValueSlider {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var unit: String = ""
    var step: Double = 0.5
    /// Decimal places shown.
    var places: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(String(format: "%.\(places)f", value) + unit)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step, label: { Text(title) }, onEditingChanged: { _ in })
                .labelsHidden()
        }
    }
}

/// A stepper over a count.
@View
struct CountStepper {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        Stepper(value: $value, in: range) {
            Text(title)
            Text("\(value)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

@View
struct CircularControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Fit the stage", isOn: $gallery.fitCircle)
            if !gallery.fitCircle {
                ValueSlider(title: "Radius", value: $gallery.radius, range: 60...320)
            }
            HStack(spacing: 8) {
                Button("Spin back") {
                    withAnimation(.smooth(duration: 0.9)) { gallery.spin(by: -360 / Double(max(gallery.tiles.count, 1)) * 3) }
                }
                Button("Spin on") {
                    withAnimation(.smooth(duration: 0.9)) { gallery.spin(by: 360 / Double(max(gallery.tiles.count, 1)) * 3) }
                }
            }
        }
    }
}

@View
struct GridControls {
    @Bindable var gallery: Gallery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CountStepper(title: "Columns", value: $gallery.gridColumns, range: 1...12)
            ValueSlider(title: "Spacing", value: $gallery.gridSpacing, range: 0...40)
            Text("Alignment in the cell")
            Picker("Across", selection: $gallery.gridHorizontal) {
                Text("Leading").tag(HorizontalAlignment.leading)
                Text("Center").tag(HorizontalAlignment.center)
                Text("Trailing").tag(HorizontalAlignment.trailing)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            Picker("Down", selection: $gallery.gridVertical) {
                Text("Top").tag(VerticalAlignment.top)
                Text("Center").tag(VerticalAlignment.center)
                Text("Bottom").tag(VerticalAlignment.bottom)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
}

@View
struct FlowControls {
    @Bindable var gallery: Gallery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Line alignment")
            Picker("Lines", selection: $gallery.flowAlignment) {
                Text("Leading").tag(HorizontalAlignment.leading)
                Text("Center").tag(HorizontalAlignment.center)
                Text("Trailing").tag(HorizontalAlignment.trailing)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            ValueSlider(title: "Spacing", value: $gallery.flowSpacing, range: 0...32)
            ValueSlider(title: "Line spacing", value: $gallery.flowLineSpacing, range: 0...32)
        }
    }
}

@View
struct MasonryControls {
    @Bindable var gallery: Gallery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CountStepper(title: "Columns", value: $gallery.masonryColumns, range: 1...8)
            ValueSlider(title: "Spacing", value: $gallery.masonrySpacing, range: 0...32)
        }
    }
}

@View
struct HoneycombControls {
    @Bindable var gallery: Gallery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CountStepper(title: "Columns", value: $gallery.honeycombColumns, range: 1...12)
            ValueSlider(title: "Spacing", value: $gallery.honeycombSpacing, range: 0...24)
        }
    }
}

@View
struct SpiralControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Divergence", value: $gallery.divergence, range: 60...180, unit: "°")
            ValueSlider(title: "Spacing", value: $gallery.spiralSpacing, range: 16...60)
            HStack(spacing: 8) {
                // Not 90° or 150°: a whole fraction of a turn stacks the
                // tiles in straight spokes; just off one curls them into arms.
                Button("95°") {
                    withAnimation(.smooth(duration: 1.4)) { gallery.divergence = 95 }
                }
                Button("Golden") {
                    withAnimation(.smooth(duration: 1.4)) { gallery.divergence = SpiralLayout.goldenAngle.degrees }
                }
                Button("152°") {
                    withAnimation(.smooth(duration: 1.4)) { gallery.divergence = 152 }
                }
            }
        }
    }
}

@View
struct WaveControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Amplitude", value: $gallery.waveAmplitude, range: 0...200)
            ValueSlider(title: "Waves", value: $gallery.waveCount, range: 0...4, step: 0.1, places: 1)
            ValueSlider(title: "Spacing", value: $gallery.waveSpacing, range: 0...24)
            HStack(spacing: 8) {
                Button("Ripple") {
                    withAnimation(.linear(duration: 1.6)) { gallery.ripple() }
                }
                Button("Flatten") {
                    withAnimation(.spring(duration: 0.8, bounce: 0.3)) { gallery.waveAmplitude = 0 }
                }
                Button("Swell") {
                    withAnimation(.spring(duration: 0.8, bounce: 0.3)) { gallery.waveAmplitude = 160 }
                }
            }
        }
    }
}

@View
struct ArcControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Span", value: $gallery.arcSpan, range: 20...360, unit: "°")
            Toggle("Fan the cards", isOn: $gallery.fanCards)
            HStack(spacing: 8) {
                Button("Close") {
                    withAnimation(.spring(duration: 0.8, bounce: 0.2)) { gallery.arcSpan = 40 }
                }
                Button("Open") {
                    withAnimation(.spring(duration: 0.8, bounce: 0.2)) { gallery.arcSpan = 140 }
                }
                Button("Ring") {
                    withAnimation(.spring(duration: 0.8, bounce: 0.2)) { gallery.arcSpan = 360 }
                }
            }
        }
    }
}

@View
struct RingsControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Spacing", value: $gallery.ringsSpacing, range: 0...30)
            ValueSlider(title: "Twist", value: $gallery.ringsTwist, range: -180...180, unit: "°")
            HStack(spacing: 8) {
                Button("Twist") {
                    withAnimation(.smooth(duration: 1.2)) { gallery.ringsTwist += 60 }
                }
                Button("Untwist") {
                    withAnimation(.smooth(duration: 1.2)) { gallery.ringsTwist = 0 }
                }
            }
        }
    }
}

@View
struct CascadeControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Across", value: $gallery.cascadeHorizontal, range: -40...40)
            ValueSlider(title: "Down", value: $gallery.cascadeVertical, range: -40...40)
            HStack(spacing: 8) {
                Button("Pile") {
                    withAnimation(.spring(duration: 0.7, bounce: 0.2)) {
                        gallery.cascadeHorizontal = 0
                        gallery.cascadeVertical = 0
                    }
                }
                Button("Deal") {
                    withAnimation(.spring(duration: 0.9, bounce: 0.2)) {
                        gallery.cascadeHorizontal = 18
                        gallery.cascadeVertical = 14
                    }
                }
            }
        }
    }
}

@View
struct TreemapControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Spacing", value: $gallery.treemapSpacing, range: 0...20)
            Button("Reweigh") {
                withAnimation(.spring(duration: 0.8, bounce: 0.15)) { gallery.reweigh() }
            }
        }
    }
}

@View
struct JustifiedControls {
    @Bindable var gallery: Gallery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Row height", value: $gallery.justifiedRowHeight, range: 50...240)
            ValueSlider(title: "Spacing", value: $gallery.justifiedSpacing, range: 0...24)
        }
    }
}

@View
struct BentoControls {
    @Bindable var gallery: Gallery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CountStepper(title: "Columns", value: $gallery.bentoColumns, range: 2...10)
            ValueSlider(title: "Spacing", value: $gallery.bentoSpacing, range: 0...24)
        }
    }
}

@View
struct EqualWidthControls {
    @Bindable var gallery: Gallery

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Spacing", value: $gallery.equalWidthSpacing, range: 0...24)
            Text("With every tile, they share the width. Remove tiles and they grow, until each is as wide as the widest word.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

@View
struct CarouselControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Falloff", value: $gallery.carouselFalloff, range: 0.4...1, step: 0.01, places: 2)
            HStack(spacing: 8) {
                Button("Previous") {
                    withAnimation(.spring(duration: 0.6, bounce: 0.2)) { gallery.stepCarousel(by: -1) }
                }
                Button("Next") {
                    withAnimation(.spring(duration: 0.6, bounce: 0.2)) { gallery.stepCarousel(by: 1) }
                }
                Button("Last") {
                    withAnimation(.smooth(duration: 1.4)) { gallery.stepCarousel(by: gallery.tiles.count) }
                }
            }
        }
    }
}

@View
struct PyramidControls {
    @Bindable var gallery: Gallery

    var body: some View {
        let gallery = self.gallery
        VStack(alignment: .leading, spacing: 12) {
            ValueSlider(title: "Spacing", value: $gallery.pyramidSpacing, range: 0...30)
            Button(gallery.pyramidInverted ? "Stand it up" : "Stand it on its point") {
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) { gallery.pyramidInverted.toggle() }
            }
        }
    }
}
