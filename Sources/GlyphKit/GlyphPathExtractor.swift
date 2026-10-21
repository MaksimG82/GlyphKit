//
//  GlyphPathExtractor.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//

import CoreText
import Foundation

public enum GlyphPathExtractor {

    /// Returns a `CGPath` for the given character using the specified font.
    ///
    /// The character is shaped by Core Text, so combining marks and multi-scalar
    /// characters produce one combined outline. If the font lacks the character,
    /// Core Text substitutes a fallback font for it.
    ///
    /// - Parameters:
    ///   - character: A single character (e.g. "A", "é", "𝑥").
    ///   - font: The font to use for extraction. Defaults to `GlyphKitFont.default`.
    /// - Returns: The combined outline path, or `nil` if no glyph has an outline.
    public static func path(for character: Character, font: GlyphKitFont = .default) -> CGPath? {
        guard let ctFont = font.ctFont else { return nil }

        let fontKey = NSAttributedString.Key(kCTFontAttributeName as String)
        let text = NSAttributedString(string: String(character), attributes: [fontKey: ctFont])
        let line = CTLineCreateWithAttributedString(text)

        let combined = CGMutablePath()
        for run in CTLineGetGlyphRuns(line) as! [CTRun] {
            combined.addPath(outline(of: run))
        }
        return combined.isEmpty ? nil : combined
    }

    /// Returns the outlines of all glyphs in a run, each placed at its position within the line.
    ///
    /// Glyphs without an outline (for example a space) are skipped.
    private static func outline(of run: CTRun) -> CGPath {
        let attributes = CTRunGetAttributes(run) as NSDictionary
        let runFont = attributes[kCTFontAttributeName] as! CTFont

        let count = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: count)
        var positions = [CGPoint](repeating: .zero, count: count)
        CTRunGetGlyphs(run, CFRangeMake(0, 0), &glyphs)
        CTRunGetPositions(run, CFRangeMake(0, 0), &positions)

        let result = CGMutablePath()
        for (glyph, position) in zip(glyphs, positions) {
            guard let glyphPath = CTFontCreatePathForGlyph(runFont, glyph, nil) else { continue }
            result.addPath(glyphPath, transform: CGAffineTransform(translationX: position.x, y: position.y))
        }
        return result
    }
}


