// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Temas visuales del tablero.
enum ThemeID: String, CaseIterable, Identifiable, Sendable {
    case relief
    case flat
    case highContrast

    var id: Self { self }

    var title: String {
        switch self {
        case .relief: String(localized: "Relieve")
        case .flat: String(localized: "Plano")
        case .highContrast: String(localized: "Alto contraste")
        }
    }

    var theme: BoardTheme {
        switch self {
        case .relief: .relief
        case .flat: .flat
        case .highContrast: .highContrast
        }
    }
}

/// Colores y forma de las casillas. Cada color tiene variante clara y oscura.
struct BoardTheme: Equatable {
    enum CellStyle: Equatable {
        /// Casillas tapadas con volumen (degradado y sombra).
        case raised
        /// Casillas planas separadas por un hueco.
        case flat
        /// Casillas con borde grueso, para máxima legibilidad.
        case outlined
    }

    let id: ThemeID
    let style: CellStyle
    let boardBackground: Color
    let cellCovered: Color
    let cellCoveredShade: Color
    let cellRevealed: Color
    let cellGrid: Color
    let detonated: Color
    let mine: Color
    let flag: Color
    let numberWeight: Font.Weight
    /// Colores de los números 1–8.
    let numbers: [Color]

    static func == (lhs: BoardTheme, rhs: BoardTheme) -> Bool { lhs.id == rhs.id }

    func numberColor(_ number: Int) -> Color {
        numbers[(number - 1).clamped(to: 0...7)]
    }

    // MARK: - Temas

    static let relief = BoardTheme(
        id: .relief,
        style: .raised,
        boardBackground: .dynamic(light: 0xC3C9D3, dark: 0x1A1D23),
        cellCovered: .dynamic(light: 0xDCE1E8, dark: 0x535B6B),
        cellCoveredShade: .dynamic(light: 0xB4BCC9, dark: 0x3D4350),
        cellRevealed: .dynamic(light: 0xF6F7F9, dark: 0x262A31),
        cellGrid: .dynamic(light: 0xD5D9E0, dark: 0x33373F),
        detonated: .dynamic(light: 0xF06A6A, dark: 0xC9373C),
        mine: .dynamic(light: 0x1E2127, dark: 0xE3E6EB),
        flag: .red,
        numberWeight: .heavy,
        numbers: [
            .dynamic(light: 0x1F5FD6, dark: 0x6EA8FF),
            .dynamic(light: 0x1E7F3A, dark: 0x5AD47E),
            .dynamic(light: 0xC62828, dark: 0xFF6B6B),
            .dynamic(light: 0x4B3BC4, dark: 0xA99BFF),
            .dynamic(light: 0x8F4510, dark: 0xE6A15C),
            .dynamic(light: 0x0B727A, dark: 0x45D0D8),
            .dynamic(light: 0x1E2127, dark: 0xE8EAED),
            .dynamic(light: 0x5F6670, dark: 0xA0A6AF),
        ]
    )

    static let flat = BoardTheme(
        id: .flat,
        style: .flat,
        boardBackground: .dynamic(light: 0xE4E8EE, dark: 0x16191E),
        cellCovered: .dynamic(light: 0xA9B6C9, dark: 0x4A5368),
        cellCoveredShade: .dynamic(light: 0xA9B6C9, dark: 0x4A5368),
        cellRevealed: .dynamic(light: 0xF7F8FA, dark: 0x22262D),
        cellGrid: .clear,
        detonated: .dynamic(light: 0xF27474, dark: 0xB83A3F),
        mine: .dynamic(light: 0x2B303A, dark: 0xDDE1E8),
        flag: .dynamic(light: 0xE5484D, dark: 0xFF6B6F),
        numberWeight: .bold,
        numbers: [
            .dynamic(light: 0x2557CC, dark: 0x6EA0FF),
            .dynamic(light: 0x1D7343, dark: 0x5CD18A),
            .dynamic(light: 0xC2303A, dark: 0xFF7A7E),
            .dynamic(light: 0x5B30D6, dark: 0xA98BFF),
            .dynamic(light: 0x9A4708, dark: 0xF09A55),
            .dynamic(light: 0x08707A, dark: 0x4FD1DC),
            .dynamic(light: 0x30343B, dark: 0xE8EAED),
            .dynamic(light: 0x5D636B, dark: 0xA0A6AF),
        ]
    )

    static let highContrast = BoardTheme(
        id: .highContrast,
        style: .outlined,
        boardBackground: .dynamic(light: 0x000000, dark: 0xFFFFFF),
        cellCovered: .dynamic(light: 0x9A9A9A, dark: 0x6B6B6B),
        cellCoveredShade: .dynamic(light: 0x9A9A9A, dark: 0x6B6B6B),
        cellRevealed: .dynamic(light: 0xFFFFFF, dark: 0x000000),
        cellGrid: .dynamic(light: 0x000000, dark: 0xFFFFFF),
        detonated: .dynamic(light: 0xFF0000, dark: 0xFF3B30),
        mine: .dynamic(light: 0x000000, dark: 0xFFFFFF),
        flag: .dynamic(light: 0xD00000, dark: 0xFF453A),
        numberWeight: .black,
        numbers: [
            .dynamic(light: 0x0033CC, dark: 0x66A3FF),
            .dynamic(light: 0x006600, dark: 0x4CD964),
            .dynamic(light: 0xCC0000, dark: 0xFF5C5C),
            .dynamic(light: 0x330099, dark: 0xB38CFF),
            .dynamic(light: 0x800000, dark: 0xFF9F43),
            .dynamic(light: 0x006666, dark: 0x40E0D0),
            .dynamic(light: 0x000000, dark: 0xFFFFFF),
            .dynamic(light: 0x444444, dark: 0xBBBBBB),
        ]
    )
}

extension Color {
    /// Color con una variante para modo claro y otra para modo oscuro.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if os(macOS)
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? NSColor(hex: dark) : NSColor(hex: light)
        })
        #else
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
        #endif
    }
}

#if os(macOS)
private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#else
private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
