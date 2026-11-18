// Cazaminas — © 2026 App-Zilla. Licencia MIT.

@testable import CazaminasCore

/// Atajo para crear posiciones en los tests.
func P(_ row: Int, _ column: Int) -> Position {
    Position(row: row, column: column)
}

/// Partida con minas fijas.
func makeGame(
    width: Int,
    height: Int,
    mines: [Position],
    allowsQuestionMarks: Bool = true
) throws -> Game {
    let configuration = try BoardConfiguration(width: width, height: height, mines: mines.count)
    return Game(configuration: configuration, minePositions: Set(mines), allowsQuestionMarks: allowsQuestionMarks)
}
