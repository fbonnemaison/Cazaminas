// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Pantalla principal: cabecera, tablero y línea de estado.
struct GameView: View {
    @Bindable var model: GameViewModel
    let settings: AppSettings

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            HeaderView(model: model)
            BoardView(model: model, theme: settings.theme.theme, cellSize: settings.cellSize)
            statusLine
        }
        .padding(16)
        .overlay {
            if !reduceMotion {
                ConfettiView(trigger: model.winCount)
            }
        }
        .fixedSize()
        .animation(.snappy(duration: 0.2), value: settings.cellSize)
        .animation(.snappy(duration: 0.2), value: model.mood)
        #if os(macOS)
        .navigationSubtitle(model.difficulty.title)
        #endif
        .sheet(isPresented: $model.isCustomBoardSheetPresented) {
            CustomBoardSheet(initial: model.configuration) { configuration in
                model.select(.custom(configuration))
            }
        }
    }

    /// Mensaje de victoria/derrota, o recordatorio de controles.
    @ViewBuilder
    private var statusLine: some View {
        Group {
            switch model.status {
            case .won:
                winMessage
            case .lost:
                Label("¡Boom! Has pisado una mina.", systemImage: "burst.fill")
                    .foregroundStyle(.red)
            case .ready, .playing:
                Text("Clic: destapar · Clic derecho: bandera")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout.weight(.medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(height: 20)
    }

    /// Tiempo de la victoria y, si entra en la tabla, su puesto.
    @ViewBuilder
    private var winMessage: some View {
        let seconds = formattedSeconds(model.lastWin?.seconds ?? 0)
        switch model.lastWin?.rank {
        case 1:
            Label("¡Nuevo récord: \(seconds)!", systemImage: "trophy.fill")
                .foregroundStyle(.orange)
        case let rank?:
            Label("¡Despejado en \(seconds)! (n.º \(rank))", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case nil:
            Label("¡Despejado en \(seconds)!", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    GameView(model: GameViewModel(store: nil, statisticsStore: nil), settings: AppSettings())
}
