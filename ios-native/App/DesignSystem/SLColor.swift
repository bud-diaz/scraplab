import SwiftUI

/// Literal brand ramps plus semantic aliases. Feature views should prefer aliases.
enum SLColor {
    static let orange50 = Color(hex: 0xFEF4EC)
    static let orange100 = Color(hex: 0xFDE3CE)
    static let orange200 = Color(hex: 0xFBCBA3)
    static let orange300 = Color(hex: 0xF8AD73)
    static let orange400 = Color(hex: 0xF5A052)
    static let orange500 = Color(hex: 0xF4934B)
    static let orange600 = Color(hex: 0xDD7A32)
    static let orange700 = Color(hex: 0xB85F22)
    static let orange800 = Color(hex: 0x94491A)
    static let orange900 = Color(hex: 0x783A16)
    static let orange950 = Color(hex: 0x431F0B)

    static let builder400 = orange400
    static let builder500 = orange500
    static let builder600 = orange600
    static let builder700 = orange700

    static let scraplabBlue = Color(hex: 0x2D3FE0)
    static let scraplabBlueDark = Color(hex: 0x1F2CB0)
    static let scraplabBlueLight = Color(hex: 0x5A68E8)

    static let kraft300 = Color(hex: 0xE6E6EF)
    static let kraft400 = Color(hex: 0xD6D6E4)
    static let kraft500 = Color(hex: 0x9B9BAE)
    static let kraft600 = Color(hex: 0x6B6B7B)
    static let kraft700 = Color(hex: 0x52525F)

    static let walnut500 = Color(hex: 0x8A8A9C)
    static let walnut600 = Color(hex: 0x6B6B7B)
    static let walnut700 = Color(hex: 0x52525F)
    static let walnut800 = Color(hex: 0x3A3A47)
    static let walnut900 = Color(hex: 0x2E2E3A)

    static let cream50 = Color(hex: 0xEDEBFB)
    static let cream100 = Color(hex: 0xE4E1F9)
    static let cream200 = Color(hex: 0xD9D6F0)
    static let charcoal800 = Color(hex: 0x34344A)
    static let charcoal900 = Color(hex: 0x1C1C28)

    static let mist = Color(hex: 0xF4F4F8)

    static let leaf = Color(hex: 0x5FBF7A)
    static let leafText = Color(hex: 0x2E7D46)
    static let caution = Color(hex: 0xF2A93B)
    static let cautionText = Color(hex: 0x8A5A0A)
    static let coral = Color(hex: 0xE8604C)
    static let coralText = Color(hex: 0xB23A2A)
    static let sunshine = Color(hex: 0xFFC93C)

    /// Vibrant accents for the whole-app "kiddie" pass — playful pink, bright teal, purple.
    static let bubblegum = Color(hex: 0xFF5FA2)
    static let bubblegumText = Color(hex: 0xC22A6E)
    static let turquoise = Color(hex: 0x2FD1C5)
    static let turquoiseText = Color(hex: 0x0E8A7F)
    static let grape = Color(hex: 0x9B5DE5)
    static let grapeText = Color(hex: 0x6A2FB0)

    static let primary = builder500
    static let primaryPressed = builder600
    static let hero = scraplabBlue
    static let pageBackground = cream50
    static let surface = Color.white
    static let ink = charcoal900
    static let bodyText = walnut600
    static let mutedText = kraft600
    static let line = kraft300
    static let fieldFill = mist

    /// Shared low-opacity tint used by soft-filled chips/badges (Reality Indicators,
    /// SupervisionBadge) so every "traffic light" surface uses identical tint math.
    static func softFill(_ color: Color) -> Color {
        color.opacity(0.15)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
