
# ``GlyphKit``

Render any font glyph into a SwiftUI view with point-precise sizing.

## Overview

GlyphKit extracts vector glyph outlines via Core Text and exposes them 
as a SwiftUI `Shape` — without baseline shifts, Dynamic Type interference, 
or UILabel/NSTextField rendering pipeline. Fill, stroke, trim, or clip to a glyph 
like any other shape.

Two sizing modes give you full control: **tight** fills the container 
edge to edge, **typographic** preserves the glyph's visual weight 
within the font's vertical metrics.

## Topics

### Shape

- ``GlyphShape``

### Layout

- ``GlyphLayout``
- ``GlyphSizing``

### Font

- ``GlyphKitFont``

### Extraction

- ``GlyphPathExtractor``
- ``GlyphLayoutResolver``

### Deprecated

- ``GlyphView``
