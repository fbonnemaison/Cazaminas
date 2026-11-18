// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore

extension Difficulty {
    /// Nombre del nivel para menús y títulos.
    var title: String {
        switch self {
        case .beginner: String(localized: "Principiante")
        case .intermediate: String(localized: "Intermedio")
        case .expert: String(localized: "Experto")
        case .custom: String(localized: "Personalizado")
        }
    }

    /// Medidas del tablero, p. ej. «9 × 9 · 10 minas».
    var summary: String {
        let configuration = configuration
        return String(localized: "\(configuration.width) × \(configuration.height) · \(configuration.mines) minas")
    }
}
