//
//  RenderTierBenchmarkTests.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 22.10.26.
//

import Foundation
import Testing
import CoreGraphics
@testable import GlyphKit

/// Micro-benchmark comparing the full glyph path pipeline (render tier + extraction tier)
/// against a variant that skips the render tier of `GlyphPathCache`.
///
/// Prints average nanoseconds per call. Run in Release with testability enabled;
/// Debug numbers are not representative.
@Suite("Benchmark — render tier")
struct RenderTierBenchmarkTests {

    private let character: Character = "A"
    private let font = GlyphKitFont.default
    private let layout = GlyphLayout.default
    private let size = CGSize(width: 56, height: 56)

    /// Calls per timed repetition, standing in for a grid of identical cells.
    private let cellCount = 100

    /// Timed repetitions per variant; the fastest one is reported.
    private let repetitions = 20

    // MARK: - Scenario 1: identical cells

    /// 100 cells with the same character, font, layout, and size, with warm caches.
    @Test func identicalCells() {
        // Warm both tiers so the timed runs measure steady-state lookups only.
        _ = GlyphPathProvider.resolvedPath(character: character, font: font, layout: layout, size: size)

        var sink = 0

        let withRenderTier = nanosecondsPerCall(calls: cellCount) {
            for _ in 0..<cellCount {
                if GlyphPathProvider.resolvedPath(
                    character: character, font: font, layout: layout, size: size
                ) != nil { sink += 1 }
            }
        }

        let withoutRenderTier = nanosecondsPerCall(calls: cellCount) {
            for _ in 0..<cellCount {
                if resolvedPathWithoutRenderTier() != nil { sink += 1 }
            }
        }

        print("""
        [Benchmark] identical cells (\(cellCount) per repetition, best of \(repetitions))
          with render tier:    \(format(withRenderTier)) ns/call
          without render tier: \(format(withoutRenderTier)) ns/call
        """)

        // Guards against the optimizer discarding the timed work and against a broken pipeline.
        #expect(sink == 2 * cellCount * repetitions)
    }

    // MARK: - Scenario 2: cost of a render-tier miss

    /// Times each step that runs on a render-tier miss separately, with the extraction tier warm.
    @Test func missBreakdown() throws {
        _ = GlyphPathProvider.resolvedPath(character: character, font: font, layout: layout, size: size)

        let key = GlyphPathCache.ExtractionKey(character: character, font: font)
        let extracted = try #require(GlyphPathCache.extractedPath(for: key))
        let ctFont = try #require(font.ctFont)
        let transform = GlyphLayoutResolver.resolve(
            layout: layout, path: extracted, font: ctFont, containerSize: size
        )

        var sink = 0

        let fontConstruction = nanosecondsPerCall(calls: cellCount) {
            for _ in 0..<cellCount {
                if font.ctFont != nil { sink += 1 }
            }
        }

        let cachedFontLookup = nanosecondsPerCall(calls: cellCount) {
            for _ in 0..<cellCount {
                if GlyphPathCache.ctFont(for: font) != nil { sink += 1 }
            }
        }

        let extractionLookup = nanosecondsPerCall(calls: cellCount) {
            for _ in 0..<cellCount {
                if GlyphPathCache.extractedPath(for: key) != nil { sink += 1 }
            }
        }

        let transformResolution = nanosecondsPerCall(calls: cellCount) {
            for _ in 0..<cellCount {
                let resolved = GlyphLayoutResolver.resolve(
                    layout: layout, path: extracted, font: ctFont, containerSize: size
                )
                if resolved.a.isFinite { sink += 1 }
            }
        }

        let pathCopy = nanosecondsPerCall(calls: cellCount) {
            for _ in 0..<cellCount {
                if extracted.copy(using: [transform]) != nil { sink += 1 }
            }
        }

        print("""
        [Benchmark] render-tier miss breakdown (\(cellCount) per repetition, best of \(repetitions))
          font construction (font.ctFont):     \(format(fontConstruction)) ns/call
          font tier lookup (cached ctFont):    \(format(cachedFontLookup)) ns/call
          extraction tier lookup:              \(format(extractionLookup)) ns/call
          transform resolution (resolve):      \(format(transformResolution)) ns/call
          path copy (copy(using:)):            \(format(pathCopy)) ns/call
        """)

        #expect(sink == 5 * cellCount * repetitions)
    }

    // MARK: - Variants

    /// Runs the pipeline like `GlyphPathProvider.resolvedPath`, minus the render tier:
    /// extraction tier lookup, transform resolution, and path copy on every call.
    private func resolvedPathWithoutRenderTier() -> CGPath? {
        let key = GlyphPathCache.ExtractionKey(character: character, font: font)
        guard
            let ctFont = GlyphPathCache.ctFont(for: font),
            let extracted = GlyphPathCache.extractedPath(for: key)
        else { return nil }

        let transform = GlyphLayoutResolver.resolve(
            layout: layout, path: extracted, font: ctFont, containerSize: size
        )
        return extracted.copy(using: [transform])
    }

    // MARK: - Helpers

    /// Returns the fastest average time per call, in nanoseconds, over `repetitions` runs of `body`.
    ///
    /// - Parameters:
    ///   - calls: The number of calls `body` makes per run.
    ///   - body: The work to time.
    private func nanosecondsPerCall(calls: Int, _ body: () -> Void) -> Double {
        let clock = ContinuousClock()
        var best = Double.infinity
        for _ in 0..<repetitions {
            let components = clock.measure(body).components
            let nanoseconds = Double(components.seconds) * 1e9 + Double(components.attoseconds) / 1e9
            best = min(best, nanoseconds / Double(calls))
        }
        return best
    }

    /// Formats a nanosecond value with one decimal place.
    private func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
