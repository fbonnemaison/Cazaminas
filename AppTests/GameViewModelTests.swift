// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation
import Testing
@testable import Cazaminas

/// Reloj manual para controlar el cronómetro en los tests.
@MainActor
final class TestClock {
    var date = Date(timeIntervalSinceReferenceDate: 0)
    func advance(_ seconds: TimeInterval) { date += seconds }
}

@MainActor
@Suite("GameViewModel")
struct GameViewModelTests {
    let clock = TestClock()

    private func P(_ row: Int, _ column: Int) -> Position { Position(row: row, column: column) }

    /// 3×3 con una mina en la esquina superior izquierda.
    private func makeModel(mines: [Position] = [Position(row: 0, column: 0)]) throws -> GameViewModel {
        let configuration = try BoardConfiguration(width: 3, height: 3, mines: mines.count)
        let game = Game(configuration: configuration, minePositions: Set(mines))
        return GameViewModel(game: game, now: { [clock] in clock.date })
    }

    // MARK: - Cronómetro

    @Test("El cronómetro arranca con el primer clic y no antes")
    func timerStartsOnFirstReveal() throws {
        let model = try makeModel()
        model.toggleMark(at: P(0, 0))
        #expect(!model.isTimerRunning)
        #expect(model.elapsedSeconds(at: clock.date) == 0)

        model.primaryAction(at: P(1, 1))
        #expect(model.isTimerRunning)
        clock.advance(5.7)
        #expect(model.elapsedSeconds(at: clock.date) == 5)
    }

    @Test("El cronómetro se detiene al terminar la partida")
    func timerStopsWhenOver() throws {
        let model = try makeModel()
        model.primaryAction(at: P(1, 1))
        clock.advance(12)
        model.primaryAction(at: P(0, 0))
        #expect(model.status == .lost(detonated: P(0, 0)))
        #expect(!model.isTimerRunning)
        clock.advance(100)
        #expect(model.elapsedSeconds(at: clock.date) == 12)
    }

    @Test("El cronómetro no pasa de 999")
    func timerCap() throws {
        let model = try makeModel()
        model.primaryAction(at: P(1, 1))
        clock.advance(5_000)
        #expect(model.elapsedSeconds(at: clock.date) == 999)
    }

    // MARK: - Apariencia

    @Test("Apariencia de casillas tapadas, marcadas y destapadas")
    func appearances() throws {
        let model = try makeModel()
        #expect(model.appearance(at: P(2, 2)) == .covered)
        model.toggleMark(at: P(0, 0))
        #expect(model.appearance(at: P(0, 0)) == .flagged)
        model.toggleMark(at: P(0, 1))
        model.toggleMark(at: P(0, 1))
        #expect(model.appearance(at: P(0, 1)) == .questioned)
        model.primaryAction(at: P(1, 1))
        #expect(model.appearance(at: P(1, 1)) == .number(1))
    }

    @Test("Al perder: mina detonada, minas visibles y banderas erróneas")
    func lossAppearances() throws {
        let model = try makeModel(mines: [P(0, 0), P(2, 2)])
        model.primaryAction(at: P(1, 1))
        model.toggleMark(at: P(0, 2)) // errónea
        model.primaryAction(at: P(0, 0))
        #expect(model.appearance(at: P(0, 0)) == .detonatedMine)
        #expect(model.appearance(at: P(2, 2)) == .mine)
        #expect(model.appearance(at: P(0, 2)) == .wrongFlag)
        #expect(model.mood == .lost)
    }

    @Test("Casilla vacía tras la cascada y victoria")
    func emptyAndWin() throws {
        let model = try makeModel(mines: [P(0, 0)])
        model.primaryAction(at: P(2, 2))
        #expect(model.appearance(at: P(2, 2)) == .empty)
        #expect(model.status == .won)
        #expect(model.mood == .won)
        #expect(model.appearance(at: P(0, 0)) == .flagged)
    }

    // MARK: - Pulsación

    @Test("Pulsar resalta solo casillas que se pueden destapar")
    func press() throws {
        let model = try makeModel()
        model.press(at: P(2, 2))
        #expect(model.appearance(at: P(2, 2)) == .pressed)
        #expect(model.mood == .tense)

        model.toggleMark(at: P(0, 0))
        model.press(at: P(0, 0))
        #expect(model.appearance(at: P(0, 0)) == .flagged)
        #expect(model.mood == .calm)

        model.press(at: nil)
        #expect(model.pressedPosition == nil)
    }

    @Test("Soltar sobre la casilla destapa y quita el resaltado")
    func releaseReveals() throws {
        let model = try makeModel()
        model.press(at: P(1, 1))
        model.primaryAction(at: P(1, 1))
        #expect(model.pressedPosition == nil)
        #expect(model.appearance(at: P(1, 1)) == .number(1))
    }

    // MARK: - Nueva partida

    @Test("Nueva partida reinicia tablero y cronómetro")
    func newGame() throws {
        let model = try makeModel()
        model.primaryAction(at: P(1, 1))
        clock.advance(3)
        model.newGame()
        #expect(model.status == .ready)
        #expect(!model.isTimerRunning)
        #expect(model.elapsedSeconds(at: clock.date) == 0)
        #expect(model.configuration.width == 3)
        #expect(model.appearance(at: P(1, 1)) == .covered)
    }

    // MARK: - Dificultad

    /// Almacén aislado en su propio dominio de UserDefaults.
    private func makeStore() -> (DifficultyStore, cleanup: () -> Void) {
        let suite = "CazaminasTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (DifficultyStore(defaults: defaults), { defaults.removePersistentDomain(forName: suite) })
    }

    @Test("Cambiar de dificultad empieza una partida nueva con ese tablero")
    func selectDifficulty() throws {
        let model = try makeModel()
        model.primaryAction(at: P(1, 1))
        model.select(.expert)
        #expect(model.difficulty == .expert)
        #expect(model.configuration == .expert)
        #expect(model.remainingMines == 99)
        #expect(model.status == .ready)
        #expect(!model.isTimerRunning)
    }

    @Test("Preguntar por una casilla fuera del tablero no falla")
    func appearanceOutOfBounds() throws {
        let model = try makeModel()
        model.select(.expert)
        model.select(.beginner)
        #expect(model.appearance(at: P(15, 29)) == .covered)
    }

    @Test("Una partida con tablero fijo reconoce su dificultad")
    func difficultyFromGame() throws {
        #expect(try makeModel().difficulty.isCustom)
        let model = GameViewModel(game: Game(configuration: .intermediate), store: nil)
        #expect(model.difficulty == .intermediate)
    }

    @Test("La primera vez se empieza en Principiante")
    func defaultDifficulty() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        let model = GameViewModel(store: store)
        #expect(model.difficulty == .beginner)
        #expect(model.configuration == .beginner)
    }

    @Test("Se recuerda la última dificultad, también la personalizada")
    func remembersDifficulty() throws {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        let custom = Difficulty.custom(try BoardConfiguration(width: 20, height: 12, mines: 50))

        GameViewModel(store: store).select(.intermediate)
        #expect(GameViewModel(store: store).difficulty == .intermediate)

        GameViewModel(store: store).select(custom)
        let reopened = GameViewModel(store: store)
        #expect(reopened.difficulty == custom)
        #expect(reopened.configuration.width == 20)
    }

    @Test("Datos guardados corruptos no impiden arrancar")
    func corruptStoredDifficulty() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        store.defaults.set(Data("basura".utf8), forKey: DifficultyStore.key)
        #expect(GameViewModel(store: store).difficulty == .beginner)
    }
}
