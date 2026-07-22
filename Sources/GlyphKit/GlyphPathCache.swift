//
//  GlyphPathCache.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 22.07.26.
//

import Foundation
import CoreGraphics

/// A process-lifetime, thread-safe cache for the two expensive, independently
/// invalidating steps in `GlyphView`'s render pipeline, so it doesn't need to
/// redo them on every `Canvas` re-evaluation when nothing relevant changed.
///
/// Backed by `NSCache`, which is safe for concurrent access from multiple threads
/// and evicts entries automatically under memory pressure — `GlyphView`'s `Canvas`
/// content closure isn't guaranteed to run on the main thread, so this avoids
/// needing any additional locking.
///
/// The cache is split into two tiers, mirroring the two independent steps in the
/// render pipeline:
/// - **Extraction** (`ExtractionKey` — `character` + `font`): the raw, untransformed
///   glyph outline from `GlyphPathExtractor`, the expensive step.
/// - **Render** (`RenderKey` — `character` + `font` + `layout` + `size`): the final
///   transformed path from `GlyphLayoutResolver`, ready to fill.
///
/// Splitting the tiers means a size- or layout-only change (the same character
/// re-rendered at a different size, say) still reuses the extracted path and only
/// redoes the transform.
enum GlyphPathCache {

    /// Identifies a glyph's extraction inputs — character and font — for cache lookup.
    struct ExtractionKey: Hashable {
        var character: Character
        var font: GlyphKitFont

        /// Creates an extraction cache key.
        /// - Parameters:
        ///   - character: The character being extracted.
        ///   - font: The font used for extraction.
        init(character: Character, font: GlyphKitFont) {
            self.character = character
            self.font = font
        }
    }

    /// Identifies a glyph's fully-resolved render configuration — character, font,
    /// layout, and container size — for cache lookup.
    ///
    /// `layout`'s `anchor`/`offset`/`size` are broken out into raw `CGFloat` fields
    /// rather than stored as `UnitPoint`/`CGPoint`/`CGSize` directly, so this type
    /// has no dependency on those SDK types conforming to `Hashable`.
    struct RenderKey: Hashable {
        var character: Character
        var font: GlyphKitFont
        var isTightSizing: Bool
        var anchorX: CGFloat
        var anchorY: CGFloat
        var offsetX: CGFloat
        var offsetY: CGFloat
        var width: CGFloat
        var height: CGFloat

        /// Creates a render cache key.
        /// - Parameters:
        ///   - character: The character being rendered.
        ///   - font: The font used for extraction.
        ///   - layout: The layout configuration.
        ///   - size: The external container size.
        init(character: Character, font: GlyphKitFont, layout: GlyphLayout, size: CGSize) {
            self.character = character
            self.font = font
            switch layout.sizing {
            case .tight: isTightSizing = true
            case .fontMetrics: isTightSizing = false
            }
            anchorX = layout.anchor.x
            anchorY = layout.anchor.y
            offsetX = layout.offset.x
            offsetY = layout.offset.y
            width = size.width
            height = size.height
        }
    }

    /// Returns the cached, untransformed glyph path for `key`, if present.
    /// - Parameter key: The extraction inputs to look up.
    /// - Returns: The cached path, or `nil` on a cache miss.
    static func extractedPath(for key: ExtractionKey) -> CGPath? {
        extractionStorage.object(forKey: ExtractionBox(key))
    }

    /// Stores `path` in the extraction cache for `key`.
    /// - Parameters:
    ///   - path: The raw, untransformed glyph path to cache.
    ///   - key: The extraction inputs `path` was resolved from.
    static func store(extractedPath path: CGPath, for key: ExtractionKey) {
        extractionStorage.setObject(path, forKey: ExtractionBox(key))
    }

    /// Returns the cached, fully-transformed glyph path for `key`, if present.
    /// - Parameter key: The render configuration to look up.
    /// - Returns: The cached path, or `nil` on a cache miss.
    static func renderedPath(for key: RenderKey) -> CGPath? {
        renderStorage.object(forKey: RenderBox(key))
    }

    /// Stores `path` in the render cache for `key`.
    /// - Parameters:
    ///   - path: The fully-transformed glyph path to cache.
    ///   - key: The render configuration `path` was resolved from.
    static func store(renderedPath path: CGPath, for key: RenderKey) {
        renderStorage.setObject(path, forKey: RenderBox(key))
    }

    // MARK: - Private

    /// The maximum number of extracted paths to retain. Extraction keys vary only
    /// by character + font, so the working set is naturally small.
    private static let extractionCountLimit = 128

    /// The maximum number of rendered paths to retain. A cheap guardrail against
    /// unbounded growth — e.g. during continuous size-changing animations, where
    /// every intermediate frame size is a distinct render key — on top of
    /// `NSCache`'s own memory-pressure eviction.
    private static let renderCountLimit = 256

    // `NSCache` is documented as safe for concurrent access from multiple threads,
    // but Foundation's overlay doesn't mark it `Sendable` — `nonisolated(unsafe)`
    // asserts that documented thread-safety to the compiler.
    private nonisolated(unsafe) static let extractionStorage: NSCache<ExtractionBox, CGPath> = {
        let cache = NSCache<ExtractionBox, CGPath>()
        cache.countLimit = extractionCountLimit
        return cache
    }()

    private nonisolated(unsafe) static let renderStorage: NSCache<RenderBox, CGPath> = {
        let cache = NSCache<RenderBox, CGPath>()
        cache.countLimit = renderCountLimit
        return cache
    }()

    /// Wraps `ExtractionKey` as an `NSObject` so it can be used with `NSCache`,
    /// which requires reference-type keys.
    private final class ExtractionBox: NSObject, Sendable {
        let key: ExtractionKey

        init(_ key: ExtractionKey) {
            self.key = key
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? ExtractionBox else { return false }
            return other.key == key
        }

        override var hash: Int {
            key.hashValue
        }
    }

    /// Wraps `RenderKey` as an `NSObject` so it can be used with `NSCache`, which
    /// requires reference-type keys.
    private final class RenderBox: NSObject {
        let key: RenderKey

        init(_ key: RenderKey) {
            self.key = key
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? RenderBox else { return false }
            return other.key == key
        }

        override var hash: Int {
            key.hashValue
        }
    }
}
