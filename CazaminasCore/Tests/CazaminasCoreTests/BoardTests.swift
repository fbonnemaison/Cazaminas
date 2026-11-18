// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import CazaminasCore

@Suite("Configuración y tablero")
struct BoardTests {
    @Test("Configuraciones válidas")
    func validConfiguration() throws {
        let configuration = try BoardConfiguration(width: 30, height: 16, mines: 99)
        #expect(configuration.cellCount == 480)
        #expect(configuration.safeCellCount == 381)
        _ = try BoardConfiguration(width: 1, height: 2, mines: 1)
    }

    @Test("Configuraciones imposibles se rechazan")
    func invalidConfiguration() {
        #expect(throws: BoardConfiguration.ValidationError.invalidDimensions) {
            try BoardConfiguration(width: 0, height: 9, mines: 1)
        }
        #expect(throws: BoardConfiguration.ValidationError.invalidMineCount) {
            try BoardConfiguration(width: 9, height: 9, mines: 0)
        }
        #expect(throws: BoardConfiguration.ValidationError.invalidMineCount) {
            try BoardConfiguration(width: 3, height: 3, mines: 9)
        }
    }

    @Test("Vecinos: 3 en esquina, 5 en borde, 8 en el interior")
    func neighbors() {
        let board = Board(width: 4, height: 3)
        #expect(board.neighbors(of: P(0, 0)).count == 3)
        #expect(board.neighbors(of: P(2, 3)).count == 3)
        #expect(board.neighbors(of: P(0, 1)).count == 5)
        #expect(board.neighbors(of: P(1, 0)).count == 5)
        #expect(Set(board.neighbors(of: P(1, 1))) == [
            P(0, 0), P(0, 1), P(0, 2),
            P(1, 0), P(1, 2),
            P(2, 0), P(2, 1), P(2, 2),
        ])
    }

    @Test("Los números cuentan las minas vecinas, diagonales incluidas")
    func adjacentCounts() {
        // M M 1
        // 2 2 1
        // 0 0 0
        let board = Board(width: 3, height: 3, mines: [P(0, 0), P(0, 1)])
        #expect(board[P(0, 2)].adjacentMines == 1)
        #expect(board[P(1, 0)].adjacentMines == 2)
        #expect(board[P(1, 1)].adjacentMines == 2)
        #expect(board[P(1, 2)].adjacentMines == 1)
        #expect(board[P(2, 0)].adjacentMines == 0)
        #expect(board[P(2, 2)].adjacentMines == 0)
        #expect(board[P(0, 0)].adjacentMines == 1)
        #expect(Set(board.minePositions) == [P(0, 0), P(0, 1)])
    }

    @Test("Todas las casillas están dentro del tablero")
    func positions() {
        let board = Board(width: 5, height: 2)
        #expect(board.positions.count == 10)
        #expect(board.positions.allSatisfy(board.contains))
        #expect(!board.contains(P(2, 0)))
        #expect(!board.contains(P(0, -1)))
    }
}
