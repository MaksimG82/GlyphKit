//
//  GlyphPathCacheTests.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 22.10.26.
//

import Testing
import Foundation
import CoreText
@testable import GlyphKit

// The cache is process-wide and tests run in parallel, so each test uses its own font key.
@Suite("GlyphPathCache")
struct GlyphPathCacheTests {

    // MARK: - Font tier

    /// A second lookup of the same font returns the identical cached `CTFont` instance.
    @Test func fontLookupReturnsIdenticalInstance() throws {
        let font = GlyphKitFont.system(.georgia, isBold: true)

        let first = try #require(GlyphPathCache.ctFont(for: font))
        let second = try #require(GlyphPathCache.ctFont(for: font))

        #expect(first === second)
    }

    /// A font that fails to resolve returns `nil` and is not stored.
    @Test func unresolvableFontIsNotCached() {
        let font = GlyphKitFont.custom("NoSuchFont-\(UUID().uuidString)")

        #expect(GlyphPathCache.ctFont(for: font) == nil)
        #expect(GlyphPathCache.cachedCTFont(for: font) == nil)
    }
}
