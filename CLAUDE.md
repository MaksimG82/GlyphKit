# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

GlyphKit is a Swift Package (iOS 17+, Swift 6) that renders a single font glyph as a vector outline inside a SwiftUI `Canvas`, bypassing `UILabel`/text rendering entirely (no baseline shifts, no Dynamic Type interference). It extracts the glyph's `CGPath` via Core Text and draws it with point-precise sizing/placement.

## Commands

The user runs all builds and tests themselves. Do not run `xcodebuild build` or `xcodebuild test`, and do not treat a successful build/test run as a required verification step before considering a task done — only run these commands if explicitly asked to.

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

The rendering pipeline has these pieces that map directly to the two concerns called out in `GlyphLayout`'s doc comment — **sizing** (how the glyph fills its own bounding box) and **placement** (how that box sits inside the container the caller gives it):

1. **`GlyphPathExtractor`** — turns a `Character` + `GlyphKitFont` into a `CGPath` via `CTFontCreatePathForGlyph`. Font-agnostic, stateless, single static method.
2. **`GlyphKitFont`** — an enum (`.system(SystemFont, isBold:isItalic:)` or `.custom(String, isBold:isItalic:)`) that resolves to a `CTFont`. All glyph extraction happens at a fixed internal `extractionSize` of 512pt regardless of the view's actual on-screen size — visual size is entirely a function of the transform computed in step 3, not the extraction size.
3. **`GlyphSizing`** — `.tight` (glyph's own path bounds fill the container, so small glyphs like `.` or `-` scale up) vs `.fontMetrics` (glyph is placed within the font's full ascent+descent range, so small glyphs stay visually small relative to others, matching how they'd look in a line of text).
4. **`GlyphLayoutResolver`** — the core geometry. `resolve(layout:path:font:containerSize:)` builds a single `CGAffineTransform` by concatenating three sub-transforms, each independently testable and each with a clear responsibility:
   - `transformToInternalContainer` — normalizes the path to origin (0,0) accounting for sizing mode, then flips Y (Core Text is Y-up, Canvas is Y-down)
   - `transformToExternalContainer` — uniform scale (`scaleFactor`, the min of width/height ratios, so aspect ratio is preserved) that fits the internal container into the caller's container
   - `transformPlacement` — positions the scaled glyph within the external container using `UnitPoint` anchor + `CGPoint` offset, applied to leftover space after scaling
5. **`GlyphLayout`** — the public struct bundling `sizing`, `anchor`, and `offset` that callers configure; `GlyphLayoutResolver` consumes it.
6. **`GlyphPathProvider`** — internal helper that runs extraction (step 1) and resolution (step 4) through the three tiers of `GlyphPathCache`, returning a ready-to-fill path for a container at origin (0,0). Shared by both public renderers below. `GlyphPathCache` tiers: **font** (`GlyphKitFont` → resolved `CTFont`; building a `CTFont` dominates the cost of a render miss, so it's cached; fonts that fail to resolve are not stored), **extraction** (`character` + `font` → raw outline), **render** (+ `layout` + `size` → transformed path). `GlyphPathExtractor` still builds its own `CTFont` on an extraction miss.
7. **`GlyphShape`** — a public SwiftUI `InsettableShape`. `path(in:)` shrinks `rect` by the accumulated `insetAmount`, gets the path from `GlyphPathProvider` for that rect's size, and offsets it by that rect's origin (the cache is keyed on size only). `inset(by:)` refits the glyph into the smaller rect — the outline itself is not offset — which is what makes `strokeBorder` keep the stroke inside the frame. Returns an empty `Path` when the glyph can't be resolved or the inset rect has no area. Supports any fill/stroke style, `strokeBorder`, `trim`, and use as a clip or content shape.
8. **`GlyphView`** — **deprecated** in favor of `GlyphShape(...).fill(color)`; kept for source compatibility, no previews. SwiftUI view that draws in a `Canvas`, filling the path from `GlyphPathProvider` with `color`. Marked `.accessibilityHidden(true)` since it renders decorative/typographic content, not readable text.

When changing geometry logic, prefer testing the individual static methods on `GlyphLayoutResolver` (`scaleFactor`, `transformToInternalContainer`, `transformPlacement`, `internalContainerSize`) rather than only the composed `resolve(...)` — the existing test suite (`GlyphLayoutResolverTests`) is structured this way, one `@Suite`-nested group of tests per method.

## Notes

- `GlyphKitFont.SystemFont` cases map to actual iOS font PostScript names (e.g. `.timesNewRoman` → `"TimesNewRomanPSMT"`) with a `.systemFont` fallback if the named font isn't installed — check `GlyphKitFont.swift` before adding a new system font case.
- SwiftUI `#Preview` blocks in `GlyphShape.swift` double as living usage examples (multiple glyphs, layout variants, Shape styling, the README's own snippets) — keep them in sync with README examples when changing the public API.
- New declarations use `///` DocC doc comments: a one-line summary, expanded with `- Parameters:`/`- Returns:` for non-trivial functions (see `GlyphShape.swift`, `GlyphLayoutResolver.swift`). Follow this for internal/private declarations too, not just `public` API.
- When adding new functionality — whether public API or significant internal implementation (e.g. caching strategy) — update the corresponding documentation in the same change: DocC `///` comments, and README.md where relevant. The deploy-documentation.yml workflow publishes whatever documentation exists; it does not verify completeness or accuracy.
