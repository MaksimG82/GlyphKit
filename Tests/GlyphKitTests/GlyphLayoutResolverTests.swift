//
//  GlyphLayoutResolverTests.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//

import Testing
import CoreGraphics
import CoreText
@testable import GlyphKit

@Suite("GlyphLayoutResolver")
struct GlyphLayoutResolverTests {

    // MARK: - scaleFactor

    /// Width is the constraining axis — scale is determined by width ratio.
    @Test func scaleFactorConstrainedByWidth() {
        let scale = GlyphLayoutResolver.scaleFactor(
            internalSize: CGSize(width: 100, height: 50),
            containerSize: CGSize(width: 44, height: 44)
        )
        #expect(abs(scale - 44.0 / 100.0) < 0.0001)
    }

    /// Height is the constraining axis — scale is determined by height ratio.
    @Test func scaleFactorConstrainedByHeight() {
        let scale = GlyphLayoutResolver.scaleFactor(
            internalSize: CGSize(width: 50, height: 100),
            containerSize: CGSize(width: 44, height: 44)
        )
        #expect(abs(scale - 44.0 / 100.0) < 0.0001)
    }

    /// Square glyph in square container — both axes give the same scale.
    @Test func scaleFactorSquareInSquare() {
        let scale = GlyphLayoutResolver.scaleFactor(
            internalSize: CGSize(width: 100, height: 100),
            containerSize: CGSize(width: 44, height: 44)
        )
        #expect(abs(scale - 44.0 / 100.0) < 0.0001)
    }

    // MARK: - internalContainerSize

    /// In tight mode, internal container size equals the glyph path bounding box.
    @Test func internalContainerSizeTight() {
        let font = CTFontCreateWithName("HelveticaNeue" as CFString, 512, nil)
        let path = CGMutablePath()
        path.addRect(CGRect(x: 10, y: 20, width: 80, height: 60))
        let size = GlyphLayoutResolver.internalContainerSize(
            sizing: .tight,
            path: path,
            font: font
        )
        #expect(abs(size.width - 80) < 0.0001)
        #expect(abs(size.height - 60) < 0.0001)
    }

    /// In fontMetrics mode, height equals ascent + descent, width equals path bounds width.
    @Test func internalContainerSizeFontMetrics() {
        let font = CTFontCreateWithName("HelveticaNeue" as CFString, 512, nil)
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: 80, height: 60))
        let size = GlyphLayoutResolver.internalContainerSize(
            sizing: .fontMetrics,
            path: path,
            font: font
        )
        let expectedHeight = CTFontGetAscent(font) + CTFontGetDescent(font)
        #expect(abs(size.width - 80) < 0.0001)
        #expect(abs(size.height - expectedHeight) < 0.0001)
    }

    // MARK: - transformToInternalContainer

    /// After transform, a point at the top of the glyph should have a smaller Y than a point at the bottom.
    /// This verifies that the Y-axis flip is applied correctly for Canvas coordinates.
    @Test func internalContainerFlipsYAxis() {
        guard let ctFont = GlyphKitFont.default.ctFont,
              let path = GlyphPathExtractor.path(for: "A") else {
            Issue.record("Failed to extract glyph path")
            return
        }
        let bounds = path.boundingBoxOfPath
        let transform = GlyphLayoutResolver.transformToInternalContainer(
            sizing: .tight,
            path: path,
            font: ctFont
        )
        let topPoint = CGPoint(x: bounds.midX, y: bounds.maxY).applying(transform)
        let bottomPoint = CGPoint(x: bounds.midX, y: bounds.minY).applying(transform)

        #expect(topPoint.y < bottomPoint.y)
    }

    /// After transform with tight sizing, the bottom-left of the glyph should be at (0, 0).
    @Test func internalContainerNormalizesToOrigin() {
        guard let ctFont = GlyphKitFont.default.ctFont,
              let path = GlyphPathExtractor.path(for: "A") else {
            Issue.record("Failed to extract glyph path")
            return
        }
        let bounds = path.boundingBoxOfPath
        let transform = GlyphLayoutResolver.transformToInternalContainer(
            sizing: .tight,
            path: path,
            font: ctFont
        )
        let bottomLeft = CGPoint(x: bounds.minX, y: bounds.minY).applying(transform)
        #expect(abs(bottomLeft.x) < 0.0001)
        #expect(abs(bottomLeft.y) < 0.0001)
    }

    // MARK: - transformPlacement

    /// With center anchor and equal sizes, translation should be equal on both axes.
    @Test func placementCenterSymmetric() {
        let containerSize = CGSize(width: 44, height: 44)
        let internalSize = CGSize(width: 20, height: 20)
        let scale = GlyphLayoutResolver.scaleFactor(
            internalSize: internalSize,
            containerSize: containerSize
        )
        let transform = GlyphLayoutResolver.transformPlacement(
            scaleFactor: scale,
            internalSize: internalSize,
            anchor: .center,
            offset: .zero,
            containerSize: containerSize
        )
        #expect(abs(transform.tx - transform.ty) < 0.0001)
    }

    /// With topLeading anchor and glyph filling the container exactly, translation should be zero.
    @Test func placementTopLeadingZeroOffset() {
        let transform = GlyphLayoutResolver.transformPlacement(
            scaleFactor: 1.0,
            internalSize: CGSize(width: 44, height: 44),
            anchor: .topLeading,
            offset: .zero,
            containerSize: CGSize(width: 44, height: 44)
        )
        #expect(abs(transform.tx) < 0.0001)
        #expect(abs(transform.ty) < 0.0001)
    }
}
