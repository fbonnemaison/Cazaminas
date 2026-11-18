// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation
import Testing
@testable import Cazaminas

@MainActor
@Suite("Modo sin adivinar y pistas")
struct NoGuessModeTests {
    private func P(_ row: Int, _ column: Int) -> Position { Position(row: row, column: column) }

    private func makeModel(noGuess: Bool = true) -> GameViewModel {
        let settings = AppSettings()
        settings.noGuessMode = noGuess
        return GameViewModel(settings: settings, store: nil, statisticsStore: nil)
    }

    @Test("El primer clic genera un tablero resoluble y lo destapa")
    func firstClickGeneratesSolvableBoard() async {
        let model = makeModel()
        model.select(.expert)
        let click = P(8, 15)
        model.primaryAction(at: click)
        #expect(model.isGenerating)
        await model.generationTask?.value

        #expect(!model.isGenerating)
        #expect(model.status == .playing || model.status == .won)
        #expect(model.mode == .noGuess)
        #expect(!model.noGuessFallback)
        #expect(model.isTimerRunning)
        #expect(Solver.isSolvableWithoutGuessing(board: model.game.board, firstClick: click))
    }

    @Test("Mientras se genera, los clics se ignoran")
    func inputIgnoredWhileGenerating() async {
        let model = makeModel()
        model.primaryAction(at: P(4, 4))
        model.toggleMark(at: P(0, 0))
        model.primaryAction(at: P(0, 8))
        await model.generationTask?.value
        #expect(model.game[P(0, 0)].state != .flagged)
    }

    @Test("Las banderas puestas antes del primer clic se conservan")
    func marksSurviveGeneration() async {
        let model = makeModel()
        model.toggleMark(at: P(0, 0))
        model.primaryAction(at: P(4, 4))
        await model.generationTask?.value
        // Puede que la cascada no llegue a la esquina: si sigue tapada, conserva la bandera.
        if model.game[P(0, 0)].state != .revealed {
            #expect(model.game[P(0, 0)].state == .flagged)
        }
    }

    @Test("Nueva partida durante la generación la cancela")
    func newGameCancelsGeneration() async {
        let model = makeModel()
        model.select(.expert)
        model.primaryAction(at: P(8, 15))
        let task = model.generationTask
        model.newGame()
        await task?.value
        #expect(model.status == .ready)
        #expect(!model.isGenerating)
        #expect(model.statistics.isEmpty)
    }

    @Test("El modo se fija en el primer clic aunque luego cambie el ajuste")
    func modeLockedAtFirstClick() async {
        let model = makeModel()
        model.primaryAction(at: P(4, 4))
        await model.generationTask?.value
        model.settings.noGuessMode = false
        #expect(model.mode == .noGuess)
        model.newGame()
        #expect(model.mode == .classic)
    }

    @Test("Las partidas sin adivinar se registran en su propio modo")
    func statisticsByMode() async {
        let model = makeModel()
        model.primaryAction(at: P(4, 4))
        await model.generationTask?.value
        model.newGame() // abandonada
        #expect(model.statistics[.beginner, .noGuess].played == 1)
        #expect(model.statistics[.beginner].played == 0)
    }

    @Test("Un tablero imposible de garantizar cae al modo clásico y avisa")
    func fallbackForDenseBoards() async throws {
        let model = makeModel()
        model.select(.custom(try BoardConfiguration(width: 5, height: 5, mines: 16)))
        model.primaryAction(at: P(2, 2))
        await model.generationTask?.value
        #expect(!model.isGenerating)
        if model.noGuessFallback {
            #expect(model.mode == .classic)
        }
        #expect(model.status != .ready)
    }

    // MARK: - Pistas

    @Test("Pedir una pista la muestra y la marca como ayuda")
    func hint() throws {
        let configuration = try BoardConfiguration(width: 5, height: 3, mines: 2)
        let model = GameViewModel(game: Game(configuration: configuration, minePositions: [P(0, 2), P(1, 2)]))
        model.primaryAction(at: P(2, 0))
        model.showHint()
        #expect(model.hint == Hint(position: P(0, 2), kind: .mine))
        #expect(model.hintKind(at: P(0, 2)) == .mine)
        #expect(model.hintKind(at: P(1, 2)) == nil)
        #expect(model.usedHint)
        model.toggleMark(at: P(0, 2))
        #expect(model.hint == nil)
    }

    @Test("Ganar con pistas no entra en la tabla de récords")
    func assistedWinNotRanked() throws {
        let configuration = try BoardConfiguration(width: 5, height: 3, mines: 2)
        let model = GameViewModel(game: Game(configuration: configuration, minePositions: [P(0, 2), P(1, 2)]))
        model.primaryAction(at: P(2, 0))
        model.showHint()
        for row in 0..<3 {
            for column in 0..<5 where !model.game[P(row, column)].isMine {
                model.primaryAction(at: P(row, column))
            }
        }
        #expect(model.status == .won)
        #expect(model.lastWin?.rank == nil)
        #expect(model.statistics[.custom].won == 1)
    }

    @Test("Sin jugada segura, la pista avisa en lugar de inventar")
    func hintUnavailable() throws {
        // 50/50: dos casillas indistinguibles con una mina.
        let configuration = try BoardConfiguration(width: 4, height: 2, mines: 1)
        let model = GameViewModel(game: Game(configuration: configuration, minePositions: [P(0, 0)]))
        model.primaryAction(at: P(1, 3))
        model.showHint()
        #expect(model.hint == nil)
        #expect(model.hintUnavailable)
        #expect(!model.usedHint)
    }
}
