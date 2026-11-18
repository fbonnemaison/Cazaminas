// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Dimensiones y número de minas de un tablero.
///
/// Siempre es válida: el inicializador rechaza combinaciones imposibles.
public struct BoardConfiguration: Hashable, Sendable, Codable {
    public enum ValidationError: Error, Hashable, Sendable {
        /// Ancho o alto menor que 1.
        case invalidDimensions
        /// Menos de 1 mina, o tantas que no quede ni una casilla segura.
        case invalidMineCount
    }

    public let width: Int
    public let height: Int
    public let mines: Int

    public init(width: Int, height: Int, mines: Int) throws(ValidationError) {
        guard width >= 1, height >= 1 else { throw .invalidDimensions }
        guard mines >= 1, mines < width * height else { throw .invalidMineCount }
        self.width = width
        self.height = height
        self.mines = mines
    }

    /// Número total de casillas.
    public var cellCount: Int { width * height }

    /// Número de casillas sin mina.
    public var safeCellCount: Int { cellCount - mines }

    // Decodificación validada: un archivo corrupto no puede producir una configuración imposible.
    private enum CodingKeys: String, CodingKey { case width, height, mines }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            width: container.decode(Int.self, forKey: .width),
            height: container.decode(Int.self, forKey: .height),
            mines: container.decode(Int.self, forKey: .mines)
        )
    }
}
