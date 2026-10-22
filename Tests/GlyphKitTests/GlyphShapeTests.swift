//
//  GlyphShapeTests.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 21.10.26.
//

import Testing
import SwiftUI
@testable import GlyphKit

// `GlyphShape` conforms to `View`, so its initializer is main-actor isolated.
@MainActor
@Suite("GlyphShape")
struct GlyphShapeTests {

    private let tolerance: CGFloat = 0.01
    private let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

    // MARK: - path(in:)

    /// Tight sizing: the glyph stays inside the rect and fills it along the constraining axis.
    @Test func tightSizingFillsRect() {
        let bounds = GlyphShape("A").path(in: rect).boundingRect

        #expect(isContained(bounds, in: rect))
        let fillsWidth = abs(bounds.width - rect.width) < tolerance
        let fillsHeight = abs(bounds.height - rect.height) < tolerance
        #expect(fillsWidth || fillsHeight)
    }

    /// Font-metrics sizing: a small glyph stays inside the rect and stays visually small.
    @Test func fontMetricsSizingKeepsSmallGlyphSmall() {
        let layout = GlyphLayout(sizing: .fontMetrics)
        let bounds = GlyphShape(".", layout: layout).path(in: rect).boundingRect

        #expect(isContained(bounds, in: rect))
        #expect(bounds.height < rect.height / 2)
    }

    /// A rect with a non-zero origin shifts the path by exactly that origin.
    @Test func nonZeroOriginOffsetsPath() {
        let shape = GlyphShape("g")
        let shiftedRect = rect.offsetBy(dx: 30, dy: 40)

        let base = shape.path(in: rect).boundingRect
        let shifted = shape.path(in: shiftedRect).boundingRect

        #expect(abs(shifted.minX - (base.minX + 30)) < tolerance)
        #expect(abs(shifted.minY - (base.minY + 40)) < tolerance)
        #expect(abs(shifted.width - base.width) < tolerance)
        #expect(abs(shifted.height - base.height) < tolerance)
    }

    /// The shape's path matches the shared pipeline's path for the same inputs.
    @Test func matchesPathProvider() throws {
        let layout = GlyphLayout(sizing: .fontMetrics, anchor: .bottomLeading)
        let font = GlyphKitFont.system(.georgia, isItalic: true)

        let shapeBounds = GlyphShape("3", font: font, layout: layout).path(in: rect).boundingRect
        let providerPath = try #require(GlyphPathProvider.resolvedPath(
            character: "3", font: font, layout: layout, size: rect.size
        ))
        let providerBounds = Path(providerPath).boundingRect

        #expect(abs(shapeBounds.minX - providerBounds.minX) < tolerance)
        #expect(abs(shapeBounds.minY - providerBounds.minY) < tolerance)
        #expect(abs(shapeBounds.width - providerBounds.width) < tolerance)
        #expect(abs(shapeBounds.height - providerBounds.height) < tolerance)
    }

    /// A character without an outline produces an empty path.
    @Test func characterWithoutOutlineIsEmpty() {
        #expect(GlyphShape(" ").path(in: rect).isEmpty)
    }

    // MARK: - inset(by:)

    /// Insetting is equivalent to laying the glyph out in the correspondingly smaller rect.
    @Test func insetMatchesSmallerRect() {
        let shape = GlyphShape("A")

        let inset = shape.inset(by: 10).path(in: rect).boundingRect
        let smaller = shape.path(in: rect.insetBy(dx: 10, dy: 10)).boundingRect

        #expect(isApproximatelyEqual(inset, smaller))
    }

    /// The inset glyph stays inside the inset rect.
    @Test func insetPathStaysInsideInsetRect() {
        let bounds = GlyphShape("W").inset(by: 10).path(in: rect).boundingRect

        #expect(isContained(bounds, in: rect.insetBy(dx: 10, dy: 10)))
    }

    /// Successive insets accumulate.
    @Test func insetsAccumulate() {
        let shape = GlyphShape("g")

        let chained = shape.inset(by: 4).inset(by: 6).path(in: rect).boundingRect
        let single = shape.inset(by: 10).path(in: rect).boundingRect

        #expect(isApproximatelyEqual(chained, single))
    }

    /// An inset larger than half the rect leaves no area, producing an empty path.
    @Test func oversizedInsetIsEmpty() {
        #expect(GlyphShape("A").inset(by: 60).path(in: rect).isEmpty)
    }

    // MARK: - Helpers

    /// Returns whether `lhs` and `rhs` have the same origin and size, allowing for floating-point tolerance.
    private func isApproximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) < tolerance
            && abs(lhs.minY - rhs.minY) < tolerance
            && abs(lhs.width - rhs.width) < tolerance
            && abs(lhs.height - rhs.height) < tolerance
    }

    /// Returns whether `inner` lies within `outer`, allowing for floating-point tolerance.
    private func isContained(_ inner: CGRect, in outer: CGRect) -> Bool {
        inner.minX >= outer.minX - tolerance
            && inner.minY >= outer.minY - tolerance
            && inner.maxX <= outer.maxX + tolerance
            && inner.maxY <= outer.maxY + tolerance
    }
}
