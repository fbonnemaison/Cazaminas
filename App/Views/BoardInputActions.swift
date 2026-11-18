// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore

/// Acciones que la capa de entrada de cada plataforma envía al juego.
/// El clic derecho en Mac y la pulsación larga en iOS acaban en la misma acción.
struct BoardInputActions {
    /// Pulsación en curso sobre una casilla (`nil` al salir del tablero o soltar).
    var press: @MainActor (Position?) -> Void
    /// Destapar o hacer chording.
    var primary: @MainActor (Position) -> Void
    /// Bandera / «?».
    var mark: @MainActor (Position) -> Void
    /// Chording explícito.
    var chord: @MainActor (Position) -> Void
}
