// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Generador pseudoaleatorio determinista (SplitMix64).
///
/// La misma semilla produce siempre la misma secuencia, en cualquier plataforma.
/// Permite tests reproducibles y, en el futuro, compartir o repetir tableros.
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Entero uniforme en `0..<upperBound`, sin sesgo (muestreo por rechazo).
    ///
    /// Implementado aquí, y no con `Int.random(in:using:)`, para que el resultado
    /// no dependa de detalles internos de la biblioteca estándar.
    public mutating func nextInt(below upperBound: Int) -> Int {
        precondition(upperBound > 0)
        let bound = UInt64(upperBound)
        let limit = UInt64.max - (UInt64.max % bound)
        var value: UInt64
        repeat { value = next() } while value >= limit
        return Int(value % bound)
    }
}
