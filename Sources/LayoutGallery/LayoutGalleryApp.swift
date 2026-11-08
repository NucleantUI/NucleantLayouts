//
//  LayoutGalleryApp.swift
//  LayoutGallery
//
//  Every layout in NucleantLayouts, live: pick one in the sidebar and the
//  stage's tiles travel into it; its parameters are in the inspector, with
//  the code for what the stage shows.
//

import NucleantLayouts
import NucleantUI

enum Theme {
    static let sidebar = ShapeStyle.dynamic(light: Color(hex: 0xEFEDE8), dark: Color(hex: 0x17181C))
    static let stage = ShapeStyle.dynamic(light: Color(hex: 0xF7F6F2), dark: Color(hex: 0x111215))
    static let panel = ShapeStyle.dynamic(light: Color(hex: 0xF8F7F4), dark: Color(hex: 0x1C1D22))
    static let accent = Color(hex: 0xE0663D)
    static let glyph = Color(hex: 0x8A8D96)
}

@View
struct GalleryWindow {
    @State private var gallery = Gallery()

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(gallery: gallery)
                .frame(width: 200)
                .frame(maxHeight: .infinity)
                .background(Theme.sidebar)
            Divider()
            Stage(gallery: gallery)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.stage)
            Divider()
            Inspector(gallery: gallery)
                .frame(width: 300)
                .frame(maxHeight: .infinity)
                .background(Theme.panel)
        }
        .font(.system(size: 13))
        .tint(Theme.accent)
    }
}

@main
struct LayoutGalleryApp: NucleantApp {
    var body: some Scene {
        WindowGroup("Layout Gallery") {
            GalleryWindow()
        }
        .defaultSize(width: 1280, height: 820)
    }
}
