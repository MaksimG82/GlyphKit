# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

GlyphKit is a Swift Package (iOS 17+, Swift 6) that renders a single font glyph as a vector outline inside a SwiftUI `Canvas`, bypassing `UILabel`/text rendering entirely (no baseline shifts, no Dynamic Type interference). It extracts the glyph's `CGPath` via Core Text and draws it with point-precise sizing/placement.

## Commands

Build and test via `xcodebuild` (this is a library package, not an app — there's no `swift test` CI path used here, though it should work locally too):

```bash
# Run all tests
xcodebuild test -scheme GlyphKit -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test suite or test (xcodebuild -only-testing)
xcodebuild test -scheme GlyphKit -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:GlyphKitTests/GlyphLayoutResolverTests

xcodebuild test -scheme GlyphKit -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:GlyphKitTests/GlyphLayoutResolverTests/scaleFactorConstrainedByWidth
```

Tests use the `Testing` framework (`@Suite` / `@Test` / `#expect`), not XCTest.

CI (`.github/workflows/tests.yml`) runs the same `xcodebuild test` command on `macos-15` against `iPhone 16` simulator for pushes/PRs to `main`/`develop`. A second workflow (`deploy-documentation.yml`) builds the DocC archive via `xcodebuild docbuild` and publishes it to GitHub Pages on the same branches.

## Architecture

The rendering pipeline has four pieces that map directly to the two concerns called out in `GlyphLayout`'s doc comment — **sizing** (how the glyph fills its own bounding box) and **placement** (how that box sits inside the container the caller gives it):

1. **`GlyphPathExtractor`** — turns a `Character` + `GlyphKitFont` into a `CGPath` via `CTFontCreatePathForGlyph`. Font-agnostic, stateless, single static method.
2. **`GlyphKitFont`** — an enum (`.system(SystemFont, isBold:isItalic:)` or `.custom(String, isBold:isItalic:)`) that resolves to a `CTFont`. All glyph extraction happens at a fixed internal `extractionSize` of 512pt regardless of the view's actual on-screen size — visual size is entirely a function of the transform computed in step 3, not the extraction size.
3. **`GlyphSizing`** — `.tight` (glyph's own path bounds fill the container, so small glyphs like `.` or `-` scale up) vs `.fontMetrics` (glyph is placed within the font's full ascent+descent range, so small glyphs stay visually small relative to others, matching how they'd look in a line of text).
4. **`GlyphLayoutResolver`** — the core geometry. `resolve(layout:path:font:containerSize:)` builds a single `CGAffineTransform` by concatenating three sub-transforms, each independently testable and each with a clear responsibility:
   - `transformToInternalContainer` — normalizes the path to origin (0,0) accounting for sizing mode, then flips Y (Core Text is Y-up, Canvas is Y-down)
   - `transformToExternalContainer` — uniform scale (`scaleFactor`, the min of width/height ratios, so aspect ratio is preserved) that fits the internal container into the caller's container
   - `transformPlacement` — positions the scaled glyph within the external container using `UnitPoint` anchor + `CGPoint` offset, applied to leftover space after scaling
5. **`GlyphLayout`** — the public struct bundling `sizing`, `anchor`, and `offset` that callers configure; `GlyphLayoutResolver` consumes it.
6. **`GlyphView`** — the public SwiftUI entry point. Draws in a `Canvas`, calling the extractor and resolver per-frame and filling the transformed path with `color`. Marked `.accessibilityHidden(true)` since it renders decorative/typographic content, not readable text.

When changing geometry logic, prefer testing the individual static methods on `GlyphLayoutResolver` (`scaleFactor`, `transformToInternalContainer`, `transformPlacement`, `internalContainerSize`) rather than only the composed `resolve(...)` — the existing test suite (`GlyphLayoutResolverTests`) is structured this way, one `@Suite`-nested group of tests per method.

## Notes

- `GlyphKitFont.SystemFont` cases map to actual iOS font PostScript names (e.g. `.timesNewRoman` → `"TimesNewRomanPSMT"`) with a `.systemFont` fallback if the named font isn't installed — check `GlyphKitFont.swift` before adding a new system font case.
- SwiftUI `#Preview` blocks in `GlyphView.swift` double as living usage examples (multiple glyphs, layout variants, the README's own snippets) — keep them in sync with README examples when changing the public API.
