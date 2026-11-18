// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Jugada que se puede deducir sin adivinar.
public struct Hint: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        /// La casilla es segura: se puede destapar.
        case safe
        /// La casilla tiene mina: se puede marcar.
        case mine
    }

    public var position: Position
    public var kind: Kind

    public init(position: Position, kind: Kind) {
        self.position = position
        self.kind = kind
    }
}

/// Solucionador lógico: deduce casillas seguras y minas solo a partir de los números
/// visibles, como lo haría un jugador que nunca adivina.
///
/// Usa tres niveles de razonamiento, de más barato a más caro:
/// 1. Reglas simples de cada número (todas sus vecinas son minas / ninguna lo es).
/// 2. Restricciones contenidas en otras (si las vecinas de A están dentro de las de B,
///    la diferencia tiene `B − A` minas).
/// 3. Enumeración exhaustiva de cada grupo pequeño de casillas de frontera, más el
///    recuento global de minas.
public enum Solver {
    /// Si una partida se puede ganar desde `firstClick` sin adivinar nunca.
    public static func isSolvableWithoutGuessing(board: Board, firstClick: Position) -> Bool {
        var state = Knowledge(board: board)
        guard state.reveal(state.index(of: firstClick)) else { return false }
        while !state.isComplete {
            let deduction = state.deduce()
            if deduction.isEmpty { return false }
            state.knownMines.formUnion(deduction.mines)
            for index in deduction.safe {
                guard state.reveal(index) else { return false }
            }
        }
        return true
    }

    /// Siguiente jugada deducible en una partida en curso, o `nil` si toca adivinar.
    ///
    /// No se fía de las banderas del jugador (pueden estar mal): solo usa los números.
    /// Prefiere casillas seguras sin marcar; si no hay, minas sin bandera; y si solo
    /// queda eso, señala una bandera puesta en una casilla segura.
    public static func hint(for game: Game) -> Hint? {
        switch game.status {
        case .won, .lost:
            return nil
        case .ready:
            // El primer clic siempre es seguro: mejor en el centro, que abre más.
            let center = Position(row: game.configuration.height / 2, column: game.configuration.width / 2)
            return Hint(position: center, kind: .safe)
        case .playing:
            break
        }

        var state = Knowledge(visibleIn: game)
        var deducedMines = Set<Int>()
        var safe = Set<Int>()
        // Deduce hasta encontrar algo útil para el jugador.
        while true {
            let deduction = state.deduce()
            if deduction.isEmpty { break }
            safe.formUnion(deduction.safe)
            deducedMines.formUnion(deduction.mines)
            state.knownMines.formUnion(deduction.mines)
            // Las casillas seguras no se pueden destapar aquí (no conocemos su número):
            // se tratan como conocidas para no volver a deducirlas.
            state.assumedSafe.formUnion(deduction.safe)
            let positions = safe.map(state.position(of:))
            if positions.contains(where: { game[$0].state.isRevealable }) { break }
            if deducedMines.contains(where: { game[state.position(of: $0)].state != .flagged }) { break }
        }

        let positions = { (indices: Set<Int>) in indices.map(state.position(of:)).sorted { ($0.row, $0.column) < ($1.row, $1.column) } }
        if let cell = positions(safe).first(where: { game[$0].state.isRevealable }) {
            return Hint(position: cell, kind: .safe)
        }
        if let cell = positions(deducedMines).first(where: { game[$0].state != .flagged }) {
            return Hint(position: cell, kind: .mine)
        }
        if let cell = positions(safe).first(where: { game[$0].state == .flagged }) {
            return Hint(position: cell, kind: .safe)
        }
        return nil
    }
}

// MARK: - Conocimiento del jugador

/// Lo que un jugador sabe del tablero: números visibles y minas deducidas.
struct Knowledge {
    let width: Int
    let height: Int
    let totalMines: Int
    /// Número visible de cada casilla, o `nil` si está tapada.
    var numbers: [Int?]
    var knownMines: Set<Int> = []
    /// Casillas deducidas como seguras pero no destapadas (solo para pistas).
    var assumedSafe: Set<Int> = []
    /// Verdad del tablero, para poder destapar en la simulación.
    private let truth: Board?
    private let neighborTable: [[Int]]
    private var revealedSafe = 0

    init(board: Board) {
        width = board.width
        height = board.height
        totalMines = board.minePositions.count
        numbers = Array(repeating: nil, count: board.width * board.height)
        truth = board
        neighborTable = Self.neighbors(width: board.width, height: board.height)
    }

    init(visibleIn game: Game) {
        let board = game.board
        width = board.width
        height = board.height
        totalMines = game.configuration.mines
        numbers = board.cells.map { $0.state == .revealed && !$0.isMine ? $0.adjacentMines : nil }
        truth = nil
        neighborTable = Self.neighbors(width: board.width, height: board.height)
    }

