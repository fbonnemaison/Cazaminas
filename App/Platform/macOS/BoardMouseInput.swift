// Cazaminas — © 2026 App-Zilla. Licencia MIT.
//
// Entrada de ratón específica de macOS. SwiftUI no distingue el clic derecho ni el
// central, así que una NSView transparente sobre el tablero recibe los clics y los
// traduce a acciones abstractas. En iOS habrá otra capa (toque / pulsación larga)
// que llame a las mismas acciones.

#if os(macOS)
import AppKit
import CazaminasCore
import SwiftUI

/// Capa transparente que convierte los clics del ratón en acciones del tablero.
///
/// - Clic izquierdo: destapar (al soltar, como el clásico) o chording sobre un número.
/// - Clic derecho o Control-clic: bandera / «?».
/// - Clic central: chording.
struct BoardMouseInput: NSViewRepresentable {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    let actions: BoardInputActions

    func makeNSView(context: Context) -> MouseCaptureView {
        MouseCaptureView()
    }

    func updateNSView(_ view: MouseCaptureView, context: Context) {
        view.columns = columns
        view.rows = rows
        view.cellSize = cellSize
        view.actions = actions
    }

    final class MouseCaptureView: NSView {
        var columns = 0
        var rows = 0
        var cellSize: CGFloat = 1
        var actions: BoardInputActions?

        /// El clic izquierdo actual empezó con Control: se trata como clic secundario.
        private var leftClickIsMark = false

        override var isFlipped: Bool { true }

        /// Invisible para VoiceOver: las casillas SwiftUI ya son accesibles.
        override func isAccessibilityElement() -> Bool { false }

        /// Responder al primer clic aunque la ventana no esté activa.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        private func position(for event: NSEvent) -> Position? {
            let point = convert(event.locationInWindow, from: nil)
            guard point.x >= 0, point.y >= 0 else { return nil }
            let position = Position(row: Int(point.y / cellSize), column: Int(point.x / cellSize))
            guard position.row < rows, position.column < columns else { return nil }
            return position
        }

        override func mouseDown(with event: NSEvent) {
            if event.modifierFlags.contains(.control) {
                leftClickIsMark = true
                if let position = position(for: event) { actions?.mark(position) }
                return
            }
            leftClickIsMark = false
            actions?.press(position(for: event))
        }

        override func mouseDragged(with event: NSEvent) {
            guard !leftClickIsMark else { return }
            actions?.press(position(for: event))
        }

        override func mouseUp(with event: NSEvent) {
            guard !leftClickIsMark else {
                leftClickIsMark = false
                return
            }
            actions?.press(nil)
            if let position = position(for: event) { actions?.primary(position) }
        }

        override func rightMouseDown(with event: NSEvent) {
            if let position = position(for: event) { actions?.mark(position) }
        }

        override func otherMouseUp(with event: NSEvent) {
            if let position = position(for: event) { actions?.chord(position) }
        }
    }
}
#endif
