// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Una partida de Cazaminas: el tablero, su estado y las reglas del juego.
///
/// Es un tipo valor: cada acción muta la partida y devuelve las casillas que se han
/// destapado, para que la interfaz pueda animarlas.
public struct Game: Hashable, Sendable, Codable {
    /// Estado de la partida.
    public enum Status: Hashable, Sendable, Codable {
        /// Aún no se ha destapado ninguna casilla (el cronómetro no ha empezado).
        case ready
        /// Partida en curso.
        case playing
        /// Todas las casillas seguras están destapadas.
        case won
        /// Se ha destapado una mina.
        case lost(detonated: Position)

        /// `true` si la partida ha terminado (ganada o perdida).
        public var isOver: Bool {
            switch self {
            case .won, .lost: true
            case .ready, .playing: false
            }
        }
    }

    public let configuration: BoardConfiguration
    /// Semilla con la que se colocan las minas tras el primer clic.
    public let seed: UInt64
    /// Si el ciclo de marcas incluye la interrogación «?».
    public var allowsQuestionMarks: Bool

    public private(set) var board: Board
    public private(set) var status: Status = .ready
    /// Si las minas ya están en el tablero (se colocan con el primer clic).
    public private(set) var minesPlaced: Bool
    /// Número de banderas colocadas.
    public private(set) var flagCount = 0
    /// Número de casillas seguras destapadas.
    public private(set) var revealedCount = 0

    /// Nueva partida. Las minas se colocan con el primer clic, que nunca es una mina.
    public init(
        configuration: BoardConfiguration,
        seed: UInt64 = .random(in: .min ... .max),
        allowsQuestionMarks: Bool = true
    ) {
        self.configuration = configuration
        self.seed = seed
        self.allowsQuestionMarks = allowsQuestionMarks
        self.board = Board(width: configuration.width, height: configuration.height)
        self.minesPlaced = false
    }

    /// Partida con las minas en posiciones fijas (tests, repeticiones, tableros compartidos).
    ///
    /// Aquí el primer clic **no** está protegido: las minas ya están colocadas.
    public init(
        configuration: BoardConfiguration,
        minePositions: Set<Position>,
        allowsQuestionMarks: Bool = true
    ) {
        precondition(minePositions.count == configuration.mines, "El número de minas no coincide con la configuración")
        self.configuration = configuration
        self.seed = 0
        self.allowsQuestionMarks = allowsQuestionMarks
        self.board = Board(width: configuration.width, height: configuration.height, mines: minePositions)
        self.minesPlaced = true
    }

    // MARK: - Consultas

    /// Minas sin marcar según el jugador: minas − banderas. Puede ser negativo si sobran banderas.
    public var remainingMines: Int { configuration.mines - flagCount }

    /// Banderas colocadas sobre casillas sin mina. La interfaz las señala al perder.
    public var wrongFlags: [Position] {
        board.positions.filter { board[$0].state == .flagged && !board[$0].isMine }
    }

    /// Casilla en `position`.
    public subscript(position: Position) -> Cell { board[position] }

    // MARK: - Acciones

    /// Acción principal (clic izquierdo / toque): destapa una casilla tapada,
    /// o hace chording si la casilla ya está destapada.
    @discardableResult
    public mutating func primaryAction(at position: Position) -> Set<Position> {
        guard board.contains(position) else { return [] }
        return board[position].state == .revealed ? chord(at: position) : reveal(at: position)
    }

    /// Destapa una casilla. Si es un 0, destapa en cascada toda el área vacía y su borde.
    ///
    /// Las casillas con bandera están protegidas y no se destapan.
    /// - Returns: las casillas destapadas por esta acción.
    @discardableResult
    public mutating func reveal(at position: Position) -> Set<Position> {
        guard !status.isOver, board.contains(position), board[position].state.isRevealable else { return [] }
        if !minesPlaced {
            let mines = MinePlacer.minePositions(for: configuration, firstClick: position, seed: seed)
            board.placeMines(at: mines)
            minesPlaced = true
        }
        if status == .ready { status = .playing }
        return open([position])
    }

    /// Chording: sobre un número destapado con tantas banderas vecinas como su valor,
    /// destapa el resto de vecinas. Si alguna bandera es incorrecta, se pierde la partida.
    /// - Returns: las casillas destapadas por esta acción.
    @discardableResult
    public mutating func chord(at position: Position) -> Set<Position> {
        guard !status.isOver, board.contains(position) else { return [] }
        let cell = board[position]
        guard cell.state == .revealed, cell.adjacentMines > 0 else { return [] }
        let neighbors = board.neighbors(of: position)
        let flags = neighbors.count { board[$0].state == .flagged }
        guard flags == cell.adjacentMines else { return [] }
        return open(neighbors.filter { board[$0].state.isRevealable })
    }

    /// Cambia la marca de una casilla tapada: sin marca → bandera → «?» → sin marca.
    /// Si `allowsQuestionMarks` es `false`, alterna solo entre sin marca y bandera.
    /// - Returns: el nuevo estado, o `nil` si no se pudo marcar.
    @discardableResult
    public mutating func toggleMark(at position: Position) -> CellState? {
        guard !status.isOver, board.contains(position) else { return nil }
        let next: CellState
        switch board[position].state {
        case .hidden:
            next = .flagged
            flagCount += 1
        case .flagged:
            next = allowsQuestionMarks ? .questioned : .hidden
            flagCount -= 1
        case .questioned:
            next = .hidden
        case .revealed:
            return nil
        }
        board[position].state = next
        return next
    }

    // MARK: - Lógica interna

    /// Destapa las casillas dadas y propaga la cascada desde los ceros (sin recursión).
    private mutating func open(_ start: [Position]) -> Set<Position> {
        var opened = Set<Position>()
        var pending = start
        while let position = pending.popLast() {
            guard board[position].state.isRevealable else { continue }
            board[position].state = .revealed
            opened.insert(position)

            if board[position].isMine {
                lose(detonated: position)
                return opened
            }

            revealedCount += 1
            if board[position].adjacentMines == 0 {
                pending.append(contentsOf: board.neighbors(of: position).filter { board[$0].state.isRevealable })
            }
        }
        if revealedCount == configuration.safeCellCount {
            win()
        }
        return opened
    }

    /// Fin de partida por mina: se muestran todas las minas no marcadas.
    private mutating func lose(detonated: Position) {
        status = .lost(detonated: detonated)
        for position in board.minePositions where board[position].state != .flagged {
            board[position].state = .revealed
        }
    }

    /// Victoria: se marcan con bandera todas las minas restantes.
    private mutating func win() {
        status = .won
        for position in board.minePositions where board[position].state != .flagged {
            board[position].state = .flagged
        }
        flagCount = configuration.mines
    }
}
