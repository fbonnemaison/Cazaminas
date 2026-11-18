// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Foundation
import Testing
@testable import CazaminasCore

@Suite("Reglas de la partida")
struct GameTests {
    // MARK: - Revelar y cascada

    @Test("Una partida nueva empieza lista y sin minas colocadas")
    func newGame() throws {
        let game = Game(configuration: try BoardConfiguration(width: 9, height: 9, mines: 10))
        #expect(game.status == .ready)
        #expect(!game.minesPlaced)
        #expect(game.remainingMines == 10)
        #expect(game.board.positions.allSatisfy { game[$0].state == .hidden })
    }

    @Test("Destapar un 0 abre en cascada toda el área y su borde")
    func cascade() throws {
        var game = try makeGame(width: 5, height: 5, mines: [P(4, 4)])
        let opened = game.reveal(at: P(0, 0))
        #expect(opened.count == 24)
        #expect(game.revealedCount == 24)
        #expect(game.status == .won)
    }

    @Test("La cascada se detiene en los números")
    func cascadeStopsAtNumbers() throws {
        // Una columna de minas a la derecha: la cascada no debe cruzarla.
        var game = try makeGame(width: 5, height: 3, mines: [P(0, 3), P(1, 3), P(2, 3)])
        let opened = game.reveal(at: P(1, 0))
        #expect(opened == Set((0..<3).flatMap { row in [P(row, 0), P(row, 1), P(row, 2)] }))
        #expect(game[P(1, 4)].state == .hidden)
        #expect(game.status == .playing)
    }

