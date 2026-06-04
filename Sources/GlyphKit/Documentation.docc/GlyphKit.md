
# ``GlyphKit``

Render any font glyph into a SwiftUI view with point-precise sizing.

## Overview

GlyphKit extracts vector glyph outlines via Core Text and renders them 
into a SwiftUI `Canvas` — without baseline shifts, Dynamic Type interference, 
or UILabel rendering pipeline.

Two sizing modes give you full control: **tight** fills the container 
edge to edge, **typographic** preserves the glyph's visual weight 
within the font's vertical metrics.

## Topics

### View

- ``GlyphView``

### Layout

- ``GlyphLayout``
- ``GlyphSizing``

### Font

- ``GlyphKitFont``

### Extraction

- ``GlyphPathExtractor``
- ``GlyphLayoutResolver``
