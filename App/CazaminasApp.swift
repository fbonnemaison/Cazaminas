// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import SwiftUI

enum WindowID {
    static let main = "main"
    static let statistics = "statistics"
}

@main
struct CazaminasApp: App {
    @State private var services = AppServices()

    var body: some Scene {
        // Una sola ventana de juego: ⌘N queda libre para «Nueva partida».
        Window("Cazaminas", id: WindowID.main) {
            GameView(model: services.model, settings: services.settings)
        }
        .windowResizability(.contentSize)
        .commands {
            GameCommands(model: services.model)
            ZoomCommands(settings: services.settings)
        }

        Window("Estadísticas", id: WindowID.statistics) {
            StatisticsView(model: services.model)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)

        #if os(macOS)
        Settings {
            SettingsView(settings: services.settings)
        }
        #endif
    }
}
