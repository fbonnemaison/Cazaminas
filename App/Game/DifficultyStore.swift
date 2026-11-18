// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation

/// Recuerda la última dificultad elegida (UserDefaults, disponible en macOS e iOS).
struct DifficultyStore {
    static let key = "lastDifficulty"

    let defaults: UserDefaults

    static var standard: DifficultyStore { DifficultyStore(defaults: .standard) }

    /// La dificultad guardada, o `nil` si no hay ninguna o los datos no son válidos.
    func load() -> Difficulty? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(Difficulty.self, from: data)
    }

    func save(_ difficulty: Difficulty) {
        guard let data = try? JSONEncoder().encode(difficulty) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
