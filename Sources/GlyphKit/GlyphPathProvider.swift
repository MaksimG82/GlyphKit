//
//  GlyphPathProvider.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 21.10.26.
//

import CoreGraphics

/// Produces ready-to-fill glyph paths by running the extraction and layout pipeline
/// through both tiers of `GlyphPathCache`.
enum GlyphPathProvider {

    /// Returns the fully-transformed glyph path for a container of `size` with its
    /// origin at (0, 0), reading and populating the render tier of `GlyphPathCache`.
    ///
    /// - Parameters:
    ///   - character: The character to render.
    ///   - font: The font used for extraction and font metrics.
    ///   - layout: The layout configuration.
    ///   - size: The external container size.
    /// - Returns: The transformed path, or `nil` if the font can't be resolved or the
    ///   character has no outline.
    static func resolvedPath(
        character: Character,
        font: GlyphKitFont,
        layout: GlyphLayout,
        size: CGSize
    ) -> CGPath? {
        let renderKey = GlyphPathCache.RenderKey(character: character, font: font, layout: layout, size: size)
        if let cached = GlyphPathCache.renderedPath(for: renderKey) {
            return cached
        } else if
            let ctFont = font.ctFont,
            let extracted = extractedPath(character: character, font: font),
            let transformed = extracted.copy(using: [GlyphLayoutResolver.resolve(
                layout: layout, path: extracted, font: ctFont, containerSize: size
            )])
        {
            GlyphPathCache.store(renderedPath: transformed, for: renderKey)
            return transformed
        } else {
            return nil
        }
    }

    // MARK: - Private

    /// Returns the raw, untransformed glyph path, reading and populating the
    /// extraction tier of `GlyphPathCache`.
    ///
    /// - Parameters:
    ///   - character: The character to extract.
    ///   - font: The font used for extraction.
    /// - Returns: The untransformed path, or `nil` if the character has no outline.
    private static func extractedPath(character: Character, font: GlyphKitFont) -> CGPath? {
        let key = GlyphPathCache.ExtractionKey(character: character, font: font)
        if let cached = GlyphPathCache.extractedPath(for: key) {
            return cached
        } else if let path = GlyphPathExtractor.path(for: character, font: font) {
            GlyphPathCache.store(extractedPath: path, for: key)
            return path
        } else {
            return nil
        }
    }
}
