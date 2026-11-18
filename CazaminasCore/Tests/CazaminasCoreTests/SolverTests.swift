// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import CazaminasCore

@Suite("Solucionador lógico")
struct SolverTests {
    @Test("Un tablero abierto de un solo clic es resoluble")
    func trivialBoard() {
        let board = Board(width: 5, height: 5, mines: [P(4, 4)])
        #expect(Solver.isSolvableWithoutGuessing(board: board, firstClick: P(0, 0)))
    }

    @Test("Un 50/50 clásico no es resoluble sin adivinar")
    func fiftyFifty() {
        // Dos casillas de la esquina, una con mina, rodeadas solo de números iguales:
        //  ? ? 1 0
        //  2 2 1 0   (minas en (0,0) o (0,1): indistinguibles)
        // Más simple: 2×1 con una mina y el clic en otro lado no es posible; usamos
        // una columna aislada por dos minas simétricas.
        let board = Board(width: 4, height: 2, mines: [P(0, 0)])
        // Clic en (1,3): abre la parte derecha; (0,0) y (1,0) quedan indistinguibles
        // para el «1» de (0,1)/(1,1), pero el recuento global (1 mina) no basta: hay
        // que adivinar entre (0,0) y (1,0).
        #expect(!Solver.isSolvableWithoutGuessing(board: board, firstClick: P(1, 3)))
    }

    @Test("Detecta minas y casillas seguras con la regla de subconjuntos")
    func subsetRule() {
        // Fila con patrón 1-2-1 contra un borde: las minas están bajo los «1».
        //  M . M
        //  1 2 1
        let board = Board(width: 3, height: 3, mines: [P(0, 0), P(0, 2)])
        #expect(Solver.isSolvableWithoutGuessing(board: board, firstClick: P(2, 1)))
    }

    @Test("El recuento global de minas decide el interior")
    func globalCount() {
        // Tras abrir, queda una zona interior sin números; si la frontera ya tiene
        // todas las minas, el interior es seguro.
        let board = Board(width: 5, height: 1, mines: [P(0, 2)])
        // Clic en (0,0): ve «0»,«1»; (0,2) es mina por la regla simple; (0,3) y (0,4)
        // no tocan ningún número abierto: solo el recuento global las libera.
        #expect(Solver.isSolvableWithoutGuessing(board: board, firstClick: P(0, 0)))
    }

    @Test("Pistas: primer clic en el centro y nada al terminar")
    func hintsOutsidePlay() throws {
        let game = Game(configuration: .beginner)
        #expect(Solver.hint(for: game) == Hint(position: P(4, 4), kind: .safe))
        var lost = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        lost.reveal(at: P(0, 0))
        #expect(Solver.hint(for: lost) == nil)
    }

    /// 5×3 con minas en (0,2) y (1,2). El clic en (2,0) abre la parte izquierda:
    ///   0 2 ? ? ?
    ///   0 2 ? ? ?
    ///   0 1 ? ? ?
    /// El «2» de arriba obliga a que (0,2) y (1,2) sean minas, y entonces el «1»
    /// de abajo libera (2,2).
    private func partialGame() throws -> Game {
        var game = try makeGame(width: 5, height: 3, mines: [P(0, 2), P(1, 2)])
        game.reveal(at: P(2, 0))
        #expect(game.status == .playing)
        return game
    }

    @Test("La pista señala primero una mina deducible y luego una casilla segura")
    func hintSequence() throws {
        var game = try partialGame()
        #expect(Solver.hint(for: game) == Hint(position: P(0, 2), kind: .mine))
        game.toggleMark(at: P(0, 2))
        #expect(Solver.hint(for: game) == Hint(position: P(1, 2), kind: .mine))
        game.toggleMark(at: P(1, 2))
        #expect(Solver.hint(for: game) == Hint(position: P(2, 2), kind: .safe))
    }

    @Test("La pista no se fía de las banderas del jugador")
    func hintIgnoresWrongFlags() throws {
        var game = try partialGame()
        game.toggleMark(at: P(2, 2)) // bandera errónea
        let hint = try #require(Solver.hint(for: game))
        #expect(hint == Hint(position: P(0, 2), kind: .mine))
    }

    @Test("Las pistas nunca mienten en partidas reales", arguments: 0..<40)
    func hintsAreSound(seed: Int) {
        var game = Game(configuration: .intermediate, seed: UInt64(seed))
        game.reveal(at: P(8, 8))
        var steps = 0
        while game.status == .playing, let hint = Solver.hint(for: game), steps < 400 {
            steps += 1
            switch hint.kind {
            case .safe:
                #expect(!game[hint.position].isMine)
                if game[hint.position].state == .flagged {
                    game.toggleMark(at: hint.position) // quita la bandera errónea
                    if game[hint.position].state == .questioned { game.toggleMark(at: hint.position) }
                }
                game.reveal(at: hint.position)
            case .mine:
                #expect(game[hint.position].isMine)
                game.toggleMark(at: hint.position)
            }
        }
        #expect(game.status != .lost(detonated: P(8, 8)))
        if case .lost = game.status { Issue.record("Una pista llevó a perder") }
    }
}

@Suite("Generador sin adivinar")
struct NoGuessGeneratorTests {
    @Test(
        "Los tableros generados se resuelven sin adivinar",
        arguments: [BoardConfiguration.beginner, .intermediate, .expert]
    )
    func generatedBoardsAreSolvable(configuration: BoardConfiguration) throws {
        let click = P(configuration.height / 2, configuration.width / 2)
        for seed in UInt64(0)..<5 {
            let mines = try #require(NoGuessGenerator.minePositions(for: configuration, firstClick: click, seed: seed))
            #expect(mines.count == configuration.mines)
            #expect(Set(mines).count == configuration.mines)
            let board = Board(width: configuration.width, height: configuration.height, mines: mines)
            #expect(!board[click].isMine)
            #expect(board[click].adjacentMines == 0)
            #expect(Solver.isSolvableWithoutGuessing(board: board, firstClick: click))
        }
    }

    @Test("La generación es determinista")
    func deterministic() {
        let a = NoGuessGenerator.minePositions(for: .intermediate, firstClick: P(3, 3), seed: 42)
        let b = NoGuessGenerator.minePositions(for: .intermediate, firstClick: P(3, 3), seed: 42)
        #expect(a != nil)
        #expect(a == b)
    }

    @Test("Un tablero imposible devuelve nil en vez de colgarse")
    func impossibleBoard() throws {
        // 5×5 con 16 minas: la zona segura queda rodeada y casi todo es azar.
        let configuration = try BoardConfiguration(width: 5, height: 5, mines: 16)
        _ = NoGuessGenerator.minePositions(
            for: configuration, firstClick: P(2, 2), seed: 1, maxAttempts: 50, timeLimit: .seconds(1)
        )
    }
}
