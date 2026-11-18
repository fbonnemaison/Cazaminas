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

/// Estadísticas de todas las partidas.
public struct Statistics: Hashable, Sendable, Codable {
    /// Cuántos tiempos guarda cada tabla.
    public static let maxBestTimes = 10

    private var categories: [StatsCategory: CategoryStats] = [:]

    public init() {}

    public subscript(category: StatsCategory) -> CategoryStats {
        categories[category] ?? CategoryStats()
    }

    /// `true` si nunca se ha registrado ninguna partida.
    public var isEmpty: Bool {
        StatsCategory.allCases.allSatisfy { self[$0].played == 0 }
    }

    /// Registra una victoria y devuelve su posición en la tabla de tiempos.
    @discardableResult
    public mutating func recordWin(in category: StatsCategory, seconds: Double, date: Date) -> WinOutcome {
        var stats = self[category]
        stats.played += 1
        stats.won += 1
        stats.currentStreak += 1
        stats.bestStreak = max(stats.bestStreak, stats.currentStreak)

        var rank: Int?
        if category.tracksBestTimes {
            // Empates: el tiempo más antiguo va primero.
            let index = stats.bestTimes.firstIndex { seconds < $0.seconds } ?? stats.bestTimes.endIndex
            if index < Self.maxBestTimes {
                stats.bestTimes.insert(TimeRecord(seconds: seconds, date: date), at: index)
                stats.bestTimes = Array(stats.bestTimes.prefix(Self.maxBestTimes))
                rank = index + 1
            }
        }

        categories[category] = stats
        return WinOutcome(seconds: seconds, rank: rank)
    }

    /// Registra una derrota (o una partida abandonada a medias).
    public mutating func recordLoss(in category: StatsCategory) {
        var stats = self[category]
        stats.played += 1
        stats.currentStreak = 0
        categories[category] = stats
    }

    /// Borra las estadísticas de una categoría, o de todas.
    public mutating func reset(_ category: StatsCategory? = nil) {
        if let category {
            categories[category] = nil
        } else {
            categories.removeAll()
        }
    }
}
