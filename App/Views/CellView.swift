// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// Una casilla del tablero. Solo depende de sus propiedades (todas comparables),
/// así SwiftUI no la vuelve a dibujar si no cambian.
struct CellView: View, Equatable {
    let appearance: CellAppearance
    let size: CGFloat
    let theme: BoardTheme
    /// HD (vectorial) o pixel art.
    var style: GraphicsStyle = .hd
    /// Si se anima el cambio de estado (desactivado con «Reducir movimiento»).
    var animated: Bool = true
    /// Retraso de la animación, para la onda de la cascada.
    var delay: Double = 0
    /// Pista sobre esta casilla: segura (verde) o mina (naranja).
    var hint: Hint.Kind? = nil
    /// Si el cursor del teclado está sobre esta casilla.
    var isCursor: Bool = false

    var body: some View {
        ZStack {
            if style.isPixel {
                pixelBackground
                pixelContent
            } else {
                background
                content
            }
            if let hint {
                HintMarker(kind: hint, size: size, animated: animated, square: style.isPixel)
            }
            if isCursor {
                RoundedRectangle(cornerRadius: style.isPixel ? 0 : size * 0.18, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: max(2, size * 0.09))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size, height: size)
        .animation(animated ? .spring(duration: 0.28, bounce: 0.35).delay(delay) : nil, value: appearance)
    }

    // MARK: - Fondo

    private var isCovered: Bool {
        switch appearance {
        case .covered, .flagged, .questioned: true
        default: false
        }
    }

    @ViewBuilder
    private var background: some View {
        if isCovered {
            coveredBackground
        } else {
            revealedBackground(appearance == .detonatedMine ? theme.detonated : theme.cellRevealed)
        }
    }

    @ViewBuilder
    private var coveredBackground: some View {
        switch theme.style {
        case .raised:
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .fill(LinearGradient(
                    colors: [theme.cellCovered, theme.cellCoveredShade],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .shadow(color: .black.opacity(0.18), radius: 0.5, y: 0.8)
                .padding(1)
        case .flat:
            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .fill(theme.cellCovered)
                .padding(size * 0.05)
        case .outlined:
            Rectangle()
                .fill(theme.cellCovered)
                .overlay(Rectangle().strokeBorder(theme.cellGrid, lineWidth: 1.5))
        }
    }

    @ViewBuilder
    private func revealedBackground(_ fill: Color) -> some View {
        switch theme.style {
        case .raised:
            Rectangle()
                .fill(fill)
                .overlay(Rectangle().strokeBorder(theme.cellGrid, lineWidth: 0.5))
        case .flat:
            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .fill(fill)
                .padding(size * 0.05)
        case .outlined:
            Rectangle()
                .fill(fill)
                .overlay(Rectangle().strokeBorder(theme.cellGrid, lineWidth: 1))
        }
    }

    // MARK: - Pixel art

    @ViewBuilder
    private var pixelBackground: some View {
        if isCovered {
            PixelArtView(sprite: PixelSprites.covered, palette: [
                "B": theme.cellCovered,
                "H": .white.opacity(0.55),
                "S": .black.opacity(0.32),
            ])
            .background(theme.cellCovered)
        } else {
            let fill = appearance == .detonatedMine ? theme.detonated : theme.cellRevealed
            PixelArtView(sprite: PixelSprites.revealed, palette: [
                "B": fill,
                "G": theme.boardBackground,
            ])
        }
    }

    @ViewBuilder
    private var pixelContent: some View {
        switch appearance {
        case .covered, .pressed, .empty:
            EmptyView()
        case .number(let number):
            PixelArtView(sprite: PixelSprites.number(number), palette: ["N": theme.numberColor(number)])
                .transition(.opacity)
        case .flagged:
            PixelArtView(sprite: PixelSprites.flag, palette: ["F": theme.flag, "P": theme.mine])
                .transition(.move(edge: .bottom).combined(with: .opacity))
        case .questioned:
            PixelArtView(sprite: PixelSprites.question, palette: ["Q": .secondary])
                .transition(.opacity)
        case .mine, .detonatedMine:
            PixelArtView(sprite: PixelSprites.mine, palette: ["M": theme.mine, "W": .white])
                .transition(.opacity)
        case .wrongFlag:
            ZStack {
                PixelArtView(sprite: PixelSprites.mine, palette: ["M": theme.mine, "W": .white])
                    .opacity(0.35)
                PixelArtView(sprite: PixelSprites.cross, palette: ["X": theme.flag])
            }
            .transition(.opacity)
        }
    }

    // MARK: - Contenido

    @ViewBuilder
    private var content: some View {
        switch appearance {
        case .covered, .pressed, .empty:
            EmptyView()
        case .number(let number):
            Text("\(number)")
                .font(.system(size: size * 0.6, weight: theme.numberWeight, design: .rounded))
                .foregroundStyle(theme.numberColor(number))
                .transition(.scale(scale: 0.4).combined(with: .opacity))
        case .flagged:
            Image(systemName: "flag.fill")
                .font(.system(size: size * 0.5))
                .foregroundStyle(theme.flag)
                .transition(.scale(scale: 0.3, anchor: .bottom).combined(with: .opacity))
        case .questioned:
            Text("?")
                .font(.system(size: size * 0.58, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .transition(.opacity)
        case .mine:
            MineSymbol(color: theme.mine)
                .padding(size * 0.16)
                .transition(.scale(scale: 0.2).combined(with: .opacity))
        case .detonatedMine:
            MineSymbol(color: theme.mine)
                .padding(size * 0.16)
                .transition(.scale(scale: 2.2).combined(with: .opacity))
        case .wrongFlag:
            ZStack {
                MineSymbol(color: theme.mine)
                    .padding(size * 0.16)
                    .opacity(0.35)
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundStyle(theme.flag)
            }
            .transition(.opacity)
        }
    }
}

/// Marco que parpadea suavemente sobre la casilla de la pista.
private struct HintMarker: View {
    let kind: Hint.Kind
    let size: CGFloat
    let animated: Bool
    /// Esquinas rectas (pixel art).
    var square = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: square ? 0 : size * 0.2, style: .continuous)
        let color: Color = kind == .safe ? .green : .orange
        let style = StrokeStyle(lineWidth: max(2, size * 0.1), dash: kind == .mine ? [size * 0.18, size * 0.1] : [])
        Group {
            if animated {
                shape.strokeBorder(color, style: style)
                    .phaseAnimator([1.0, 0.35]) { view, opacity in
                        view.opacity(opacity)
                    } animation: { _ in .easeInOut(duration: 0.6) }
            } else {
                shape.strokeBorder(color, style: style)
            }
        }
        .padding(1)
        .allowsHitTesting(false)
    }
}

#Preview {
    let samples: [CellAppearance] = [
        .covered, .pressed, .flagged, .questioned, .empty,
        .number(1), .number(2), .number(3), .number(4),
        .number(5), .number(6), .number(7), .number(8),
        .mine, .detonatedMine, .wrongFlag,
    ]
    VStack(spacing: 8) {
        ForEach(GraphicsStyle.allCases) { style in
            ForEach(ThemeID.allCases) { id in
                HStack(spacing: 0) {
                    ForEach(Array(samples.enumerated()), id: \.offset) { _, appearance in
                        CellView(appearance: appearance, size: 28, theme: id.theme, style: style)
                    }
                }
                .padding(4)
                .background(id.theme.boardBackground)
            }
        }
    }
    .padding()
}
