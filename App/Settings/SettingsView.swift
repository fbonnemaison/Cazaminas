// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Ventana de Ajustes (⌘,).
struct SettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Form {
            Section("Juego") {
                Toggle("Marca de interrogación «?»", isOn: $settings.allowsQuestionMarks)
                Text("Con la marca activada, el clic derecho alterna entre bandera, «?» y sin marca.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Tableros sin adivinar", isOn: $settings.noGuessMode)
                Text("Cada tablero se puede resolver solo con lógica desde el primer clic. Se aplica a la siguiente partida y tiene sus propios récords.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Sonido y respuesta háptica") {
                Toggle("Efectos de sonido", isOn: $settings.soundEnabled)
                Toggle("Respuesta háptica", isOn: $settings.hapticsEnabled)
                Text("La respuesta háptica se nota en trackpads Force Touch con el dedo apoyado.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Apariencia") {
                Picker("Tema", selection: $settings.theme) {
                    ForEach(ThemeID.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                Picker("Estilo gráfico", selection: $settings.graphicsStyle) {
                    ForEach(GraphicsStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                ThemePreview(theme: settings.theme.theme, style: settings.graphicsStyle)
                LabeledContent("Tamaño de casilla") {
                    HStack {
                        Button {
                            settings.zoomOut()
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        .disabled(!settings.canZoomOut)
                        Text("\(Int(settings.cellSize)) pt")
                            .monospacedDigit()
                            .frame(minWidth: 44)
                        Button {
                            settings.zoomIn()
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .disabled(!settings.canZoomIn)
                    }
                    .buttonStyle(.borderless)
                }
                Text("El modo claro u oscuro sigue al del sistema.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Muestra de casillas con el tema elegido.
private struct ThemePreview: View {
    let theme: BoardTheme
    let style: GraphicsStyle

    private let samples: [CellAppearance] = [
        .covered, .flagged, .questioned, .empty, .number(1), .number(2),
        .number(3), .number(4), .mine, .detonatedMine, .wrongFlag,
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(samples.enumerated()), id: \.offset) { _, appearance in
                CellView(appearance: appearance, size: 28, theme: theme, style: style, animated: false)
            }
        }
        .padding(5)
        .background(theme.boardBackground, in: .rect(cornerRadius: style.isPixel ? 0 : 8, style: .continuous))
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
