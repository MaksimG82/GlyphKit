//
//  GlyphLayoutResolver.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//


import CoreGraphics
import SwiftUI

import CoreGraphics
import SwiftUI

/// Resolves a `GlyphLayout` into a `CGAffineTransform` ready to apply to a glyph path in Canvas.
///
/// The resolution happens in three sequential steps:
/// 1. Place the glyph path into its internal container (flip Y-axis, apply font metrics if needed)
/// 2. Scale the internal container to fit the external container
/// 3. Position the internal container within the external container via anchor and offset
public enum GlyphLayoutResolver {

    /// Resolves a `GlyphLayout` into a `CGAffineTransform` ready to apply to a glyph path in Canvas.
    ///
    /// Combines three sequential transforms:
    /// 1. Places the glyph path into its internal container (Y-flip + normalization)
    /// 2. Scales the internal container to fit the external container
    /// 3. Positions the internal container within the external container via anchor and offset
    ///
    /// - Parameters:
    ///   - layout: The layout configuration.
    ///   - path: The glyph path from `GlyphPathExtractor`.
    ///   - font: The font used for metrics in `.fontMetrics` sizing.
    ///   - containerSize: The size of the external container.
    public static func resolve(
        layout: GlyphLayout,
        path: CGPath,
        font: CTFont,
        containerSize: CGSize
    ) -> CGAffineTransform {
        let internalSize = internalContainerSize(sizing: layout.sizing, path: path, font: font)
        let scale = scaleFactor(internalSize: internalSize, containerSize: containerSize)

        let toInternalContainer = transformToInternalContainer(sizing: layout.sizing, path: path, font: font)
        let toExternalContainer = transformToExternalContainer(scaleFactor: scale)
        let placement = transformPlacement(scaleFactor: scale, internalSize: internalSize, anchor: layout.anchor, offset: layout.offset, containerSize: containerSize)

        return toInternalContainer.concatenating(toExternalContainer).concatenating(placement)
    }

    /// Step 1. Returns a transform that places the glyph path into its internal container.
    ///
    /// Performs two operations in order:
    /// 1. Normalizes the glyph path to (0, 0) in Core Text coordinates,
    ///    accounting for font metrics offset if `.fontMetrics` sizing is used.
    /// 2. Flips the Y-axis to match Canvas coordinate system (Y goes down).
    ///
    /// - Parameters:
    ///   - sizing: Determines whether font metrics are used for vertical positioning.
    ///   - path: The glyph path from `GlyphPathExtractor`.
    ///   - font: The font used to retrieve descent for `.fontMetrics` sizing.
    static func transformToInternalContainer(
        sizing: GlyphSizing,
        path: CGPath,
        font: CTFont
    ) -> CGAffineTransform {
        let bounds = path.boundingBoxOfPath
        let internalSize = internalContainerSize(sizing: sizing, path: path, font: font)

        let normalizeX = -bounds.minX

        let normalizeY: CGFloat
        switch sizing {
        case .tight:
            normalizeY = -bounds.minY
        case .fontMetrics:
            normalizeY = CTFontGetDescent(font)
        }

        let normalize = CGAffineTransform(translationX: normalizeX, y: normalizeY)

        let flipY = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: 0, y: -internalSize.height)

        return normalize.concatenating(flipY)
    }

    /// Step 2. Returns a uniform scale transform that fits the internal container into the external container.
    ///
    /// Use `scaleFactor(internalSize:containerSize:)` to compute the scale factor before calling this method.
    ///
    /// - Parameter scaleFactor: The uniform scale factor computed from internal and external container sizes.
    static func transformToExternalContainer(
        scaleFactor: CGFloat
    ) -> CGAffineTransform {
        CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
    }

    /// Step 3. Returns a transform that positions the scaled internal container
    /// within the external container according to anchor and offset.
    ///
    /// The anchor point is applied to the remaining space after the scaled glyph
    /// is placed — `.topLeading` pushes the glyph to the top-left,
    /// `.center` centers it, `.bottomTrailing` to the bottom-right, and so on.
    /// The offset is then applied in points relative to that anchor position.
    ///
    /// - Parameters:
    ///   - scaleFactor: The uniform scale factor from `scaleFactor(internalSize:containerSize:)`.
    ///   - internalSize: The size of the internal container before scaling.
    ///   - anchor: The anchor point within the external container.
    ///   - offset: Additional offset in points. Positive x moves right, positive y moves down.
    ///   - containerSize: The size of the external container.
    static func transformPlacement(
        scaleFactor: CGFloat,
        internalSize: CGSize,
        anchor: UnitPoint,
        offset: CGPoint,
        containerSize: CGSize
    ) -> CGAffineTransform {
        let scaledWidth = internalSize.width * scaleFactor
        let scaledHeight = internalSize.height * scaleFactor

        let placementX = anchor.x * (containerSize.width - scaledWidth) + offset.x
        let placementY = anchor.y * (containerSize.height - scaledHeight) + offset.y

        return CGAffineTransform(translationX: placementX, y: placementY)
    }

    // MARK: - Helpers

    static func internalContainerSize(
        sizing: GlyphSizing,
        path: CGPath,
        font: CTFont
    ) -> CGSize {
        switch sizing {
        case .tight:
            let bounds = path.boundingBoxOfPath
            return CGSize(width: bounds.width, height: bounds.height)
        case .fontMetrics:
            let height = CTFontGetAscent(font) + CTFontGetDescent(font)
            let width = path.boundingBoxOfPath.width
            return CGSize(width: width, height: height)
        }
    }
    
    /// Returns the uniform scale factor that fits the internal container into the external container.
    ///
    /// Computed as the minimum of the two axis ratios to preserve aspect ratio.
    /// The constraining axis fills the external container exactly;
    /// the other axis will have remaining space distributed by anchor in Step 3.
    ///
    /// - Parameters:
    ///   - internalSize: The size of the internal container.
    ///   - containerSize: The size of the external container.
    static func scaleFactor(
        internalSize: CGSize,
        containerSize: CGSize
    ) -> CGFloat {
        min(
            containerSize.width / internalSize.width,
            containerSize.height / internalSize.height
        )
    }
}
