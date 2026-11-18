// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Estado visible de una casilla.
public enum CellState: Hashable, Sendable, Codable {
    /// Oculta, sin marca.
    case hidden
    /// Oculta, marcada con bandera (el jugador cree que hay una mina).
    case flagged
    /// Oculta, marcada con interrogación (el jugador duda).
    case questioned
    /// Destapada.
    case revealed

    /// `true` si la casilla sigue tapada (con o sin marca).
    public var isCovered: Bool { self != .revealed }

    /// `true` si se puede destapar con un clic (las banderas protegen la casilla).
    public var isRevealable: Bool { self == .hidden || self == .questioned }
}

/// Una casilla del tablero.
public struct Cell: Hashable, Sendable, Codable {
    /// Si la casilla contiene una mina.
    public internal(set) var isMine: Bool
    /// Número de minas en las 8 casillas vecinas (0–8).
    public internal(set) var adjacentMines: Int
    /// Estado visible de la casilla.
    public internal(set) var state: CellState

    public init(isMine: Bool = false, adjacentMines: Int = 0, state: CellState = .hidden) {
        self.isMine = isMine
        self.adjacentMines = adjacentMines
        self.state = state
    }
}
