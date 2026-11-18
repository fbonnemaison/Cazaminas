// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Nivel de dificultad: uno de los tres clásicos o un tablero a medida.
public enum Difficulty: Hashable, Sendable, Codable {
    case beginner
    case intermediate
    case expert
    case custom(BoardConfiguration)

    /// Los tres niveles clásicos, en orden.
    public static let presets: [Difficulty] = [.beginner, .intermediate, .expert]

    /// Configuración del tablero para este nivel.
    public var configuration: BoardConfiguration {
        switch self {
        case .beginner: .beginner
        case .intermediate: .intermediate
        case .expert: .expert
        case .custom(let configuration): configuration
        }
    }

    /// El nivel clásico que corresponde a una configuración, o `.custom` si no coincide con ninguno.
    public init(matching configuration: BoardConfiguration) {
        self = Self.presets.first { $0.configuration == configuration } ?? .custom(configuration)
    }

    public var isCustom: Bool {
        if case .custom = self { true } else { false }
    }
}

/// Límites del tablero personalizado.
///
/// Las minas dejan siempre libres al menos 9 casillas, para que el primer clic
/// pueda abrir un área (la casilla y sus 8 vecinas).
public enum CustomBoardLimits {
    public static let width: ClosedRange<Int> = 5...40
    public static let height: ClosedRange<Int> = 5...24

    /// Rango de minas permitido para unas dimensiones.
    public static func mines(width: Int, height: Int) -> ClosedRange<Int> {
        1...max(1, width * height - 9)
    }

    /// Configuración personalizada válida, o error si se sale de los límites.
    public static func configuration(
        width: Int,
        height: Int,
        mines: Int
    ) throws(BoardConfiguration.ValidationError) -> BoardConfiguration {
        guard self.width.contains(width), self.height.contains(height) else { throw .invalidDimensions }
        guard self.mines(width: width, height: height).contains(mines) else { throw .invalidMineCount }
        return try BoardConfiguration(width: width, height: height, mines: mines)
    }

    /// Ajusta unos valores cualesquiera a los límites (para la interfaz).
    public static func clamped(width: Int, height: Int, mines: Int) -> BoardConfiguration {
        let width = width.clamped(to: self.width)
        let height = height.clamped(to: self.height)
        let mines = mines.clamped(to: self.mines(width: width, height: height))
        // Valores ya ajustados a los límites: siempre válidos.
        return try! BoardConfiguration(width: width, height: height, mines: mines)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
