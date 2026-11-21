// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CoreText
import SwiftUI

/// Estilo gráfico del juego. Se combina con cualquier tema (los colores salen del tema).
enum GraphicsStyle: String, CaseIterable, Identifiable, Sendable {
    /// Gráficos vectoriales suaves, nítidos a cualquier tamaño.
    case hd
    /// Casillas, números, banderas y minas en pixel art de 16 × 16, y contadores con fuente pixel.
    case pixel

    var id: Self { self }

    var title: String {
        switch self {
        case .hd: String(localized: "HD")
        case .pixel: String(localized: "Pixel art")
        }
    }

    var isPixel: Bool { self == .pixel }
}

/// Fuente pixel incluida en la app (Public Pixel, de GGBotNet, CC0).
enum PixelFont {
    /// Nombre PostScript de la fuente.
    static let name = "PublicPixel"

    /// Registra las fuentes `.ttf` del bundle para este proceso.
    @MainActor
    static func register() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(size: CGFloat) -> Font {
        .custom(name, fixedSize: size)
    }
}
