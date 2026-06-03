//
//  GlyphKitFont.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//

import CoreText
import UIKit

/// Represents a font used for glyph path extraction, with optional bold and italic style.
public enum GlyphKitFont: Sendable {

    /// A built-in font available on iOS without bundle registration.
    public enum SystemFont: Sendable {
        /// San Francisco — the default iOS system font.
        case sanFrancisco
        /// SF Mono — monospaced variant of San Francisco.
        case sanFranciscoMono
        /// Helvetica Neue.
        case helveticaNeue
        /// Times New Roman — classic serif font.
        case timesNewRoman
        /// Georgia — elegant serif font.
        case georgia
        /// Courier New — monospaced serif font.
        case courierNew
        /// Avenir — geometric sans-serif.
        case avenir
        /// Baskerville — transitional serif font.
        case baskerville
        /// Futura — geometric sans-serif with a modern feel.
        case futura
        /// American Typewriter — slab serif with a typewriter character.
        case americanTypewriter
    }

    /// A built-in system font with optional bold and italic style.
    case system(SystemFont, isBold: Bool = false, italic: Bool = false)
    /// A custom font registered in the app bundle, referenced by PostScript name.
    case custom(String, isBold: Bool = false, italic: Bool = false)

    /// The default font: San Francisco, non-bold, non-italic.
    public static let `default` = GlyphKitFont.system(.sanFrancisco)

    /// Returns a `CTFont` for internal glyph path extraction.
    var ctFont: CTFont? {
        switch self {
        case .system(let systemFont, let isBold, let italic):
            let uiFont = resolveSystemFont(systemFont)
            return applyStyle(to: uiFont, isBold: isBold, italic: italic)
        case .custom(let name, let isBold, let italic):
            guard let uiFont = UIFont(name: name, size: extractionSize) else { return nil }
            return applyStyle(to: uiFont, isBold: isBold, italic: italic)
        }
    }

    // MARK: - Private

    /// The point size used internally for path extraction; visual size is determined by the container.
    private static let extractionSize: CGFloat = 512

    private var extractionSize: CGFloat { Self.extractionSize }

    /// Resolves a `SystemFont` case to a `UIFont` at extraction size.
    private func resolveSystemFont(_ systemFont: SystemFont) -> UIFont {
        switch systemFont {
        case .sanFrancisco:
            return .systemFont(ofSize: extractionSize)
        case .sanFranciscoMono:
            return .monospacedSystemFont(ofSize: extractionSize, weight: .regular)
        case .helveticaNeue:
            return UIFont(name: "HelveticaNeue", size: extractionSize) ?? .systemFont(ofSize: extractionSize)
        case .timesNewRoman:
            return UIFont(name: "TimesNewRomanPSMT", size: extractionSize) ?? .systemFont(ofSize: extractionSize)
        case .georgia:
            return UIFont(name: "Georgia", size: extractionSize) ?? .systemFont(ofSize: extractionSize)
        case .courierNew:
            return UIFont(name: "CourierNewPSMT", size: extractionSize) ?? .systemFont(ofSize: extractionSize)
        case .avenir:
            return UIFont(name: "Avenir-Book", size: extractionSize) ?? .systemFont(ofSize: extractionSize)
        case .baskerville:
            return UIFont(name: "Baskerville", size: extractionSize) ?? .systemFont(ofSize: extractionSize)
        case .futura:
            return UIFont(name: "Futura-Medium", size: extractionSize) ?? .systemFont(ofSize: extractionSize)
        case .americanTypewriter:
            return UIFont(name: "AmericanTypewriter", size: extractionSize) ?? .systemFont(ofSize: extractionSize)
        }
    }

    /// Applies bold and italic traits to a `UIFont` and returns it as `CTFont`.
    private func applyStyle(to font: UIFont, isBold: Bool, italic: Bool) -> CTFont {
        var traits = UIFontDescriptor.SymbolicTraits()
        if isBold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        let descriptor = font.fontDescriptor.withSymbolicTraits(traits) ?? font.fontDescriptor
        return CTFontCreateWithFontDescriptor(descriptor as CTFontDescriptor, extractionSize, nil)
    }
}
