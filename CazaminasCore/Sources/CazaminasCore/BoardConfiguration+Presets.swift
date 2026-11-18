// Cazaminas — © 2026 App-Zilla. Licencia MIT.

extension BoardConfiguration {
    // Los valores son literales válidos, así que el `try!` nunca falla.

    /// Principiante: 9×9, 10 minas.
    public static let beginner = try! BoardConfiguration(width: 9, height: 9, mines: 10)
    /// Intermedio: 16×16, 40 minas.
    public static let intermediate = try! BoardConfiguration(width: 16, height: 16, mines: 40)
    /// Experto: 30×16, 99 minas.
    public static let expert = try! BoardConfiguration(width: 30, height: 16, mines: 99)
}
