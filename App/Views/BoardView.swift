// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// La cuadrícula de casillas más la capa de entrada de la plataforma.
struct BoardView: View {
    let model: GameViewModel
    let theme: BoardTheme
    let cellSize: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let configuration = model.configuration
        VStack(spacing: 0) {
            ForEach(0..<configuration.height, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<configuration.width, id: \.self) { column in
                        let position = Position(row: row, column: column)
                        CellView(
                            appearance: model.appearance(at: position),
                            size: cellSize,
                            theme: theme,
                            animated: !reduceMotion,
                            delay: reduceMotion ? 0 : model.revealDelay(at: position)
                        )
                        .equatable()
                    }
                }
            }
        }
        // Rangos distintos = cuadrícula nueva. Sin esto, al pasar a un tablero más
        // pequeño SwiftUI reevalúa casillas de columnas que ya no existen.
        .id(configuration)
        .overlay { input(for: configuration) }
        .padding(6)
        .background(theme.boardBackground, in: .rect(cornerRadius: 10, style: .continuous))
        // Sacudida al perder.
        .modifier(ShakeEffect(animatableData: reduceMotion ? 0 : CGFloat(model.lossCount)))
        .animation(reduceMotion ? nil : .linear(duration: 0.45), value: model.lossCount)
    }

    @ViewBuilder
    private func input(for configuration: BoardConfiguration) -> some View {
        let actions = BoardInputActions(
            press: { model.press(at: $0) },
            primary: { model.primaryAction(at: $0) },
            mark: { model.toggleMark(at: $0) },
            chord: { model.chord(at: $0) }
        )
        #if os(macOS)
        BoardMouseInput(
            columns: configuration.width,
            rows: configuration.height,
            cellSize: cellSize,
            actions: actions
        )
        #endif
    }
}
