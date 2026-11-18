// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation
import Testing
@testable import Cazaminas

@MainActor
@Suite("Pausa, teclado y accesibilidad")
struct PauseKeyboardAccessibilityTests {
    let clock = TestClock()

    private func P(_ row: Int, _ column: Int) -> Position { Position(row: row, column: column) }

    /// 5×3 con minas en (0,2) y (1,2): el clic en (2,0) deja la partida a medias.
    private func makeModel() throws -> GameViewModel {
        let configuration = try BoardConfiguration(width: 5, height: 3, mines: 2)
        let game = Game(configuration: configuration, minePositions: [P(0, 2), P(1, 2)])
        return GameViewModel(game: game, now: { [clock] in clock.date })
    }

    // MARK: - Pausa

    @Test("La pausa detiene el cronómetro y no cuenta en el tiempo")
    func pauseStopsTimer() throws {
        let model = try makeModel()
        model.primaryAction(at: P(2, 0))
        clock.advance(10)
        model.pause()
        #expect(model.isPaused)
        #expect(!model.isTimerRunning)
        clock.advance(100)
        #expect(model.elapsedSeconds(at: clock.date) == 10)
        model.resume()
        clock.advance(5)
        #expect(model.elapsedSeconds(at: clock.date) == 15)
    }

    @Test("En pausa no se puede jugar")
    func pauseBlocksInput() throws {
        let model = try makeModel()
        model.primaryAction(at: P(2, 0))
        model.pause()
        model.primaryAction(at: P(2, 2))
        model.toggleMark(at: P(0, 2))
        #expect(model.appearance(at: P(2, 2)) == .covered)
        #expect(model.appearance(at: P(0, 2)) == .covered)
    }

    @Test("Solo se pausa una partida en curso")
    func pauseOnlyWhilePlaying() throws {
        let model = try makeModel()
        model.pause()
        #expect(!model.isPaused) // sin empezar
        model.primaryAction(at: P(2, 0))
        model.primaryAction(at: P(0, 2)) // pierde
        model.pause()
        #expect(!model.isPaused)
    }

    @Test("El tiempo de la victoria descuenta las pausas")
    func winTimeExcludesPauses() throws {
        let model = try makeModel()
        model.primaryAction(at: P(2, 0))
        clock.advance(4)
        model.togglePause()
        clock.advance(60)
        model.togglePause()
        clock.advance(2)
        for position in [P(2, 2), P(0, 3), P(1, 3), P(2, 3), P(0, 4), P(1, 4), P(2, 4)] {
            model.primaryAction(at: position)
        }
        #expect(model.status == .won)
        #expect(model.lastWin?.seconds == 6)
    }

    @Test("Nueva partida quita la pausa")
    func newGameClearsPause() throws {
        let model = try makeModel()
        model.primaryAction(at: P(2, 0))
        model.pause()
        model.newGame()
        #expect(!model.isPaused)
    }

    // MARK: - Teclado

    @Test("La primera tecla muestra el cursor en el centro sin jugar")
    func firstKeyShowsCursor() throws {
        let model = try makeModel()
        model.keyboardPrimary()
        #expect(model.showsCursor)
        #expect(model.cursor == P(1, 2))
        #expect(model.status == .ready)
    }

    @Test("Las flechas mueven el cursor sin salir del tablero")
    func arrowsMoveCursor() throws {
        let model = try makeModel()
        model.moveCursor(rows: 0, columns: 0)
        for _ in 0..<10 { model.moveCursor(rows: -1, columns: -1) }
        #expect(model.cursor == P(0, 0))
        for _ in 0..<10 { model.moveCursor(rows: 1, columns: 1) }
        #expect(model.cursor == P(2, 4))
    }

    @Test("Espacio destapa, F marca e Intro hace chording")
    func keyboardActions() throws {
        let model = try makeModel()
        model.moveCursor(rows: 0, columns: 0) // centro (1,2)
        model.moveCursor(rows: 1, columns: -2) // (2,0)
        model.keyboardPrimary()
        #expect(model.status == .playing)
        model.moveCursor(rows: -2, columns: 2) // (0,2)
        model.keyboardMark()
        #expect(model.appearance(at: P(0, 2)) == .flagged)
        model.moveCursor(rows: 1, columns: 0) // (1,2)
        model.keyboardMark()
        model.moveCursor(rows: 1, columns: -1) // (2,1): un «1»
        model.keyboardChord()
        #expect(model.appearance(at: P(2, 2)) != .covered)
    }

    @Test("El ratón mueve el cursor pero lo oculta")
    func mouseHidesCursor() throws {
        let model = try makeModel()
        model.moveCursor(rows: 0, columns: 0)
        model.primaryAction(at: P(2, 0))
        #expect(model.cursor == P(2, 0))
        #expect(!model.showsCursor)
    }

    // MARK: - Accesibilidad

    @Test("Cada casilla tiene una descripción para VoiceOver")
    func accessibilityLabels() throws {
        let model = try makeModel()
        #expect(model.accessibilityLabel(at: P(0, 0)) == "Fila 1, columna 1: tapada")
        model.primaryAction(at: P(2, 0))
        #expect(model.accessibilityLabel(at: P(0, 1)) == "Fila 1, columna 2: 2 minas cerca")
        #expect(model.accessibilityLabel(at: P(2, 1)) == "Fila 3, columna 2: 1 mina cerca")
        #expect(model.accessibilityLabel(at: P(2, 0)) == "Fila 3, columna 1: vacía")
        model.toggleMark(at: P(0, 2))
        #expect(model.accessibilityLabel(at: P(0, 2)) == "Fila 1, columna 3: bandera")
        model.showHint()
        let hint = try #require(model.hint)
        #expect(model.accessibilityLabel(at: hint.position).contains("pista"))
    }
}
