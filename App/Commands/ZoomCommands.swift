// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Zoom del tablero en el menú «Visualización».
struct ZoomCommands: Commands {
    let settings: AppSettings

    var body: some Commands {
        CommandGroup(before: .toolbar) {
            Button("Ampliar tablero") { settings.zoomIn() }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(!settings.canZoomIn)
            Button("Reducir tablero") { settings.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(!settings.canZoomOut)
            Button("Tamaño normal") { settings.resetZoom() }
                .keyboardShortcut("0", modifiers: .command)
            Divider()
        }
    }
}
