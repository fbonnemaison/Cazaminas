// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Cuadrícula de casillas, almacenada por filas.
public struct Board: Hashable, Sendable, Codable {
    public let width: Int
    public let height: Int
    public private(set) var cells: [Cell]

    /// Tablero vacío, sin minas.
    public init(width: Int, height: Int) {
        precondition(width >= 1 && height >= 1, "El tablero necesita al menos una casilla")
        self.width = width
        self.height = height
        self.cells = Array(repeating: Cell(), count: width * height)
    }

    /// Tablero con minas en las posiciones indicadas y los números ya calculados.
    public init(width: Int, height: Int, mines: some Sequence<Position>) {
        self.init(width: width, height: height)
        placeMines(at: mines)
    }

    // MARK: - Acceso

    /// Si la posición está dentro del tablero.
    public func contains(_ position: Position) -> Bool {
        (0..<height).contains(position.row) && (0..<width).contains(position.column)
    }

    public internal(set) subscript(position: Position) -> Cell {
        get { cells[index(of: position)] }
        set { cells[index(of: position)] = newValue }
    }

    /// Todas las posiciones, por filas.
    public var positions: [Position] {
        (0..<height).flatMap { row in (0..<width).map { Position(row: row, column: $0) } }
    }

    /// Las hasta 8 casillas que rodean a `position`, diagonales incluidas.
    public func neighbors(of position: Position) -> [Position] {
        var result: [Position] = []
        result.reserveCapacity(8)
        for dr in -1...1 {
            for dc in -1...1 where dr != 0 || dc != 0 {
                let neighbor = Position(row: position.row + dr, column: position.column + dc)
                if contains(neighbor) { result.append(neighbor) }
            }
        }
        return result
    }

    /// Posiciones que contienen mina.
    public var minePositions: [Position] {
        positions.filter { self[$0].isMine }
    }

    // MARK: - Minas

    /// Coloca minas en las posiciones dadas y recalcula los números de todo el tablero.
    mutating func placeMines(at mines: some Sequence<Position>) {
        for position in mines {
            precondition(contains(position), "Mina fuera del tablero: \(position)")
            self[position].isMine = true
        }
        for position in positions {
            self[position].adjacentMines = neighbors(of: position).count { self[$0].isMine }
        }
    }

    private func index(of position: Position) -> Int {
        precondition(contains(position), "Posición fuera del tablero: \(position)")
        return position.row * width + position.column
    }
}
