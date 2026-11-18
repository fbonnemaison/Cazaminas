// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// Estadísticas y mejores tiempos por dificultad.
struct StatisticsView: View {
    let model: GameViewModel

    @State private var category: StatsCategory = .beginner
    @State private var isConfirmingReset = false

    private var stats: CategoryStats { model.statistics[category] }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Dificultad", selection: $category) {
                ForEach(StatsCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            summary

            VStack(alignment: .leading, spacing: 8) {
                Text("Mejores tiempos")
                    .font(.headline)
                bestTimes
                    .frame(height: 230, alignment: .top)
            }

            HStack {
                Spacer()
                Button("Restablecer…", role: .destructive) { isConfirmingReset = true }
                    .disabled(model.statistics.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500)
        .onAppear { category = model.statsCategory }
        .confirmationDialog(
            "¿Restablecer las estadísticas?",
            isPresented: $isConfirmingReset
        ) {
            Button("Solo \(category.title)", role: .destructive) { model.resetStatistics(category) }
            Button("Todas las dificultades", role: .destructive) { model.resetStatistics() }
        } message: {
            Text("Se borrarán partidas, rachas y mejores tiempos. No se puede deshacer.")
        }
    }

    // MARK: - Resumen

    private var summary: some View {
        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
            GridRow {
                StatTile(title: "Jugadas", value: "\(stats.played)")
                StatTile(title: "Ganadas", value: "\(stats.won)")
                StatTile(
                    title: "Victorias",
                    value: stats.winRate.formatted(.percent.precision(.fractionLength(0)))
                )
            }
            GridRow {
                StatTile(title: "Racha actual", value: "\(stats.currentStreak)")
                StatTile(title: "Mejor racha", value: "\(stats.bestStreak)")
                StatTile(
                    title: "Mejor tiempo",
                    value: stats.bestTimes.first.map { formattedSeconds($0.seconds) } ?? "—"
                )
            }
        }
    }

    // MARK: - Tabla de tiempos

    @ViewBuilder
    private var bestTimes: some View {
        if !category.tracksBestTimes {
            Text("Los tableros personalizados no tienen tabla de tiempos porque cada uno puede tener medidas distintas.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } else if stats.bestTimes.isEmpty {
            Text("Aún no hay victorias en este nivel.")
                .foregroundStyle(.secondary)
        } else {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                ForEach(Array(stats.bestTimes.enumerated()), id: \.offset) { index, record in
                    GridRow {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .gridColumnAlignment(.trailing)
                        Text(formattedSeconds(record.seconds))
                            .fontWeight(index == 0 ? .bold : .regular)
                            .gridColumnAlignment(.trailing)
                        Text(record.date, format: .dateTime.day().month().year().hour().minute())
                            .foregroundStyle(.secondary)
                    }
                    .monospacedDigit()
                }
            }
        }
    }
}

/// Valor destacado con su título debajo.
private struct StatTile: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 100, alignment: .leading)
    }
}
