//
//  GlyphLayout.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//

import CoreGraphics
import SwiftUI

/// Defines how a glyph is rendered within an external container.
///
/// The rendering involves two nested problems:
///
/// 1. **Sizing** (`GlyphSizing`): how the glyph path is sized within
///    its typographic bounding box — either tightly by its exact path bounds,
///    or relative to the full vertical extent of the font.
///
/// 2. **Placement**: how that typographic box is positioned
///    within the external container, controlled by `anchor` and `offset`.
///
/// These two concerns are independent but together fully describe
/// how a glyph occupies its external container.
public struct GlyphLayout: Sendable {
    public var sizing: GlyphSizing
    public var anchor: UnitPoint
    public var offset: CGPoint

    public static let `default` = GlyphLayout(
        sizing: .tight,
        anchor: .center,
        offset: .zero
    )
}
