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
    
    /// Determines how the glyph path is sized within its internal container.
    public var sizing: GlyphSizing

    /// The anchor point within the external container. Use `UnitPoint` presets such as `.center`, `.topLeading`, etc.
    public var anchor: UnitPoint

    /// Additional offset in points applied after anchor placement. Positive x moves right, positive y moves down.
    public var offset: CGPoint

    /// A centered glyph with tight sizing and no offset.
    public static let `default` = GlyphLayout(
        sizing: .tight,
        anchor: .center,
        offset: .zero
    )
    
    /// Creates a new `GlyphLayout` with the specified sizing, anchor, and offset.
    /// - Parameters:
    ///   - sizing: Determines how the glyph path is sized within its internal container.
    ///   - anchor: The anchor point within the external container.
    ///   - offset: Additional offset in points. Positive x moves right, positive y moves down.
    public init(
        sizing: GlyphSizing = .tight,
        anchor: UnitPoint = .center,
        offset: CGPoint = .zero
    ) {
        self.sizing = sizing
        self.anchor = anchor
        self.offset = offset
    }
}
