// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// Pantalla principal: cabecera, tablero y línea de estado.
struct GameView: View {
    @Bindable var model: GameViewModel
    let settings: AppSettings

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

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
        // Pausa automática al cambiar de app o minimizar.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.pause() }
        }
        #if os(macOS)
        .modifier(PauseOnDeactivate(model: model))
        #endif
        // Avisos para VoiceOver.
        .onChange(of: model.winCount) {
            AccessibilityNotification.Announcement(String(localized: "¡Tablero despejado!")).post()
        }
        .onChange(of: model.lossCount) {
            AccessibilityNotification.Announcement(String(localized: "¡Boom! Has pisado una mina.")).post()
        }
        .animation(.snappy(duration: 0.2), value: model.mood)
        #if os(macOS)
        .navigationSubtitle(subtitle)
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
                if model.isGenerating {
                    Label("Generando tablero sin adivinar…", systemImage: "wand.and.stars")
                        .foregroundStyle(.secondary)
                } else if model.hintUnavailable {
                    Label("No hay jugada segura: toca arriesgarse.", systemImage: "questionmark.diamond")
                        .foregroundStyle(.orange)
                } else if model.noGuessFallback {
                    Label("Tablero demasiado denso: puede tocar adivinar.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else {
                    Text("Clic: destapar · Clic derecho: bandera")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.callout.weight(.medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(height: 20)
    }

    private var subtitle: String {
        model.mode == .noGuess ? "\(model.difficulty.title) · \(GameMode.noGuess.title)" : model.difficulty.title
    }

    /// Tiempo de la victoria y, si entra en la tabla, su puesto.
    @ViewBuilder
    private var winMessage: some View {
        let seconds = formattedSeconds(model.lastWin?.seconds ?? 0)
        switch model.lastWin?.rank {
        case 1:
            Label("¡Nuevo récord: \(seconds)!", systemImage: "trophy.fill")
                .foregroundStyle(.orange)
        case _ where model.usedHint:
            Label("¡Despejado en \(seconds)! (con pistas)", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
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
