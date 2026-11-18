// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation
import Observation

/// Cómo debe dibujarse una casilla. Se calcula aquí para que las vistas sean tontas
/// y la lógica de presentación se pueda testear.
enum CellAppearance: Hashable, Sendable {
    case covered
    /// Tapada mientras el ratón está pulsado sobre ella.
    case pressed
    case flagged
    case questioned
    /// Destapada, sin minas alrededor.
    case empty
    /// Destapada, con 1–8 minas alrededor.
    case number(Int)
    /// Mina mostrada al perder.
    case mine
    /// La mina que hizo perder la partida.
    case detonatedMine
    /// Bandera puesta en una casilla sin mina (se muestra al perder).
    case wrongFlag
}

/// Expresión del botón de reinicio.
enum Mood: Hashable, Sendable {
    case calm
    case tense
    case won
    case lost
}

/// Conecta el motor (`Game`) con la interfaz: acciones, cronómetro y apariencia.
@MainActor
@Observable
final class GameViewModel {
    private(set) var game: Game
    /// Nivel de la partida actual.
    private(set) var difficulty: Difficulty
    /// Si se está mostrando la hoja de tablero personalizado.
    var isCustomBoardSheetPresented = false
    /// Casilla que el jugador mantiene pulsada (aún no ha soltado el ratón).
    private(set) var pressedPosition: Position?
    /// Momento del primer clic que destapó algo.
    private(set) var startDate: Date?
    /// Momento en que terminó la partida.
    private(set) var endDate: Date?
    /// Estadísticas de todas las partidas.
    private(set) var statistics: Statistics
    /// Resultado de la victoria de la partida actual (tiempo y puesto en la tabla).
    private(set) var lastWin: WinOutcome?

    // Estado para animaciones.
    /// Dónde empezó la última oleada de casillas destapadas (clic o mina detonada).
    private(set) var revealOrigin: Position?
    /// Casillas destapadas por la última acción (al perder, también las minas).
    private(set) var lastRevealed: Set<Position> = []
    /// Contadores que cambian con cada victoria/derrota, para disparar efectos.
    private(set) var winCount = 0
    private(set) var lossCount = 0

    /// Se llama con cada evento de la partida (sonido, háptica).
    @ObservationIgnored var onEvent: (@MainActor (GameEvent) -> Void)?

    @ObservationIgnored let settings: AppSettings
    @ObservationIgnored private let now: @MainActor () -> Date
    @ObservationIgnored private let store: DifficultyStore?
    @ObservationIgnored private let statisticsStore: StatisticsStore?

    /// Empieza con la última dificultad guardada (Principiante la primera vez).
    init(
        settings: AppSettings = AppSettings(),
        store: DifficultyStore? = .standard,
        statisticsStore: StatisticsStore? = .standard,
        now: @escaping @MainActor () -> Date = { Date() }
    ) {
        let difficulty = store?.load() ?? .beginner
        self.settings = settings
        self.difficulty = difficulty
        self.game = Game(configuration: difficulty.configuration, allowsQuestionMarks: settings.allowsQuestionMarks)
        self.statistics = statisticsStore?.load() ?? Statistics()
        self.store = store
        self.statisticsStore = statisticsStore
        self.now = now
    }

    /// Para tests y tableros predefinidos.
    init(
        game: Game,
        settings: AppSettings = AppSettings(),
        store: DifficultyStore? = nil,
        statisticsStore: StatisticsStore? = nil,
        now: @escaping @MainActor () -> Date = { Date() }
    ) {
        self.settings = settings
        self.game = game
        self.difficulty = Difficulty(matching: game.configuration)
        self.statistics = statisticsStore?.load() ?? Statistics()
        self.store = store
        self.statisticsStore = statisticsStore
        self.now = now
    }

    /// Categoría de estadísticas de la partida actual.
    var statsCategory: StatsCategory { StatsCategory(difficulty) }

    // MARK: - Consultas

    var configuration: BoardConfiguration { game.configuration }
    var status: Game.Status { game.status }
    var remainingMines: Int { game.remainingMines }

    /// `true` mientras el cronómetro debe avanzar.
    var isTimerRunning: Bool { startDate != nil && endDate == nil }

    /// Segundos transcurridos, de 0 a 999.
    func elapsedSeconds(at date: Date) -> Int {
        guard let startDate else { return 0 }
        let seconds = (endDate ?? date).timeIntervalSince(startDate)
        return min(999, max(0, Int(seconds)))
    }

    var mood: Mood {
        switch game.status {
        case .won: .won
        case .lost: .lost
        case .ready, .playing: pressedPosition == nil ? .calm : .tense
        }
    }

