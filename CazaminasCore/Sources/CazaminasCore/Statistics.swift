// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Foundation

/// Grupo de partidas que comparten estadísticas.
///
/// Los tableros personalizados se agrupan juntos: no tienen mejores tiempos
/// porque cada uno puede tener medidas distintas.
public enum StatsCategory: String, CaseIterable, Identifiable, Hashable, Sendable, Codable, CodingKeyRepresentable {
    case beginner
    case intermediate
    case expert
    case custom

    public var id: Self { self }

    public init(_ difficulty: Difficulty) {
        switch difficulty {
        case .beginner: self = .beginner
        case .intermediate: self = .intermediate
        case .expert: self = .expert
        case .custom: self = .custom
        }
    }

    /// Si esta categoría guarda una tabla de mejores tiempos.
    public var tracksBestTimes: Bool { self != .custom }
}

/// Un tiempo de victoria.
public struct TimeRecord: Hashable, Sendable, Codable {
    /// Segundos desde el primer clic hasta la victoria.
    public var seconds: Double
    public var date: Date

    public init(seconds: Double, date: Date) {
        self.seconds = seconds
        self.date = date
    }
}

/// Estadísticas de una categoría.
public struct CategoryStats: Hashable, Sendable, Codable {
    public internal(set) var played = 0
    public internal(set) var won = 0
    public internal(set) var currentStreak = 0
    public internal(set) var bestStreak = 0
    /// Mejores tiempos, del más rápido al más lento.
    public internal(set) var bestTimes: [TimeRecord] = []

    public init() {}

    /// Porcentaje de victorias entre 0 y 1 (0 si no se ha jugado).
    public var winRate: Double {
        played == 0 ? 0 : Double(won) / Double(played)
    }
}

/// Resultado de registrar una victoria.
public struct WinOutcome: Hashable, Sendable {
    public var seconds: Double
    /// Posición en la tabla de mejores tiempos (1 = récord), o `nil` si no entra.
    public var rank: Int?

    public var isNewBest: Bool { rank == 1 }
}

/// Estadísticas de todas las partidas, separadas por modo de juego.
public struct Statistics: Hashable, Sendable, Codable {
    /// Cuántos tiempos guarda cada tabla.
    public static let maxBestTimes = 10

    /// Modo clásico. Conserva el nombre original para leer archivos antiguos.
    private var categories: [StatsCategory: CategoryStats] = [:]
    /// Modo sin adivinar.
    private var noGuessCategories: [StatsCategory: CategoryStats] = [:]

    public init() {}

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        categories = try container.decodeIfPresent([StatsCategory: CategoryStats].self, forKey: .categories) ?? [:]
        noGuessCategories = try container.decodeIfPresent(
            [StatsCategory: CategoryStats].self, forKey: .noGuessCategories
        ) ?? [:]
    }

    public subscript(category: StatsCategory, mode: GameMode = .classic) -> CategoryStats {
        get { storage(mode)[category] ?? CategoryStats() }
        set {
            switch mode {
            case .classic: categories[category] = newValue
            case .noGuess: noGuessCategories[category] = newValue
            }
        }
    }

    private func storage(_ mode: GameMode) -> [StatsCategory: CategoryStats] {
        switch mode {
        case .classic: categories
        case .noGuess: noGuessCategories
        }
    }

    /// `true` si nunca se ha registrado ninguna partida.
    public var isEmpty: Bool {
        categories.values.allSatisfy { $0.played == 0 } && noGuessCategories.values.allSatisfy { $0.played == 0 }
    }

    /// Registra una victoria y devuelve su posición en la tabla de tiempos.
    /// - Parameter countsForBestTimes: `false` si la partida se ganó con ayuda (pistas).
    @discardableResult
    public mutating func recordWin(
        in category: StatsCategory,
        mode: GameMode = .classic,
        seconds: Double,
        date: Date,
        countsForBestTimes: Bool = true
    ) -> WinOutcome {
        var stats = self[category, mode]
        stats.played += 1
        stats.won += 1
        stats.currentStreak += 1
        stats.bestStreak = max(stats.bestStreak, stats.currentStreak)

        var rank: Int?
        if category.tracksBestTimes, countsForBestTimes {
            // Empates: el tiempo más antiguo va primero.
            let index = stats.bestTimes.firstIndex { seconds < $0.seconds } ?? stats.bestTimes.endIndex
            if index < Self.maxBestTimes {
                stats.bestTimes.insert(TimeRecord(seconds: seconds, date: date), at: index)
                stats.bestTimes = Array(stats.bestTimes.prefix(Self.maxBestTimes))
                rank = index + 1
            }
        }

        self[category, mode] = stats
        return WinOutcome(seconds: seconds, rank: rank)
    }

    /// Registra una derrota (o una partida abandonada a medias).
    public mutating func recordLoss(in category: StatsCategory, mode: GameMode = .classic) {
        var stats = self[category, mode]
        stats.played += 1
        stats.currentStreak = 0
        self[category, mode] = stats
    }

    /// Borra las estadísticas de una categoría (o de todas) en un modo (o en los dos).
    public mutating func reset(_ category: StatsCategory? = nil, mode: GameMode? = nil) {
        for current in GameMode.allCases where mode == nil || mode == current {
            if let category {
                self[category, current] = CategoryStats()
            } else {
                switch current {
                case .classic: categories.removeAll()
                case .noGuess: noGuessCategories.removeAll()
                }
            }
        }
        categories = categories.filter { $0.value.played > 0 }
        noGuessCategories = noGuessCategories.filter { $0.value.played > 0 }
    }
}
