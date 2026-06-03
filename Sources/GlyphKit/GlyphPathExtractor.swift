//
//  GlyphPathExtractor.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//

import CoreText
import CoreGraphics

/// Extracts the vector outline of a single character using Core Text.
public enum GlyphPathExtractor {

    /// Returns a `CGPath` for the given character using the specified font.
    /// - Parameters:
    ///   - character: A single character (e.g. "A")
    ///   - font: The font to use for extraction. Defaults to `GlyphKitFont.default`.
    /// - Returns: The glyph outline path, or `nil` if the character is not found in the font.
    public static func path(for character: Character, font: GlyphKitFont = .default) -> CGPath? {
        guard let ctFont = font.ctFont else { return nil }
        let glyphs = glyphIDs(for: character, font: ctFont)
        guard let glyph = glyphs.first else { return nil }
        return CTFontCreatePathForGlyph(ctFont, glyph, nil)
    }

    /// Converts a character into an array of `CGGlyph` identifiers via Unicode scalar values.
    private static func glyphIDs(for character: Character, font: CTFont) -> [CGGlyph] {
        let chars = String(character).unicodeScalars.map { UniChar($0.value & 0xFFFF) }
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        CTFontGetGlyphsForCharacters(font, chars, &glyphs, chars.count)
        return glyphs.filter { $0 != 0 }
    }
}


