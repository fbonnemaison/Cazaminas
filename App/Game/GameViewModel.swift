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

    // Modo sin adivinar y pistas.
    /// Modo fijado en el primer clic; antes de eso manda el ajuste.
    private var lockedMode: GameMode?
    /// Se está generando un tablero sin adivinar (tras el primer clic).
    private(set) var isGenerating = false
    /// No se encontró un tablero sin adivinar y se juega uno clásico.
    private(set) var noGuessFallback = false
    /// Pista visible, si la hay.
    private(set) var hint: Hint?
    /// Se pidió una pista y no hay ninguna jugada segura.
    private(set) var hintUnavailable = false
    /// Se usó al menos una pista en esta partida (no cuenta para récords).
    private(set) var usedHint = false
    @ObservationIgnored private var generationToken: UUID?
    /// Tarea de generación en curso (los tests la esperan).
    @ObservationIgnored private(set) var generationTask: Task<Void, Never>?

    // Pausa.
    /// La partida está en pausa: el tablero se oculta y el cronómetro se detiene.
    private(set) var isPaused = false
    private var pausedAt: Date?
    /// Tiempo total en pausa durante esta partida.
    private var pausedTotal: TimeInterval = 0

    // Teclado.
    /// Casilla seleccionada con el teclado.
    private(set) var cursor: Position?
    /// Si se dibuja el cursor (solo tras usar el teclado).
    private(set) var showsCursor = false

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

    /// Modo de la partida actual.
    var mode: GameMode {
        lockedMode ?? (settings.noGuessMode ? .noGuess : .classic)
    }

    /// Tipo de pista que se muestra en una casilla, si la hay.
    func hintKind(at position: Position) -> Hint.Kind? {
        hint?.position == position ? hint?.kind : nil
    }

    // MARK: - Consultas

    var configuration: BoardConfiguration { game.configuration }
    var status: Game.Status { game.status }
    var remainingMines: Int { game.remainingMines }

    /// `true` mientras el cronómetro debe avanzar.
    var isTimerRunning: Bool { startDate != nil && endDate == nil && !isPaused }

    /// Tiempo de juego real: desde el primer clic, sin contar las pausas.
    func elapsedInterval(at date: Date) -> TimeInterval {
        guard let startDate else { return 0 }
        let end = endDate ?? pausedAt ?? date
        return max(0, end.timeIntervalSince(startDate) - pausedTotal)
    }

    /// Segundos transcurridos, de 0 a 999.
    func elapsedSeconds(at date: Date) -> Int {
        min(999, Int(elapsedInterval(at: date)))
    }

    // MARK: - Teclado

    /// Las acciones con ratón dejan el cursor donde se hizo clic, pero sin dibujarlo.
    private func moveCursorSilently(to position: Position) {
        guard game.board.contains(position) else { return }
        cursor = position
        showsCursor = false
    }

    private var boardCenter: Position {
        Position(row: game.configuration.height / 2, column: game.configuration.width / 2)
    }

    /// Mueve el cursor con las flechas (sin salir del tablero).
    func moveCursor(rows: Int, columns: Int) {
        guard !isPaused else { return }
        guard let current = cursor, showsCursor else {
            // La primera tecla solo muestra el cursor.
            cursor = cursor ?? boardCenter
            showsCursor = true
            return
        }
        cursor = Position(
            row: (current.row + rows).clamped(to: 0...(game.configuration.height - 1)),
            column: (current.column + columns).clamped(to: 0...(game.configuration.width - 1))
        )
    }

    /// Espacio: destapar (o chording sobre un número).
    func keyboardPrimary() { keyboardAction(primaryAction(at:)) }
    /// F: bandera / «?».
    func keyboardMark() { keyboardAction(toggleMark(at:)) }
    /// Intro: chording.
    func keyboardChord() { keyboardAction(chord(at:)) }

    private func keyboardAction(_ action: (Position) -> Void) {
        guard let cursor, showsCursor else {
            moveCursor(rows: 0, columns: 0)
            return
        }
        action(cursor)
        showsCursor = true
    }

    // MARK: - Accesibilidad

    /// Descripción de una casilla para VoiceOver, p. ej. «Fila 3, columna 5: 2 minas cerca».
    func accessibilityLabel(at position: Position) -> String {
        let place = String(localized: "Fila \(position.row + 1), columna \(position.column + 1)")
        let state: String = switch appearance(at: position) {
        case .covered, .pressed: String(localized: "tapada")
        case .flagged: String(localized: "bandera")
        case .questioned: String(localized: "interrogación")
        case .empty: String(localized: "vacía")
        case .number(1): String(localized: "1 mina cerca")
        case .number(let count): String(localized: "\(count) minas cerca")
        case .mine: String(localized: "mina")
        case .detonatedMine: String(localized: "mina detonada")
        case .wrongFlag: String(localized: "bandera incorrecta")
        }
        let hint: String = switch hintKind(at: position) {
        case .safe: String(localized: ", pista: segura")
        case .mine: String(localized: ", pista: mina")
        case nil: ""
        }
        return "\(place): \(state)\(hint)"
    }

    // MARK: - Pausa

    /// Solo se puede pausar una partida en curso.
    var canPause: Bool { game.status == .playing && startDate != nil && !isPaused }

    /// Detiene el cronómetro y oculta el tablero.
    func pause() {
        guard canPause else { return }
        pressedPosition = nil
        isPaused = true
        pausedAt = now()
    }

    func resume() {
        guard isPaused, let pausedAt else { return }
        pausedTotal += now().timeIntervalSince(pausedAt)
        self.pausedAt = nil
        isPaused = false
    }

    func togglePause() {
        isPaused ? resume() : pause()
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
        statistics.recordLoss(in: statsCategory, mode: mode)
        statisticsStore?.save(statistics)
    }

    private func startNewGame() {
        generationTask?.cancel()
        generationTask = nil
        generationToken = nil
        isGenerating = false
        noGuessFallback = false
        lockedMode = nil
        clearHint()
        usedHint = false
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
        isPaused = false
        pausedAt = nil
        pausedTotal = 0
        if let cursor, !game.board.contains(cursor) {
            self.cursor = nil
        }
    }

    /// El jugador pulsa (sin soltar) sobre una casilla; `nil` si sale del tablero.
    func press(at position: Position?) {
        guard !game.status.isOver, !isPaused, let position, game.board.contains(position) else {
            pressedPosition = nil
            return
        }
        pressedPosition = game[position].state.isRevealable ? position : nil
    }

    /// Clic principal: destapa o hace chording.
    func primaryAction(at position: Position) {
        pressedPosition = nil
        moveCursorSilently(to: position)
        guard !isGenerating, !isPaused else { return }
        clearHint()
        if game.status == .ready, !game.minesPlaced, mode == .noGuess,
           game.board.contains(position), game[position].state.isRevealable {
            startNoGuessGame(firstClick: position)
            return
        }
        perform(at: position) { $0.primaryAction(at: position) }
    }

    /// Genera en segundo plano un tablero resoluble sin adivinar y destapa el primer clic.
    private func startNoGuessGame(firstClick: Position) {
        isGenerating = true
        lockedMode = .noGuess
        let configuration = game.configuration
        let seed = game.seed
        // Marcas puestas antes del primer clic: se conservan en el tablero nuevo.
        let marks = game.board.positions.filter { game[$0].state == .flagged || game[$0].state == .questioned }
            .map { ($0, game[$0].state) }
        let token = UUID()
        generationToken = token

        generationTask = Task { [weak self] in
            let mines = await Task.detached(priority: .userInitiated) {
                NoGuessGenerator.minePositions(for: configuration, firstClick: firstClick, seed: seed)
            }.value
            guard let self, self.generationToken == token else { return }
            self.isGenerating = false
            if let mines {
                var fresh = Game(configuration: configuration, minePositions: Set(mines), allowsQuestionMarks: true)
                for (position, state) in marks {
                    fresh.toggleMark(at: position)
                    if state == .questioned { fresh.toggleMark(at: position) }
                }
                fresh.allowsQuestionMarks = self.settings.allowsQuestionMarks
                self.game = fresh
            } else {
                // Tablero demasiado denso: se juega uno clásico y se avisa.
                self.noGuessFallback = true
                self.lockedMode = .classic
            }
            self.perform(at: firstClick) { $0.reveal(at: firstClick) }
        }
    }

    /// Muestra la siguiente jugada deducible (o avisa de que toca arriesgarse).
    func showHint() {
        guard !isGenerating, !isPaused, !game.status.isOver else { return }
        hint = Solver.hint(for: game)
        hintUnavailable = hint == nil
        if hint != nil, game.status == .playing {
            usedHint = true
        }
    }

    private func clearHint() {
        hint = nil
        hintUnavailable = false
    }

    /// Clic secundario: bandera / «?».
    func toggleMark(at position: Position) {
        pressedPosition = nil
        moveCursorSilently(to: position)
        guard !isGenerating, !isPaused else { return }
        clearHint()
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
        moveCursorSilently(to: position)
        guard !isGenerating, !isPaused else { return }
        clearHint()
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
            lockedMode = mode
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

    /// Restablece las estadísticas de una categoría (o todas) en un modo (o en los dos).
    func resetStatistics(_ category: StatsCategory? = nil, mode: GameMode? = nil) {
        statistics.reset(category, mode: mode)
        statisticsStore?.save(statistics)
    }

    private func recordResult(endedAt end: Date) {
        switch game.status {
        case .won:
            let seconds = elapsedInterval(at: end)
            lastWin = statistics.recordWin(
                in: statsCategory, mode: mode, seconds: seconds, date: end, countsForBestTimes: !usedHint
            )
        case .lost:
            statistics.recordLoss(in: statsCategory, mode: mode)
        case .ready, .playing:
            return
        }
        statisticsStore?.save(statistics)
    }
}
