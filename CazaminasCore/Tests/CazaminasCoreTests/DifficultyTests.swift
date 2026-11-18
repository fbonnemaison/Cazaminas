// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Foundation
import Testing
@testable import CazaminasCore

@Suite("Dificultades")
struct DifficultyTests {
    @Test("Los niveles clásicos tienen las medidas de siempre")
    func presets() throws {
        let beginner = try BoardConfiguration(width: 9, height: 9, mines: 10)
        let intermediate = try BoardConfiguration(width: 16, height: 16, mines: 40)
        let expert = try BoardConfiguration(width: 30, height: 16, mines: 99)
        #expect(Difficulty.beginner.configuration == beginner)
        #expect(Difficulty.intermediate.configuration == intermediate)
        #expect(Difficulty.expert.configuration == expert)
        #expect(Difficulty.presets == [.beginner, .intermediate, .expert])
    }

    @Test("Una configuración se reconoce como nivel clásico o personalizado")
    func matching() throws {
        #expect(Difficulty(matching: .expert) == .expert)
        let custom = try BoardConfiguration(width: 20, height: 10, mines: 30)
        #expect(Difficulty(matching: custom) == .custom(custom))
        #expect(Difficulty(matching: custom).isCustom)
        #expect(!Difficulty.beginner.isCustom)
    }

    @Test("Los límites personalizados se respetan")
    func customLimits() throws {
        _ = try CustomBoardLimits.configuration(width: 5, height: 5, mines: 16)
        _ = try CustomBoardLimits.configuration(width: 40, height: 24, mines: 951)
        #expect(throws: BoardConfiguration.ValidationError.invalidDimensions) {
            try CustomBoardLimits.configuration(width: 4, height: 10, mines: 5)
        }
        #expect(throws: BoardConfiguration.ValidationError.invalidDimensions) {
            try CustomBoardLimits.configuration(width: 10, height: 25, mines: 5)
        }
        #expect(throws: BoardConfiguration.ValidationError.invalidMineCount) {
            try CustomBoardLimits.configuration(width: 5, height: 5, mines: 17)
        }
    }

    @Test("Ajustar a los límites corrige valores fuera de rango")
    func clamping() {
        let configuration = CustomBoardLimits.clamped(width: 100, height: 1, mines: 9_999)
        #expect(configuration.width == 40)
        #expect(configuration.height == 5)
        #expect(configuration.mines == 191)
        #expect(CustomBoardLimits.clamped(width: 9, height: 9, mines: 0).mines == 1)
    }

    @Test("La dificultad se codifica y decodifica", arguments: [
        Difficulty.beginner, .intermediate, .expert, .custom(try! BoardConfiguration(width: 12, height: 8, mines: 20)),
    ])
    func codable(difficulty: Difficulty) throws {
        let data = try JSONEncoder().encode(difficulty)
        #expect(try JSONDecoder().decode(Difficulty.self, from: data) == difficulty)
    }
}
