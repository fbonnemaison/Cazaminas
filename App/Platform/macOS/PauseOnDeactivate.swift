// Cazaminas — © 2026 App-Zilla. Licencia MIT.
//
// En macOS, `scenePhase` no cambia al pasar a otra app, así que se escuchan las
// notificaciones de AppKit. En iOS basta con `scenePhase` (ver GameView).

#if os(macOS)
import AppKit
import SwiftUI

/// Pausa la partida al cambiar de app o minimizar la ventana.
struct PauseOnDeactivate: ViewModifier {
    let model: GameViewModel

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                model.pause()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMiniaturizeNotification)) { _ in
                model.pause()
            }
    }
}
#endif
