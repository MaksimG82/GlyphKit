//
//  GlyphSizing.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//

/// Defines how the glyph path is sized within its internal bounding container.
public enum GlyphSizing: Sendable {

    /// Sizes the glyph by its exact path bounds.
    /// The glyph fills the container as tightly as possible.
    /// Small symbols like "-" or "." will scale up to fill the container,
    /// regardless of their size relative to other characters in the font.
    case tight

    /// Sizes the glyph relative to the full vertical extent of the font (ascent + descent).
    /// Preserves the visual weight of the symbol within its typographic context —
    /// small symbols like "-" remain small, just as they would in a line of text.
    case fontMetrics
}
