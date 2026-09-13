import CoreText
import SwiftUI
import UIKit

enum SLFont {
    private static let headingFamily = "Baloo2-Regular"
    private static let bodyFamily = "Inter-Regular"

    static func heading(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        guard UIFont(name: headingFamily, size: size) != nil else {
            return .system(style, design: .rounded)
        }
        return .custom(headingFamily, size: size, relativeTo: style)
    }

    static func body(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        guard UIFont(name: bodyFamily, size: size) != nil else {
            return .system(style, design: .default)
        }
        return .custom(bodyFamily, size: size, relativeTo: style)
    }

    static let largeTitle = heading(36, relativeTo: .largeTitle).weight(.bold)
    static let title = heading(28, relativeTo: .title).weight(.bold)
    static let title2 = heading(22, relativeTo: .title2).weight(.semibold)
    static let headline = heading(17, relativeTo: .headline).weight(.semibold)
    static let body = body(16)
    static let callout = body(15, relativeTo: .callout)
    static let caption = body(12, relativeTo: .caption)

    /// Uses Inter's OpenType tabular-number feature when available and falls back safely.
    static func tabular(_ size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        let base = UIFont(name: "Inter-Regular", size: size) ?? .systemFont(ofSize: size, weight: weight)
        let settings: [[UIFontDescriptor.FeatureKey: Int]] = [[
            .type: Int(kNumberSpacingType),
            .selector: Int(kMonospacedNumbersSelector)
        ]]
        let descriptor = base.fontDescriptor.addingAttributes([.featureSettings: settings])
        return Font(UIFont(descriptor: descriptor, size: size))
    }
}

/// Registers bundled font files for app launch and previews. Missing files intentionally use system fallbacks.
enum SLFontRegistrar {
    static func registerBundledFonts(in bundle: Bundle = .main) {
        for fileExtension in ["ttf", "otf"] {
            for subdirectory in [nil, "Fonts"] as [String?] {
                for url in bundle.urls(forResourcesWithExtension: fileExtension, subdirectory: subdirectory) ?? [] {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
        }
    }
}
