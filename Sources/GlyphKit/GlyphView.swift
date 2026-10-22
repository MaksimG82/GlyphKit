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
///
/// Deprecated: use `GlyphShape` with a fill, for example
/// `GlyphShape("A", font: font, layout: layout).fill(color)`, which renders the same
/// glyph and also supports strokes, gradients, `trim`, and clipping.
@available(*, deprecated, message: "Use GlyphShape(_:font:layout:) with .fill(color) instead.")
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
            guard let path = GlyphPathProvider.resolvedPath(
                character: character, font: font, layout: layout, size: size
            ) else { return }
            context.fill(Path(path), with: .color(color))
        }
        .accessibilityHidden(true)
    }
}
