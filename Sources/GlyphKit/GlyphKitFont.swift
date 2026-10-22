//
//  GlyphKitFont.swift
//  GlyphKit
//
//  Created by Maksim Gaisin on 02.06.26.
//

import CoreText
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Represents a font used for glyph path extraction, with optional bold and italic style.
public enum GlyphKitFont: Sendable, Hashable {

    /// A built-in font available on Apple platforms without bundle registration.
    public enum SystemFont: Sendable, Hashable {
        /// San Francisco — the default system font.
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
    case system(SystemFont, isBold: Bool = false, isItalic: Bool = false)
    /// A custom font registered in the app bundle, referenced by PostScript name.
    case custom(String, isBold: Bool = false, isItalic: Bool = false)

    /// The default font: San Francisco, non-bold, non-italic.
    public static let `default` = GlyphKitFont.system(.sanFrancisco)

    /// Returns a `CTFont` for internal glyph path extraction, or `nil` if a custom font isn't installed.
    var ctFont: CTFont? {
        switch self {
        case .system(let systemFont, let isBold, let isItalic):
            return applyStyle(to: resolveSystemFont(systemFont), isBold: isBold, isItalic: isItalic)
        case .custom(let name, let isBold, let isItalic):
            guard let font = namedFont(name) else { return nil }
            return applyStyle(to: font, isBold: isBold, isItalic: isItalic)
        }
    }

    // MARK: - Private

    /// The point size used internally for path extraction; visual size is determined by the container.
    private static let extractionSize: CGFloat = 512

    private var extractionSize: CGFloat { Self.extractionSize }

    /// Resolves a `SystemFont` case to a `CTFont` at extraction size.
    ///
    /// Named fonts fall back to the system font when they aren't installed.
    private func resolveSystemFont(_ systemFont: SystemFont) -> CTFont {
        switch systemFont {
        case .sanFrancisco:
            return systemUIFont()
        case .sanFranciscoMono:
            return monospacedSystemFont()
        case .helveticaNeue:
            return namedFont("HelveticaNeue") ?? systemUIFont()
        case .timesNewRoman:
            return namedFont("TimesNewRomanPSMT") ?? systemUIFont()
        case .georgia:
            return namedFont("Georgia") ?? systemUIFont()
        case .courierNew:
            return namedFont("CourierNewPSMT") ?? systemUIFont()
        case .avenir:
            return namedFont("Avenir-Book") ?? systemUIFont()
        case .baskerville:
            return namedFont("Baskerville") ?? systemUIFont()
        case .futura:
            return namedFont("Futura-Medium") ?? systemUIFont()
        case .americanTypewriter:
            return namedFont("AmericanTypewriter") ?? systemUIFont()
        }
    }

    /// Returns the platform's system UI font (San Francisco) at extraction size.
    private func systemUIFont() -> CTFont {
        CTFontCreateUIFontForLanguage(.system, extractionSize, nil)
            ?? CTFontCreateWithName("Helvetica" as CFString, extractionSize, nil)
    }

    /// Returns SF Mono at extraction size.
    ///
    /// Core Text has no public API for SF Mono, so this goes through the platform font
    /// class, which is toll-free bridged to `CTFont`.
    private func monospacedSystemFont() -> CTFont {
        #if canImport(UIKit)
        return UIFont.monospacedSystemFont(ofSize: extractionSize, weight: .regular) as CTFont
        #elseif canImport(AppKit)
        return NSFont.monospacedSystemFont(ofSize: extractionSize, weight: .regular) as CTFont
        #else
        return systemUIFont()
        #endif
    }

    /// Returns the installed font with the given name at extraction size, or `nil` if it isn't installed.
    ///
    /// `CTFontCreateWithName` never fails — it silently substitutes a fallback font —
    /// so the result is accepted only when its PostScript or full name matches `name`.
    ///
    /// - Parameter name: The font's PostScript name (or full name).
    /// - Returns: The matching font, or `nil` if Core Text substituted a different one.
    private func namedFont(_ name: String) -> CTFont? {
        let font = CTFontCreateWithName(name as CFString, extractionSize, nil)
        let postScriptName = CTFontCopyPostScriptName(font) as String
        let fullName = CTFontCopyFullName(font) as String
        return (postScriptName == name || fullName == name) ? font : nil
    }

    /// Applies bold and italic traits to a font, keeping the original if the styled variant doesn't exist.
    private func applyStyle(to font: CTFont, isBold: Bool, isItalic: Bool) -> CTFont {
        var traits = CTFontSymbolicTraits()
        if isBold { traits.insert(.traitBold) }
        if isItalic { traits.insert(.traitItalic) }
        guard !traits.isEmpty else { return font }
        return CTFontCreateCopyWithSymbolicTraits(font, extractionSize, nil, traits, traits) ?? font
    }
}
