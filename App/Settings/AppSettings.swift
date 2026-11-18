// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Foundation
import Observation

/// Preferencias del jugador, guardadas en UserDefaults (macOS e iOS).
@MainActor
@Observable
final class AppSettings {
    /// Tamaños de casilla disponibles para el zoom, en puntos.
    static let cellSizes: [Double] = [20, 24, 28, 32, 36, 40, 44]
    static let defaultCellSize: Double = 28

    enum Key {
        static let allowsQuestionMarks = "allowsQuestionMarks"
        static let soundEnabled = "soundEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let theme = "theme"
        static let cellSize = "cellSize"
    }

    /// Si el clic derecho pasa por «?» después de la bandera.
    var allowsQuestionMarks: Bool {
        didSet { defaults?.set(allowsQuestionMarks, forKey: Key.allowsQuestionMarks) }
    }

    var soundEnabled: Bool {
        didSet { defaults?.set(soundEnabled, forKey: Key.soundEnabled) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults?.set(hapticsEnabled, forKey: Key.hapticsEnabled) }
    }

    var theme: ThemeID {
        didSet { defaults?.set(theme.rawValue, forKey: Key.theme) }
    }

    /// Lado de una casilla en puntos (uno de `cellSizes`).
    private(set) var cellSize: Double {
        didSet { defaults?.set(cellSize, forKey: Key.cellSize) }
    }

    @ObservationIgnored private let defaults: UserDefaults?

    /// - Parameter defaults: dónde guardar; `nil` para ajustes solo en memoria (tests, vistas previas).
    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
        allowsQuestionMarks = defaults?.object(forKey: Key.allowsQuestionMarks) as? Bool ?? true
        soundEnabled = defaults?.object(forKey: Key.soundEnabled) as? Bool ?? true
        hapticsEnabled = defaults?.object(forKey: Key.hapticsEnabled) as? Bool ?? true
        theme = defaults?.string(forKey: Key.theme).flatMap(ThemeID.init(rawValue:)) ?? .relief
        let storedSize = defaults?.object(forKey: Key.cellSize) as? Double ?? Self.defaultCellSize
        cellSize = Self.cellSizes.contains(storedSize) ? storedSize : Self.defaultCellSize
    }

    // MARK: - Zoom

    var canZoomIn: Bool { cellSize < Self.cellSizes.last! }
    var canZoomOut: Bool { cellSize > Self.cellSizes.first! }

    func zoomIn() {
        if let next = Self.cellSizes.first(where: { $0 > cellSize }) { cellSize = next }
    }

    func zoomOut() {
        if let previous = Self.cellSizes.last(where: { $0 < cellSize }) { cellSize = previous }
    }

    func resetZoom() {
        cellSize = Self.defaultCellSize
    }
}