    var isComplete: Bool { revealedSafe == width * height - totalMines }

    func index(of position: Position) -> Int { position.row * width + position.column }
    func position(of index: Int) -> Position { Position(row: index / width, column: index % width) }

    /// Destapa una casilla (y la cascada) usando la verdad del tablero. `false` si era mina.
    mutating func reveal(_ start: Int) -> Bool {
        guard let truth else { return false }
        var pending = [start]
        while let index = pending.popLast() {
            guard numbers[index] == nil else { continue }
            let cell = truth.cells[index]
            if cell.isMine { return false }
            numbers[index] = cell.adjacentMines
            revealedSafe += 1
            if cell.adjacentMines == 0 {
                pending.append(contentsOf: neighborTable[index].filter { numbers[$0] == nil })
            }
        }
        return true
    }

    private func isUnknown(_ index: Int) -> Bool {
        numbers[index] == nil && !knownMines.contains(index) && !assumedSafe.contains(index)
    }

    // MARK: Deducción

    struct Deduction {
        var safe: Set<Int> = []
        var mines: Set<Int> = []
        var isEmpty: Bool { safe.isEmpty && mines.isEmpty }
    }

    /// Una restricción: entre estas casillas desconocidas hay exactamente `mines` minas.
    struct Constraint: Hashable {
        var cells: [Int] // ordenadas
        var mines: Int
    }

    func constraints() -> [Constraint] {
        var result = Set<Constraint>()
        for index in numbers.indices {
            guard let number = numbers[index] else { continue }
            var unknown: [Int] = []
            var mines = number
            for neighbor in neighborTable[index] {
                if knownMines.contains(neighbor) {
                    mines -= 1
                } else if isUnknown(neighbor) {
                    unknown.append(neighbor)
                }
            }
            if !unknown.isEmpty {
                result.insert(Constraint(cells: unknown.sorted(), mines: mines))
            }
        }
        return Array(result)
    }

    func deduce() -> Deduction {
        let constraints = constraints()

        // 1. Reglas simples.
        var deduction = Deduction()
        for constraint in constraints {
            if constraint.mines == 0 {
                deduction.safe.formUnion(constraint.cells)
            } else if constraint.mines == constraint.cells.count {
                deduction.mines.formUnion(constraint.cells)
            }
        }
        if !deduction.isEmpty { return deduction }

        // 2. Restricciones contenidas en otras.
        var byCell: [Int: [Int]] = [:]
        for (offset, constraint) in constraints.enumerated() {
            for cell in constraint.cells { byCell[cell, default: []].append(offset) }
        }
        for (offset, small) in constraints.enumerated() {
            let smallSet = Set(small.cells)
            let candidates = Set(byCell[small.cells[0]] ?? [])
            for otherOffset in candidates where otherOffset != offset {
                let large = constraints[otherOffset]
                guard large.cells.count > small.cells.count, smallSet.isSubset(of: large.cells) else { continue }
                let difference = large.cells.filter { !smallSet.contains($0) }
                let mines = large.mines - small.mines
                if mines == 0 {
                    deduction.safe.formUnion(difference)
                } else if mines == difference.count {
                    deduction.mines.formUnion(difference)
                }
            }
        }
        if !deduction.isEmpty { return deduction }

        // 3. Enumeración por grupos de frontera + recuento global.
        return enumerate(constraints, byCell: byCell)
    }

    /// Máximo de casillas de un grupo que se enumeran por completo.
    static let enumerationLimit = 22
    /// Máximo de pasos de búsqueda por grupo (evita casos patológicos).
    static let searchBudget = 250_000