    /// Retraso de la animación de una casilla recién destapada: crece con la distancia
    /// al origen, para que la cascada (o la cadena de minas al perder) se vea como una onda.
    func revealDelay(at position: Position) -> Double {
        guard let revealOrigin, lastRevealed.contains(position) else { return 0 }
        let distance = max(abs(position.row - revealOrigin.row), abs(position.column - revealOrigin.column))
        return min(Double(distance) * 0.018, 0.6)
    }

    func appearance(at position: Position) -> CellAppearance {
        // Defensa: una vista desfasada puede preguntar por una casilla que ya no existe.
        guard game.board.contains(position) else { return .covered }
        let cell = game[position]
        let isLost: Bool
        if case .lost(let detonated) = game.status {
            if position == detonated { return .detonatedMine }
            isLost = true
        } else {
            isLost = false
        }

        switch cell.state {
        case .revealed:
            if cell.isMine { return .mine }
            return cell.adjacentMines == 0 ? .empty : .number(cell.adjacentMines)
        case .flagged:
            return isLost && !cell.isMine ? .wrongFlag : .flagged
        case .questioned:
            return position == pressedPosition ? .pressed : .questioned
        case .hidden:
            return position == pressedPosition ? .pressed : .covered
        }
    }

    // MARK: - Acciones

    /// Cambia de dificultad, la recuerda y empieza una partida nueva.
    func select(_ difficulty: Difficulty) {
        recordAbandonedGame() // en la categoría de la partida que se deja
        self.difficulty = difficulty
        store?.save(difficulty)
        startNewGame()
    }

    /// Nueva partida con la dificultad actual.
    ///
    /// Una partida empezada y sin terminar cuenta como derrota: así no se puede
    /// proteger la racha reiniciando antes de perder.
    func newGame() {
        recordAbandonedGame()
        startNewGame()
    }

    private func recordAbandonedGame() {
        guard game.status == .playing else { return }
        statistics.recordLoss(in: statsCategory)
        statisticsStore?.save(statistics)
    }

    private func startNewGame() {
        lastWin = nil
        revealOrigin = nil
        lastRevealed = []
        game = Game(
            configuration: difficulty.configuration,
            allowsQuestionMarks: settings.allowsQuestionMarks
        )
        pressedPosition = nil
        startDate = nil
        endDate = nil
    }

    /// El jugador pulsa (sin soltar) sobre una casilla; `nil` si sale del tablero.
    func press(at position: Position?) {
        guard !game.status.isOver, let position, game.board.contains(position) else {
            pressedPosition = nil
            return
        }
        pressedPosition = game[position].state.isRevealable ? position : nil
    }

    /// Clic principal: destapa o hace chording.
    func primaryAction(at position: Position) {
        pressedPosition = nil
        perform(at: position) { $0.primaryAction(at: position) }
    }

    /// Clic secundario: bandera / «?».
    func toggleMark(at position: Position) {
        pressedPosition = nil
        game.allowsQuestionMarks = settings.allowsQuestionMarks
        switch game.toggleMark(at: position) {
        case .flagged: onEvent?(.flagged)
        case .questioned: onEvent?(.questioned)
        case .hidden: onEvent?(.unmarked)
        case .revealed, nil: break
        }
    }

    /// Chording explícito (clic central).
    func chord(at position: Position) {
        pressedPosition = nil
        perform(at: position) { $0.chord(at: position) }
    }

    private func perform(at origin: Position, _ action: (inout Game) -> Set<Position>) {
        let wasReady = game.status == .ready
        let opened = action(&game)
        guard !opened.isEmpty else { return }

        revealOrigin = origin
        lastRevealed = opened
        if wasReady, game.status != .ready {
            startDate = now()
        }

        guard game.status.isOver, endDate == nil else {
            onEvent?(.revealed(count: opened.count))
            return
        }
        let end = now()
        endDate = end
        recordResult(endedAt: end)

        switch game.status {
        case .lost(let detonated):
            // La onda sale de la mina detonada y alcanza al resto de minas.
            revealOrigin = detonated
            lastRevealed = opened.union(game.board.minePositions)
            lossCount += 1
            onEvent?(.lost)
        case .won:
            winCount += 1
            onEvent?(.won)
        case .ready, .playing:
            break
        }
    }

    /// Restablece las estadísticas de una categoría, o todas.
    func resetStatistics(_ category: StatsCategory? = nil) {
        statistics.reset(category)
        statisticsStore?.save(statistics)
    }

    private func recordResult(endedAt end: Date) {
        switch game.status {
        case .won:
            let seconds = startDate.map { end.timeIntervalSince($0) } ?? 0
            lastWin = statistics.recordWin(in: statsCategory, seconds: seconds, date: end)
        case .lost:
            statistics.recordLoss(in: statsCategory)
        case .ready, .playing:
            return
        }
        statisticsStore?.save(statistics)
    }
}
