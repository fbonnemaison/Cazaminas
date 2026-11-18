// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// La cuadrícula de casillas más la capa de entrada de la plataforma.
///
/// Teclado: flechas para mover el cursor, Espacio para destapar, F para marcar
/// e Intro para hacer chording.
struct BoardView: View {
    let model: GameViewModel
    let theme: BoardTheme
    let cellSize: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool

    var body: some View {
        let configuration = model.configuration
        VStack(spacing: 0) {
            ForEach(0..<configuration.height, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<configuration.width, id: \.self) { column in
                        cell(at: Position(row: row, column: column))
                    }
                }
            }
        }
        // Rangos distintos = cuadrícula nueva. Sin esto, al pasar a un tablero más
        // pequeño SwiftUI reevalúa casillas de columnas que ya no existen.
        .id(configuration)
        .overlay { input(for: configuration) }
        .overlay { if model.isPaused { pauseCover } }
        .padding(6)
        .background(theme.boardBackground, in: .rect(cornerRadius: 10, style: .continuous))
        // Sacudida al perder.
        .modifier(ShakeEffect(animatableData: reduceMotion ? 0 : CGFloat(model.lossCount)))
        .animation(reduceMotion ? nil : .linear(duration: 0.45), value: model.lossCount)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Tablero de \(configuration.width) por \(configuration.height)"))
        // Teclado.
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onKeyPress(phases: .down, action: handleKey)
        .onAppear { isFocused = true }
    }

    private func cell(at position: Position) -> some View {
        CellView(
            appearance: model.appearance(at: position),
            size: cellSize,
            theme: theme,
            animated: !reduceMotion,
            delay: reduceMotion ? 0 : model.revealDelay(at: position),
            hint: model.hintKind(at: position),
            isCursor: model.showsCursor && model.cursor == position
        )
        .equatable()
        .accessibilityElement()
        .accessibilityLabel(model.accessibilityLabel(at: position))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { model.primaryAction(at: position) }
        .accessibilityAction(named: Text("Marcar")) { model.toggleMark(at: position) }
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        // Los atajos con ⌘/⌃/⌥ son del menú.
        guard press.modifiers.isDisjoint(with: [.command, .control, .option]) else { return .ignored }
        switch press.key {
        case .upArrow: model.moveCursor(rows: -1, columns: 0)
        case .downArrow: model.moveCursor(rows: 1, columns: 0)
        case .leftArrow: model.moveCursor(rows: 0, columns: -1)
        case .rightArrow: model.moveCursor(rows: 0, columns: 1)
        case .space: model.keyboardPrimary()
        case .return: model.keyboardChord()
        default:
            guard press.characters.lowercased() == "f" else { return .ignored }
            model.keyboardMark()
        }
        return .handled
    }

    /// Tapa del tablero en pausa: oculta las casillas para que no se pueda pensar con ventaja.
    private var pauseCover: some View {
        Button {
            model.resume()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 40))
                Text("En pausa")
                    .font(.title3.bold())
                Text("Haz clic o pulsa ⌘P para continuar")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.boardBackground)
            .padding(-3) // tapa también las sombras de las casillas de los bordes
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
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
        .accessibilityHidden(true)
        #endif
    }
}
