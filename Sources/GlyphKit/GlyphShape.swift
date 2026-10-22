//
//  GlyphShape.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 21.10.26.
//

import SwiftUI

/// A SwiftUI shape that outlines a single character as a vector glyph.
///
/// The glyph is extracted via `GlyphPathExtractor` and fitted into the shape's
/// rectangle via `GlyphLayoutResolver`, without baseline or Dynamic Type shifts.
/// As a `Shape`, it supports any fill or stroke style, `trim`, and use as a clip
/// or content shape.
///
/// If the font can't be resolved or the character has no outline (for example
/// a space), the shape's path is empty.
public struct GlyphShape: Shape {
    
    // MARK: - Public Properties
    
    /// The single character to outline.
    public let character: Character
    
    /// The font used for path extraction.
    public let font: GlyphKitFont
    
    /// Layout configuration: sizing, anchor, and offset.
    public let layout: GlyphLayout
    
    // MARK: - Init
    
    /// Creates a `GlyphShape` with explicit configuration.
    ///
    /// - Parameters:
    ///   - character: The character to outline.
    ///   - font: The font for extraction. Defaults to `.default`.
    ///   - layout: The layout configuration. Defaults to `.default`.
    public init(
        _ character: Character,
        font: GlyphKitFont = .default,
        layout: GlyphLayout = .default
    ) {
        self.character = character
        self.font = font
        self.layout = layout
    }
    
    // MARK: - Shape
    
    /// Returns the glyph outline laid out within `rect`.
    ///
    /// - Parameter rect: The rectangle the glyph is fitted into; its origin may be non-zero.
    /// - Returns: The glyph path, or an empty path if the glyph can't be resolved.
    nonisolated public func path(in rect: CGRect) -> Path {
        guard let path = GlyphPathProvider.resolvedPath(
            character: character, font: font, layout: layout, size: rect.size
        ) else { return Path() }
        return Path(path).offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

// MARK: - Previews

#if DEBUG

#Preview("GlyphShape — multiple") {
    let characters: [Character] = ["A", "g", "&", "3", "ß", "?"]
    let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink]
    
    return LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 24) {
        ForEach(Array(zip(characters, colors)), id: \.0.description) { char, color in
            GlyphShape(char)
                .fill(color)
                .frame(width: 80, height: 80)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    .padding()
}

#Preview("GlyphShape — layout variants") {
    let items: [(Character, GlyphLayout, Color)] = [
        ("=", GlyphLayout(sizing: .tight, anchor: .center, offset: .zero), .blue),
        ("=", GlyphLayout(sizing: .fontMetrics, anchor: .center, offset: .zero), .blue),
        ("'", GlyphLayout(sizing: .tight, anchor: .center, offset: .zero), .red),
        ("'", GlyphLayout(sizing: .fontMetrics, anchor: .center, offset: .zero), .red),
        (".", GlyphLayout(sizing: .tight, anchor: .center, offset: .zero), .green),
        (".", GlyphLayout(sizing: .fontMetrics, anchor: .center, offset: .zero), .green),
        (".", GlyphLayout(sizing: .fontMetrics, anchor: .bottom, offset: .zero), .orange),
        (".", GlyphLayout(sizing: .fontMetrics, anchor: .bottomLeading, offset: .zero), .purple),
    ]
    
    return LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 16) {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            GlyphShape(item.0, layout: item.1)
                .fill(item.2)
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    .padding()
}

#Preview("README — examples") {
    HStack(spacing: 16) {
        GlyphShape("Å")
            .fill(.primary)
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        
        GlyphShape(".",
                   layout: GlyphLayout(sizing: .fontMetrics, anchor: .center, offset: .zero)
        )
        .fill(.orange)
        .frame(width: 80, height: 80)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        
        GlyphShape("3",
                   font: .system(.georgia, isBold: true, isItalic: true),
                   layout: .default
        )
        .fill(.blue)
        .frame(width: 80, height: 80)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding()
}

#Preview("README — notebook grid") {
    let items: [(Character, GlyphSizing)] = [
        ("3", .tight),
        ("=", .fontMetrics),
        ("8", .tight)
    ]
    
    HStack(spacing: 0) {
        ForEach(items, id: \.0) { digit, sizing in
            GlyphShape(digit,
                       font: .system(.georgia, isItalic: true),
                       layout: GlyphLayout(
                        sizing: sizing,
                        anchor: sizing == .tight ? .trailing : .center,
                        offset: .zero
                       )
            )
            .fill(.primary)
            .frame(width: 56, height: 56)
            .border(Color(.systemGray4), width: 0.5)
        }
    }
    .padding()
}

#Preview("GlyphShape — strokes") {
    HStack(spacing: 16) {
        GlyphShape("A")
            .stroke(.blue, lineWidth: 2)

        GlyphShape("&")
            .stroke(.red, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))

        GlyphShape("g")
            .fill(.yellow)
            .stroke(.orange, lineWidth: 3)
    }
    .frame(height: 80)
    .padding()
}

#Preview("GlyphShape — gradients") {
    HStack(spacing: 16) {
        GlyphShape("G", font: .system(.futura, isBold: true))
            .fill(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))

        GlyphShape("@")
            .fill(AngularGradient(colors: [.red, .yellow, .green, .blue, .red], center: .center))

        GlyphShape("ß", font: .system(.baskerville))
            .fill(RadialGradient(colors: [.orange, .brown], center: .center, startRadius: 0, endRadius: 50))
    }
    .frame(height: 80)
    .padding()
}

#Preview("GlyphShape — clipping content") {
    HStack(spacing: 0) {
        ForEach([Color.red, .orange, .yellow, .green, .blue, .purple], id: \.self) { color in
            color
        }
    }
    .frame(width: 200, height: 200)
    .clipShape(GlyphShape("R", font: .system(.americanTypewriter, isBold: true)))
    .padding()
}

#Preview("GlyphShape — trim animation") {
    TrimmedGlyphPreview()
}

/// Draws a glyph's outline progressively by animating `trim(from:to:)`.
private struct TrimmedGlyphPreview: View {

    /// The fraction of the outline currently drawn, from 0 to 1.
    @State private var progress: CGFloat = 0

    var body: some View {
        GlyphShape("S", font: .system(.georgia, isItalic: true))
            .trim(from: 0, to: progress)
            .stroke(.indigo, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .frame(width: 160, height: 160)
            .padding()
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    progress = 1
                }
            }
    }
}

#endif
