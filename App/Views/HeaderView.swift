// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Barra superior: minas restantes, botón de nueva partida y cronómetro.
struct HeaderView: View {
    let model: GameViewModel

    var body: some View {
        HStack {
            CounterView(systemImage: "flag.fill", value: model.remainingMines)
                .help("Minas restantes")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Minas restantes: \(model.remainingMines)"))
            Spacer(minLength: 12)
            Button {
                model.newGame()
            } label: {
                Image(systemName: symbol(for: model.mood))
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tint(for: model.mood))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: model.winCount)
                    .frame(width: 36, height: 30)
            }
            .buttonStyle(.bordered)
            .help("Nueva partida (⌘N)")
            .accessibilityLabel("Nueva partida")
            Spacer(minLength: 12)
            timer
                .help("Tiempo")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Tiempo: \(model.elapsedSeconds(at: .now)) segundos"))
        }
    }

    @ViewBuilder
    private var timer: some View {
        if model.isTimerRunning {
            TimelineView(.periodic(from: model.startDate ?? .now, by: 1)) { context in
                CounterView(systemImage: "timer", value: model.elapsedSeconds(at: context.date))
            }
        } else {
            CounterView(systemImage: "timer", value: model.elapsedSeconds(at: .now))
        }
    }

    private func symbol(for mood: Mood) -> String {
        switch mood {
        case .calm: "face.smiling"
        case .tense: "eyes"
        case .won: "trophy.fill"
        case .lost: "xmark.octagon.fill"
        }
    }

    private func tint(for mood: Mood) -> Color {
        switch mood {
        case .calm, .tense: .primary
        case .won: .orange
        case .lost: .red
        }
    }
}

/// Contador de tres cifras con icono (minas o segundos).
struct CounterView: View {
    let systemImage: String
    let value: Int

    var body: some View {
        Label {
            Text(formatted)
                .font(.system(size: 18, weight: .semibold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(value: Double(value)))
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.quaternary, in: .capsule)
    }

    /// Tres cifras con ceros a la izquierda; los negativos se muestran como «-01».
    private var formatted: String {
        let clamped = max(-99, min(999, value))
        if clamped < 0 {
            return "-" + String(format: "%02d", -clamped)
        }
        return String(format: "%03d", clamped)
    }
}
