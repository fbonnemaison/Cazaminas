// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation
import Testing
@testable import Cazaminas

@MainActor
@Suite("Registro de estadísticas")
struct StatisticsRecordingTests {
    let clock = TestClock()
    let directory = FileManager.default.temporaryDirectory.appending(path: "CazaminasTests-\(UUID().uuidString)")

    private var store: StatisticsStore {
        StatisticsStore(fileURL: directory.appending(path: "statistics.json"))
    }

    private func P(_ row: Int, _ column: Int) -> Position { Position(row: row, column: column) }

    /// Principiante con un muro de minas en la columna 4 (y otra en la esquina):
    /// el primer clic a la derecha no gana, y luego se puede ganar o perder a voluntad.
    private func makeModel(store: StatisticsStore? = nil) -> GameViewModel {
        let mines = Set((0..<9).map { Position(row: $0, column: 4) } + [Position(row: 0, column: 0)])
        let game = Game(configuration: .beginner, minePositions: mines)
        return GameViewModel(game: game, statisticsStore: store, now: { [clock] in clock.date })
    }

    /// Destapa todas las casillas seguras (un clic abajo abre en cascada casi todo el tablero).
    private func win(_ model: GameViewModel) {
        for row in 1..<9 {
            for column in 0..<9 where model.status == .playing || model.status == .ready {
                let position = P(row, column)
                if !model.game[position].isMine, model.game[position].state != .revealed {
                    model.primaryAction(at: position)
                }
            }
        }
    }

    @Test("Ganar registra la victoria con el tiempo exacto")
    func recordsWin() {
        let model = makeModel()
        model.primaryAction(at: P(8, 8))
        clock.advance(12.34)
        win(model)
        #expect(model.status == .won)
        #expect(model.lastWin?.seconds == 12.34)
        #expect(model.lastWin?.isNewBest == true)
        #expect(model.statistics[.beginner].won == 1)
        #expect(model.statistics[.beginner].bestTimes.first?.seconds == 12.34)
    }

    @Test("Perder registra una derrota y corta la racha")
    func recordsLoss() {
        let model = makeModel()
        model.primaryAction(at: P(8, 8))
        model.primaryAction(at: P(0, 0))
        #expect(model.statistics[.beginner].played == 1)
        #expect(model.statistics[.beginner].won == 0)
        #expect(model.lastWin == nil)
    }

    @Test("Abandonar una partida empezada cuenta como derrota")
    func abandonCountsAsLoss() {
        let model = makeModel()
        model.primaryAction(at: P(8, 8))
        model.newGame()
        #expect(model.statistics[.beginner].played == 1)
        #expect(model.statistics[.beginner].won == 0)
    }

    @Test("Una partida sin empezar no cuenta")
    func untouchedGameDoesNotCount() {
        let model = makeModel()
        model.toggleMark(at: P(0, 0))
        model.newGame()
        #expect(model.statistics.isEmpty)
    }

    @Test("La partida abandonada cuenta en su nivel, no en el nuevo")
    func abandonCountsInPreviousDifficulty() {
        let model = makeModel()
        model.primaryAction(at: P(8, 8))
        model.select(.expert)
        #expect(model.statistics[.beginner].played == 1)
        #expect(model.statistics[.expert].played == 0)
    }

    @Test("Terminar y luego empezar otra no cuenta dos veces")
    func finishedGameNotCountedTwice() {
        let model = makeModel()
        model.primaryAction(at: P(8, 8))
        model.primaryAction(at: P(0, 0))
        model.newGame()
        #expect(model.statistics[.beginner].played == 1)
    }

    @Test("Las estadísticas se guardan y se recuperan al abrir la app")
    func persistence() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        model.primaryAction(at: P(8, 8))
        clock.advance(20)
        win(model)

        let reopened = GameViewModel(store: nil, statisticsStore: store)
        #expect(reopened.statistics[.beginner].won == 1)
        #expect(reopened.statistics[.beginner].bestTimes.first?.seconds == 20)
        #expect(reopened.statistics == model.statistics)
    }

    @Test("Un archivo dañado no impide arrancar")
    func corruptFile() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("{ no es json".utf8).write(to: store.fileURL)
        #expect(store.load().isEmpty)
    }

    @Test("Restablecer borra y guarda")
    func reset() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = makeModel(store: store)
        model.primaryAction(at: P(8, 8))
        model.primaryAction(at: P(0, 0))
        model.resetStatistics()
        #expect(model.statistics.isEmpty)
        #expect(store.load().isEmpty)
    }
}
