// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation

extension StatsCategory {
    var title: String {
        switch self {
        case .beginner: String(localized: "Principiante")
        case .intermediate: String(localized: "Intermedio")
        case .expert: String(localized: "Experto")
        case .custom: String(localized: "Personalizado")
        }
    }
}

/// Tiempo de partida con una décima, p. ej. «12,3 s».
func formattedSeconds(_ seconds: Double) -> String {
    let value = seconds.formatted(.number.precision(.fractionLength(1)))
    return String(localized: "\(value) s")
}

extension GameMode {
    var title: String {
        switch self {
        case .classic: String(localized: "Clásico")
        case .noGuess: String(localized: "Sin adivinar")
        }
    }
}