    @Test("Destapar un número no abre nada más")
    func revealNumber() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        let opened = game.reveal(at: P(1, 1))
        #expect(opened == [P(1, 1)])
        #expect(game[P(1, 1)].adjacentMines == 1)
        #expect(game.status == .playing)
    }

    @Test("Destapar dos veces la misma casilla no hace nada")
    func revealTwice() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.reveal(at: P(1, 1))
        #expect(game.reveal(at: P(1, 1)).isEmpty)
        #expect(game.revealedCount == 1)
    }

    @Test("Posiciones fuera del tablero se ignoran")
    func outOfBounds() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        #expect(game.reveal(at: P(5, 5)).isEmpty)
        #expect(game.toggleMark(at: P(-1, 0)) == nil)
        #expect(game.chord(at: P(3, 0)).isEmpty)
        #expect(game.status == .ready)
    }

    // MARK: - Marcas

    @Test("Ciclo de marcas: sin marca → bandera → «?» → sin marca")
    func markCycleWithQuestion() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        #expect(game.toggleMark(at: P(0, 0)) == .flagged)
        #expect(game.remainingMines == 0)
        #expect(game.toggleMark(at: P(0, 0)) == .questioned)
        #expect(game.remainingMines == 1)
        #expect(game.toggleMark(at: P(0, 0)) == .hidden)
        #expect(game.status == .ready)
    }

    @Test("Sin «?», la marca alterna entre bandera y sin marca")
    func markCycleWithoutQuestion() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)], allowsQuestionMarks: false)
        #expect(game.toggleMark(at: P(0, 0)) == .flagged)
        #expect(game.toggleMark(at: P(0, 0)) == .hidden)
    }

    @Test("Una bandera protege la casilla de ser destapada")
    func flagProtects() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.toggleMark(at: P(0, 0))
        #expect(game.reveal(at: P(0, 0)).isEmpty)
        #expect(game[P(0, 0)].state == .flagged)
        #expect(game.status == .ready)
    }

    @Test("Una casilla con «?» sí se puede destapar")
    func questionedCanBeRevealed() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.toggleMark(at: P(1, 1))
        game.toggleMark(at: P(1, 1))
        #expect(game.reveal(at: P(1, 1)) == [P(1, 1)])
    }

    @Test("La cascada abre las «?» pero respeta las banderas")
    func cascadeAndMarks() throws {
        var game = try makeGame(width: 5, height: 5, mines: [P(4, 4)])
        game.toggleMark(at: P(2, 2))
        game.toggleMark(at: P(2, 2)) // «?»
        game.toggleMark(at: P(0, 4)) // bandera incorrecta
        let opened = game.reveal(at: P(0, 0))
        #expect(opened.contains(P(2, 2)))
        #expect(!opened.contains(P(0, 4)))
        #expect(game[P(0, 4)].state == .flagged)
        #expect(game.status == .playing)
    }

    @Test("No se pueden marcar casillas destapadas")
    func cannotMarkRevealed() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.reveal(at: P(1, 1))
        #expect(game.toggleMark(at: P(1, 1)) == nil)
    }

    @Test("El contador de minas puede ser negativo si sobran banderas")
    func negativeRemainingMines() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.toggleMark(at: P(0, 0))
        game.toggleMark(at: P(2, 2))
        #expect(game.flagCount == 2)
        #expect(game.remainingMines == -1)
    }

    // MARK: - Chording

    @Test("Chording con las banderas correctas destapa el resto de vecinas")
    func chordOpensNeighbors() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.reveal(at: P(1, 1))
        game.toggleMark(at: P(0, 0))
        let opened = game.chord(at: P(1, 1))
        #expect(opened.count == 7)
        #expect(game.status == .won)
    }

    @Test("Chording sin suficientes banderas no hace nada")
    func chordNeedsFlags() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.reveal(at: P(1, 1))
        #expect(game.chord(at: P(1, 1)).isEmpty)
        #expect(game.revealedCount == 1)
    }

    @Test("Chording con una bandera incorrecta hace perder")
    func chordWithWrongFlagLoses() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.reveal(at: P(1, 1))
        game.toggleMark(at: P(2, 2))
        game.chord(at: P(1, 1))
        #expect(game.status == .lost(detonated: P(0, 0)))
        #expect(game.wrongFlags == [P(2, 2)])
    }

    @Test("Chording sobre un 0 o una casilla tapada no hace nada")
    func chordIgnoredOnZeroOrCovered() throws {
        var game = try makeGame(width: 5, height: 5, mines: [P(4, 4)])
        #expect(game.chord(at: P(0, 0)).isEmpty)
        game.toggleMark(at: P(4, 4))
        game.reveal(at: P(3, 3))
        game.reveal(at: P(0, 0))
        #expect(game.chord(at: P(0, 0)).isEmpty)
    }

    @Test("La acción principal destapa casillas tapadas y hace chording en números")
    func primaryAction() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        #expect(game.primaryAction(at: P(1, 1)) == [P(1, 1)])
        game.toggleMark(at: P(0, 0))
        #expect(game.primaryAction(at: P(1, 1)).count == 7)
        #expect(game.status == .won)
    }

    // MARK: - Fin de partida

    @Test("Destapar una mina pierde y muestra todas las minas sin marcar")
    func loss() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0), P(0, 2)])
        game.reveal(at: P(1, 1)) // un 2: no abre en cascada
        game.toggleMark(at: P(0, 2))
        game.toggleMark(at: P(1, 0)) // bandera incorrecta
        game.reveal(at: P(0, 0))

        #expect(game.status == .lost(detonated: P(0, 0)))
        #expect(game.status.isOver)
        #expect(game[P(0, 0)].state == .revealed)
        #expect(game[P(0, 2)].state == .flagged)
        #expect(game.wrongFlags == [P(1, 0)])
    }

    @Test("Tras perder, ninguna acción tiene efecto")
    func noActionsAfterLoss() throws {
        var game = try makeGame(width: 3, height: 3, mines: [P(0, 0)])
        game.reveal(at: P(0, 0))
        #expect(game.reveal(at: P(2, 2)).isEmpty)
        #expect(game.toggleMark(at: P(2, 2)) == nil)
        #expect(game.primaryAction(at: P(1, 1)).isEmpty)
    }

    @Test("Se gana al destapar todas las casillas seguras, sin necesidad de banderas")
    func winWithoutFlags() throws {
        var game = try makeGame(width: 3, height: 1, mines: [P(0, 1)])
        game.reveal(at: P(0, 0))
        #expect(game.status == .playing)
        game.reveal(at: P(0, 2))
        #expect(game.status == .won)
        #expect(game[P(0, 1)].state == .flagged)
        #expect(game.remainingMines == 0)
        #expect(game.toggleMark(at: P(0, 1)) == nil)
    }

    // MARK: - Persistencia

    @Test("Una partida a medias se codifica y decodifica sin cambios")
    func codableRoundTrip() throws {
        var game = Game(configuration: try BoardConfiguration(width: 9, height: 9, mines: 10), seed: 99)
        game.reveal(at: P(4, 4))
        if let covered = game.board.positions.first(where: { game[$0].state == .hidden }) {
            game.toggleMark(at: covered)
        }
        let data = try JSONEncoder().encode(game)
        let decoded = try JSONDecoder().decode(Game.self, from: data)
        #expect(decoded == game)
    }

    @Test("Decodificar una configuración imposible falla")
    func invalidConfigurationDecoding() {
        let json = Data(#"{"width": 3, "height": 3, "mines": 20}"#.utf8)
        #expect(throws: BoardConfiguration.ValidationError.self) {
            try JSONDecoder().decode(BoardConfiguration.self, from: json)
        }
    }
}