    private func enumerate(_ constraints: [Constraint], byCell: [Int: [Int]]) -> Deduction {
        var deduction = Deduction()
        let remainingMines = totalMines - knownMines.count
        let unknownCount = numbers.indices.count(where: isUnknown)

        // Recuento global trivial.
        if remainingMines == 0 {
            deduction.safe = Set(numbers.indices.filter(isUnknown))
            return deduction
        }
        if remainingMines == unknownCount {
            deduction.mines = Set(numbers.indices.filter(isUnknown))
            return deduction
        }

        // Grupos conectados de casillas de frontera.
        var visited = Set<Int>()
        var groups: [[Int]] = []
        for start in byCell.keys.sorted() where !visited.contains(start) {
            var group: [Int] = []
            var stack = [start]
            visited.insert(start)
            while let cell = stack.popLast() {
                group.append(cell)
                for offset in byCell[cell] ?? [] {
                    for other in constraints[offset].cells where !visited.contains(other) {
                        visited.insert(other)
                        stack.append(other)
                    }
                }
            }
            groups.append(group)
        }

        let frontier = visited
        let interiorCount = unknownCount - frontier.count
        var minMinesPerGroup: [Int] = []
        var maxMinesPerGroup: [Int] = []
        var groupResults: [(cells: [Int], counts: [Int], solutions: Int, mineTotals: Set<Int>)] = []

        for group in groups {
            guard group.count <= Self.enumerationLimit,
                  let result = solveGroup(group, constraints: constraints, byCell: byCell)
            else {
                minMinesPerGroup.append(0)
                maxMinesPerGroup.append(group.count)
                continue
            }
            minMinesPerGroup.append(result.mineTotals.min() ?? 0)
            maxMinesPerGroup.append(result.mineTotals.max() ?? group.count)
            groupResults.append((group, result.counts, result.solutions, result.mineTotals))
            for (cellOffset, cell) in group.enumerated() {
                if result.counts[cellOffset] == 0 {
                    deduction.safe.insert(cell)
                } else if result.counts[cellOffset] == result.solutions {
                    deduction.mines.insert(cell)
                }
            }
        }
        if !deduction.isEmpty { return deduction }

        // Recuento global: si la frontera ya usa todas las minas restantes (o deja
        // exactamente las que caben en el interior), el interior queda decidido.
        if interiorCount > 0 {
            let frontierMin = minMinesPerGroup.reduce(0, +)
            let frontierMax = maxMinesPerGroup.reduce(0, +)
            let interior = numbers.indices.filter { isUnknown($0) && !frontier.contains($0) }
            if frontierMin == remainingMines {
                deduction.safe.formUnion(interior)
            } else if remainingMines - frontierMax == interiorCount {
                deduction.mines.formUnion(interior)
            }
        }
        return deduction
    }

    /// Enumera todas las asignaciones válidas de un grupo. Devuelve, por casilla, en
    /// cuántas soluciones es mina; el total de soluciones; y los totales de minas posibles.
    private func solveGroup(
        _ group: [Int],
        constraints: [Constraint],
        byCell: [Int: [Int]]
    ) -> (counts: [Int], solutions: Int, mineTotals: Set<Int>)? {
        let position = Dictionary(uniqueKeysWithValues: group.enumerated().map { ($1, $0) })
        let involved = Set(group.flatMap { byCell[$0] ?? [] }).sorted()
        // Restricciones locales en índices del grupo.
        let local = involved.map { offset in
            (cells: constraints[offset].cells.map { position[$0]! }, mines: constraints[offset].mines)
        }
        var constraintsOfCell = Array(repeating: [Int](), count: group.count)
        for (constraintOffset, constraint) in local.enumerated() {
            for cell in constraint.cells { constraintsOfCell[cell].append(constraintOffset) }
        }

        var assigned = Array(repeating: 0, count: local.count)   // minas ya asignadas
        var open = local.map(\.cells.count)                       // casillas sin asignar
        var assignment = Array(repeating: false, count: group.count)
        var counts = Array(repeating: 0, count: group.count)
        var solutions = 0
        var mineTotals = Set<Int>()
        var steps = 0
        var exhausted = false

        func search(_ cell: Int, _ mines: Int) {
            steps += 1
            if steps > Self.searchBudget { exhausted = true; return }
            if cell == group.count {
                solutions += 1
                mineTotals.insert(mines)
                for index in assignment.indices where assignment[index] { counts[index] += 1 }
                return
            }
            for isMine in [false, true] {
                var valid = true
                for constraintOffset in constraintsOfCell[cell] {
                    let newAssigned = assigned[constraintOffset] + (isMine ? 1 : 0)
                    let newOpen = open[constraintOffset] - 1
                    let target = local[constraintOffset].mines
                    if newAssigned > target || newAssigned + newOpen < target { valid = false; break }
                }
                guard valid else { continue }
                for constraintOffset in constraintsOfCell[cell] {
                    assigned[constraintOffset] += isMine ? 1 : 0
                    open[constraintOffset] -= 1
                }
                assignment[cell] = isMine
                search(cell + 1, mines + (isMine ? 1 : 0))
                for constraintOffset in constraintsOfCell[cell] {
                    assigned[constraintOffset] -= isMine ? 1 : 0
                    open[constraintOffset] += 1
                }
                if exhausted { return }
            }
        }
        search(0, 0)
        return exhausted || solutions == 0 ? nil : (counts, solutions, mineTotals)
    }

    static func neighbors(width: Int, height: Int) -> [[Int]] {
        (0..<(width * height)).map { index in
            let row = index / width, column = index % width
            var result: [Int] = []
            for dr in -1...1 {
                for dc in -1...1 where dr != 0 || dc != 0 {
                    let r = row + dr, c = column + dc
                    if r >= 0, r < height, c >= 0, c < width { result.append(r * width + c) }
                }
            }
            return result
        }
    }
}
