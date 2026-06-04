//
//  GlyphView.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//

import SwiftUI
import CoreText

/// A SwiftUI view that renders a single character as a vector glyph inside a `Canvas`.
///
/// Extracts the glyph path via `GlyphPathExtractor`, resolves the transform
/// via `GlyphLayoutResolver`, and draws the result without baseline or Dynamic Type shifts.
public struct GlyphView: View {

    // MARK: - Public Properties

    /// The single character to render.
    public let character: Character

    /// The font used for path extraction.
    public let font: GlyphKitFont

    /// Layout configuration: sizing, anchor, and offset.
    public let layout: GlyphLayout

    /// The fill color for the glyph.
    public let color: Color

    // MARK: - Init

    /// Creates a `GlyphView` with explicit configuration.
    ///
    /// - Parameters:
    ///   - character: The character to render.
    ///   - font: The font for extraction. Defaults to `.default`.
    ///   - layout: The layout configuration. Defaults to `.default`.
    ///   - color: The fill color. Defaults to `.primary`.
    public init(
        _ character: Character,
        font: GlyphKitFont = .default,
        layout: GlyphLayout = .default,
        color: Color = .primary
    ) {
        self.character = character
        self.font = font
        self.layout = layout
        self.color = color
    }

    // MARK: - Body

    public var body: some View {
        Canvas { context, size in
            guard
                let ctFont = font.ctFont,
                let path = GlyphPathExtractor.path(for: character, font: font),
                let copied = path.copy(using: [GlyphLayoutResolver.resolve(
                    layout: layout,
                    path: path,
                    font: ctFont,
                    containerSize: size
                )])
            else { return }

            context.fill(Path(copied), with: .color(color))
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#if DEBUG

#Preview("GlyphView — multiple") {
    let characters: [Character] = ["A", "g", "&", "3", "ß", "?"]
    let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink]

    return LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 24) {
        ForEach(Array(zip(characters, colors)), id: \.0.description) { char, color in
            GlyphView(char, color: color)
                .frame(width: 80, height: 80)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    .padding()
}

#Preview("GlyphView — layout variants") {
    let items: [(Character, GlyphLayout, Color)] = [
        ("=", GlyphLayout(sizing: .tight,       anchor: .center,        offset: .zero), .blue),
        ("=", GlyphLayout(sizing: .fontMetrics, anchor: .center,        offset: .zero), .blue),
        ("'", GlyphLayout(sizing: .tight,       anchor: .center,        offset: .zero), .red),
        ("'", GlyphLayout(sizing: .fontMetrics, anchor: .center,        offset: .zero), .red),
        (".", GlyphLayout(sizing: .tight,       anchor: .center,        offset: .zero), .green),
        (".", GlyphLayout(sizing: .fontMetrics, anchor: .center,        offset: .zero), .green),
        (".", GlyphLayout(sizing: .fontMetrics, anchor: .bottom,        offset: .zero), .orange),
        (".", GlyphLayout(sizing: .fontMetrics, anchor: .bottomLeading, offset: .zero), .purple),
    ]

    return LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 16) {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            GlyphView(item.0, layout: item.1, color: item.2)
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    .padding()
}

#Preview("README — examples") {
    HStack(spacing: 16) {
        GlyphView("Å")
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        GlyphView(".",
            layout: GlyphLayout(sizing: .fontMetrics, anchor: .center, offset: .zero),
            color: .orange
        )
        .frame(width: 80, height: 80)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))

        GlyphView("3",
            font: .system(.georgia, isBold: true, isItalic: true),
            layout: .default,
            color: .blue
        )
        .frame(width: 80, height: 80)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding()
}

#Preview("README — notebook grid") {
    let items: [(Character, GlyphSizing)] = [
        ("3", .tight),
        ("=", .fontMetrics),
        ("8", .tight)
    ]

    HStack(spacing: 0) {
        ForEach(items, id: \.0) { digit, sizing in
            GlyphView(digit,
                font: .system(.georgia, isItalic: true),
                layout: GlyphLayout(
                    sizing: sizing,
                    anchor: sizing == .tight ? .trailing : .center,
                    offset: .zero
                ),
                color: .primary
            )
            .frame(width: 56, height: 56)
            .border(Color(.systemGray4), width: 0.5)
        }
    }
    .padding()
}

#endif
