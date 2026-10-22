//
//  GlyphKitFontTests.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 03.06.26.
//

import Testing
import Foundation
import CoreText
@testable import GlyphKit

@Suite("GlyphKitFont")
struct GlyphKitFontTests {
    
    /// All system font cases should resolve to a non-nil CTFont.
    @Test func systemFontsResolve() {
        let cases: [GlyphKitFont.SystemFont] = [
            .sanFrancisco, .sanFranciscoMono, .helveticaNeue,
            .timesNewRoman, .georgia, .courierNew,
            .avenir, .baskerville, .futura, .americanTypewriter
        ]
        for systemFont in cases {
            let font = GlyphKitFont.system(systemFont)
            #expect(font.ctFont != nil, "\(systemFont) failed to resolve")
        }
    }
    
    /// Bold and italic variants should also resolve.
    @Test func systemFontBoldItalicResolves() {
        let font = GlyphKitFont.system(.helveticaNeue, isBold: true, isItalic: true)
        #expect(font.ctFont != nil)
    }

    /// The bold flag should produce a font that carries the bold trait.
    @Test func boldTraitApplied() throws {
        let ctFont = try #require(GlyphKitFont.system(.helveticaNeue, isBold: true).ctFont)
        #expect(CTFontGetSymbolicTraits(ctFont).contains(.traitBold))
    }

    /// A custom font that is installed should resolve to that exact font.
    @Test func customFontExistingResolves() throws {
        let ctFont = try #require(GlyphKitFont.custom("Georgia").ctFont)
        #expect(CTFontCopyPostScriptName(ctFont) as String == "Georgia")
    }

    /// A custom font that isn't installed should return nil, not a substituted fallback font.
    @Test func customFontMissingReturnsNil() {
        let font = GlyphKitFont.custom("NoSuchFont-\(UUID().uuidString)")
        #expect(font.ctFont == nil)
    }
}
