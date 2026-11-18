// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Elige dónde van las minas, respetando el primer clic seguro.
enum MinePlacer {
    /// Devuelve `configuration.mines` posiciones distintas, todas fuera de la zona segura.
    ///
    /// La zona segura es la casilla del primer clic y sus vecinas, de modo que el primer
    /// clic siempre destapa un 0 y abre un área. Si el tablero está tan lleno que no caben
    /// las minas fuera de esa zona, solo se protege la casilla del primer clic.
    static func minePositions(
        for configuration: BoardConfiguration,
        firstClick: Position,
        seed: UInt64
    ) -> [Position] {
        let board = Board(width: configuration.width, height: configuration.height)
        var safeZone = Set(board.neighbors(of: firstClick))
        safeZone.insert(firstClick)
        if configuration.cellCount - safeZone.count < configuration.mines {
            safeZone = [firstClick]
        }

        var candidates = board.positions.filter { !safeZone.contains($0) }

        // Fisher–Yates parcial: solo hace falta barajar las primeras `mines` posiciones.
        var generator = SeededRandomNumberGenerator(seed: seed)
        for i in 0..<configuration.mines {
            let j = i + generator.nextInt(below: candidates.count - i)
            candidates.swapAt(i, j)
        }
        return Array(candidates.prefix(configuration.mines))
    }
}
