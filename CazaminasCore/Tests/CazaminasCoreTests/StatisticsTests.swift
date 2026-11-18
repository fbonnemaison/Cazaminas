// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Foundation
import Testing
@testable import CazaminasCore

@Suite("Estadísticas y récords")
struct StatisticsTests {
    let date = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test("Las estadísticas empiezan vacías")
    func empty() {
        let statistics = Statistics()
        #expect(statistics.isEmpty)
        #expect(statistics[.beginner].played == 0)
        #expect(statistics[.beginner].winRate == 0)
    }

    @Test("Victorias y derrotas actualizan partidas, % y rachas")
    func streaks() {
        var statistics = Statistics()
        statistics.recordWin(in: .beginner, seconds: 30, date: date)
        statistics.recordWin(in: .beginner, seconds: 40, date: date)
        statistics.recordWin(in: .beginner, seconds: 50, date: date)
        statistics.recordLoss(in: .beginner)
        statistics.recordWin(in: .beginner, seconds: 60, date: date)

        let stats = statistics[.beginner]
        #expect(stats.played == 5)
        #expect(stats.won == 4)
        #expect(stats.winRate == 0.8)
        #expect(stats.currentStreak == 1)
        #expect(stats.bestStreak == 3)
        #expect(!statistics.isEmpty)
    }

    @Test("Cada categoría lleva sus propias estadísticas")
    func categoriesAreSeparate() {
        var statistics = Statistics()
        statistics.recordWin(in: .expert, seconds: 200, date: date)
        statistics.recordLoss(in: .beginner)
        #expect(statistics[.expert].won == 1)
        #expect(statistics[.beginner].won == 0)
        #expect(statistics[.intermediate].played == 0)
    }

    @Test("Los mejores tiempos se ordenan y devuelven su posición")
    func bestTimesRanking() {
        var statistics = Statistics()
        #expect(statistics.recordWin(in: .beginner, seconds: 50, date: date).rank == 1)
        #expect(statistics.recordWin(in: .beginner, seconds: 30, date: date).isNewBest)
        #expect(statistics.recordWin(in: .beginner, seconds: 40, date: date).rank == 2)
        #expect(statistics[.beginner].bestTimes.map(\.seconds) == [30, 40, 50])
    }

    @Test("En un empate, el tiempo anterior conserva el puesto")
    func ties() {
        var statistics = Statistics()
        statistics.recordWin(in: .beginner, seconds: 30, date: date)
        let outcome = statistics.recordWin(in: .beginner, seconds: 30, date: date.addingTimeInterval(60))
        #expect(outcome.rank == 2)
        #expect(!outcome.isNewBest)
        #expect(statistics[.beginner].bestTimes.first?.date == date)
    }

    @Test("Solo se guardan los 10 mejores tiempos")
    func topTen() {
        var statistics = Statistics()
        for seconds in 1...10 {
            statistics.recordWin(in: .intermediate, seconds: Double(seconds * 10), date: date)
        }
        #expect(statistics.recordWin(in: .intermediate, seconds: 500, date: date).rank == nil)
        #expect(statistics.recordWin(in: .intermediate, seconds: 5, date: date).rank == 1)
        let times = statistics[.intermediate].bestTimes.map(\.seconds)
        #expect(times.count == Statistics.maxBestTimes)
        #expect(times.first == 5)
        #expect(times.last == 90)
        #expect(statistics[.intermediate].played == 12)
    }

    @Test("Los tableros personalizados no tienen tabla de tiempos")
    func customHasNoBestTimes() {
        var statistics = Statistics()
        let outcome = statistics.recordWin(in: .custom, seconds: 10, date: date)
        #expect(outcome.rank == nil)
        #expect(statistics[.custom].bestTimes.isEmpty)
        #expect(statistics[.custom].won == 1)
    }

    @Test("Se puede restablecer una categoría o todas")
    func reset() {
        var statistics = Statistics()
        statistics.recordWin(in: .beginner, seconds: 10, date: date)
        statistics.recordWin(in: .expert, seconds: 100, date: date)
        statistics.reset(.beginner)
        #expect(statistics[.beginner].played == 0)
        #expect(statistics[.expert].played == 1)
        statistics.reset()
        #expect(statistics.isEmpty)
    }

    @Test("La categoría corresponde a la dificultad")
    func categoryFromDifficulty() throws {
        #expect(StatsCategory(.beginner) == .beginner)
        #expect(StatsCategory(.expert) == .expert)
        #expect(StatsCategory(.custom(try BoardConfiguration(width: 10, height: 10, mines: 5))) == .custom)
    }

    @Test("Se codifica como un objeto JSON legible y se recupera igual")
    func codable() throws {
        var statistics = Statistics()
        statistics.recordWin(in: .beginner, seconds: 12.5, date: date)
        statistics.recordLoss(in: .expert)
        let data = try JSONEncoder().encode(statistics)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"beginner\""))
        #expect(try JSONDecoder().decode(Statistics.self, from: data) == statistics)
    }
}
