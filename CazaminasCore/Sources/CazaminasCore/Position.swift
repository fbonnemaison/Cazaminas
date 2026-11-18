// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Coordenadas de una casilla del tablero. `row` crece hacia abajo y `column` hacia la derecha.
public struct Position: Hashable, Sendable, Codable, CustomStringConvertible {
    public var row: Int
    public var column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public var description: String { "(\(row), \(column))" }
}
