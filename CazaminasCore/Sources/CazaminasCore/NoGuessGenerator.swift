// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Modo de juego.
public enum GameMode: String, CaseIterable, Identifiable, Hashable, Sendable, Codable {
    /// Minas al azar (con primer clic seguro): a veces hay que adivinar.
    case classic
    /// Tableros que siempre se pueden resolver con lógica desde el primer clic.
    case noGuess

    public var id: Self { self }
}

/// Genera tableros que el `Solver` resuelve sin adivinar.
///
/// Prueba tableros al azar (con el primer clic seguro) hasta encontrar uno resoluble.
/// Es determinista: la misma semilla y el mismo primer clic dan el mismo tablero.
public enum NoGuessGenerator {
    /// Posiciones de las minas, o `nil` si no se encontró un tablero resoluble
    /// dentro de los límites (tableros muy densos).
    public static func minePositions(
        for configuration: BoardConfiguration,
        firstClick: Position,
        seed: UInt64,
        maxAttempts: Int = 3_000,
        timeLimit: Duration = .seconds(5)
    ) -> [Position]? {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeLimit)
        for attempt in 0..<maxAttempts {
            if clock.now > deadline { return nil }
            let attemptSeed = seed &+ UInt64(attempt) &* 0x9E37_79B9_7F4A_7C15
            let mines = MinePlacer.minePositions(for: configuration, firstClick: firstClick, seed: attemptSeed)
            let board = Board(width: configuration.width, height: configuration.height, mines: mines)
            if Solver.isSolvableWithoutGuessing(board: board, firstClick: firstClick) {
                return mines
            }
        }
        return nil
    }
}
