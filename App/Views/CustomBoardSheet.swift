// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// Hoja para elegir ancho, alto y número de minas de un tablero personalizado.
struct CustomBoardSheet: View {
    let onPlay: (BoardConfiguration) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var width: Int
    @State private var height: Int
    @State private var mines: Int

    init(initial: BoardConfiguration, onPlay: @escaping (BoardConfiguration) -> Void) {
        let start = CustomBoardLimits.clamped(width: initial.width, height: initial.height, mines: initial.mines)
        _width = State(initialValue: start.width)
        _height = State(initialValue: start.height)
        _mines = State(initialValue: start.mines)
        self.onPlay = onPlay
    }

    private var mineRange: ClosedRange<Int> {
        CustomBoardLimits.mines(width: width, height: height)
    }

    private var density: Double {
        Double(mines) / Double(width * height)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tablero personalizado")
                .font(.title3.bold())

            Form {
                NumberRow(title: "Ancho", value: $width, range: CustomBoardLimits.width)
                NumberRow(title: "Alto", value: $height, range: CustomBoardLimits.height)
                NumberRow(title: "Minas", value: $mines, range: mineRange)
            }
            .formStyle(.columns)

            Text("Densidad: \(density, format: .percent.precision(.fractionLength(0)))")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancelar", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Jugar") {
                    onPlay(CustomBoardLimits.clamped(width: width, height: height, mines: mines))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
        .onChange(of: width) { mines = mines.clamped(to: mineRange) }
        .onChange(of: height) { mines = mines.clamped(to: mineRange) }
    }
}

/// Campo numérico con stepper, limitado a un rango.
private struct NumberRow: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                TextField(title, value: clampedValue, format: .number)
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                Stepper(title, value: $value, in: range)
                    .labelsHidden()
                Text("\(range.lowerBound)–\(range.upperBound)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// Lo que se escribe a mano también se ajusta al rango.
    private var clampedValue: Binding<Int> {
        Binding(
            get: { value },
            set: { value = $0.clamped(to: range) }
        )
    }
}

#Preview {
    CustomBoardSheet(initial: .intermediate) { _ in }
}
