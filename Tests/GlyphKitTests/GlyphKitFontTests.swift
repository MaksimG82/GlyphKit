//
//  GlyphKitFontTests.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 03.06.26.
//

import Testing
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
        let font = GlyphKitFont.system(.helveticaNeue, isBold: true, italic: true)
        #expect(font.ctFont != nil)
    }
}
