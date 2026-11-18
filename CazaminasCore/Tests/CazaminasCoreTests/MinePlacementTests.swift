// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import CazaminasCore

@Suite("Generador y primer clic seguro")
struct MinePlacementTests {
    @Test("El generador con semilla es determinista")
    func seededGeneratorIsDeterministic() {
        var a = SeededRandomNumberGenerator(seed: 42)
        var b = SeededRandomNumberGenerator(seed: 42)
        var c = SeededRandomNumberGenerator(seed: 43)
        let sequenceA = (0..<10).map { _ in a.next() }
        let sequenceB = (0..<10).map { _ in b.next() }
        let sequenceC = (0..<10).map { _ in c.next() }
        #expect(sequenceA == sequenceB)
        #expect(sequenceA != sequenceC)
    }

    @Test("nextInt(below:) siempre queda dentro del rango")
    func boundedIntegers() {
        var generator = SeededRandomNumberGenerator(seed: 7)
        var seen = Set<Int>()
        for _ in 0..<1_000 {
            let value = generator.nextInt(below: 6)
            #expect((0..<6).contains(value))
            seen.insert(value)
        }
        #expect(seen.count == 6)
    }

    @Test(
        "El primer clic y sus vecinas nunca tienen mina",
        arguments: [(9, 9, 10), (16, 16, 40), (30, 16, 99)]
    )
    func firstClickOpensArea(width: Int, height: Int, mines: Int) throws {
        let configuration = try BoardConfiguration(width: width, height: height, mines: mines)
        var clicks = SeededRandomNumberGenerator(seed: 2026)
        for seed in UInt64(0)..<200 {
            let click = P(clicks.nextInt(below: height), clicks.nextInt(below: width))
            var game = Game(configuration: configuration, seed: seed)
            let opened = game.reveal(at: click)

            #expect(game.board.minePositions.count == mines)
            #expect(!game[click].isMine)
            #expect(game[click].adjacentMines == 0)
            #expect(game.board.neighbors(of: click).allSatisfy { !game[$0].isMine })
            #expect(opened.contains(click))
            #expect(opened.count > 1)
            #expect(game.status == .playing || game.status == .won)
        }
    }

    @Test("En tableros muy llenos solo se protege la casilla del primer clic")
    func denseBoardFallback() throws {
        // 4×4 con 10 minas: la zona segura de una casilla interior (9) no deja sitio a las minas.
        let configuration = try BoardConfiguration(width: 4, height: 4, mines: 10)
        for seed in UInt64(0)..<50 {
            var game = Game(configuration: configuration, seed: seed)
            game.reveal(at: P(1, 1))
            #expect(!game[P(1, 1)].isMine)
            #expect(game.board.minePositions.count == 10)
            #expect(game.status != .lost(detonated: P(1, 1)))
        }
    }

    @Test("Tablero con una sola casilla segura: el primer clic gana")
    func onlyOneSafeCell() throws {
        let configuration = try BoardConfiguration(width: 3, height: 3, mines: 8)
        var game = Game(configuration: configuration, seed: 1)
        game.reveal(at: P(1, 1))
        #expect(game.status == .won)
        #expect(game[P(1, 1)].adjacentMines == 8)
    }

    @Test("Misma semilla y mismo primer clic producen el mismo tablero")
    func sameSeedSameBoard() throws {
        let configuration = try BoardConfiguration(width: 16, height: 16, mines: 40)
        var a = Game(configuration: configuration, seed: 12345)
        var b = Game(configuration: configuration, seed: 12345)
        var c = Game(configuration: configuration, seed: 54321)
        a.reveal(at: P(8, 8))
        b.reveal(at: P(8, 8))
        c.reveal(at: P(8, 8))
        #expect(a.board.minePositions == b.board.minePositions)
        #expect(a.board.minePositions != c.board.minePositions)
    }
}
