// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// Menú «Juego» de la barra de menús. En iOS no se usa.
struct GameCommands: Commands {
    let model: GameViewModel

    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // Una sola ventana: no tiene sentido «Nueva ventana».
        CommandGroup(replacing: .newItem) {}

        CommandMenu("Juego") {
            Button("Nueva partida") { model.newGame() }
                .keyboardShortcut("n", modifiers: .command)

            Divider()

            ForEach(Array(Difficulty.presets.enumerated()), id: \.offset) { index, difficulty in
                Toggle(isOn: selectionBinding(for: difficulty)) {
                    Text(difficulty.title)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }

            Toggle(isOn: Binding(
                get: { model.difficulty.isCustom },
                set: { _ in model.isCustomBoardSheetPresented = true }
            )) {
                Text("Personalizado…")
            }
            .keyboardShortcut("4", modifiers: .command)

            Divider()

            Button("Estadísticas…") { openWindow(id: WindowID.statistics) }
                .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }

    /// Marca el nivel actual; elegir uno ya marcado empieza otra partida igualmente.
    private func selectionBinding(for difficulty: Difficulty) -> Binding<Bool> {
        Binding(
            get: { model.difficulty == difficulty },
            set: { _ in model.select(difficulty) }
        )
    }
}
