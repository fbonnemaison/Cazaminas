// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Algo que acaba de pasar en la partida y merece sonido, háptica o animación.
enum GameEvent: Hashable, Sendable {
    /// Se destaparon casillas (1 = una sola, más = cascada o chording).
    case revealed(count: Int)
    case flagged
    case questioned
    case unmarked
    case lost
    case won
}
