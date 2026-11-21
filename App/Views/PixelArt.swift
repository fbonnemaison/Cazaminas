// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Dibujo pixel art descrito como texto: cada carácter es un píxel y `.` es
/// transparente. Los caracteres son «papeles» (base, sombra, número…) y el color
/// de cada uno lo pone quien dibuja, así el mismo sprite sirve para todos los
/// temas y para el modo claro y oscuro.
struct PixelSprite: Equatable, Sendable {
    /// Todos los sprites de casilla miden 16 × 16 píxeles.
    static let side = 16

    let rows: [String]

    init(_ rows: [String]) {
        self.rows = rows
    }

    /// Centra un dibujo más pequeño en la rejilla de 16 × 16.
    static func centered(_ glyph: [String], dy: Int = 0) -> PixelSprite {
        let width = glyph.map(\.count).max() ?? 0
        let left = (side - width) / 2
        let top = (side - glyph.count) / 2 + dy
        let blank = String(repeating: ".", count: side)
        var rows = [String](repeating: blank, count: side)
        for (index, line) in glyph.enumerated() where (0..<side).contains(top + index) {
            let padded = line.padding(toLength: width, withPad: ".", startingAt: 0)
            rows[top + index] = String(repeating: ".", count: left) + padded
                + String(repeating: ".", count: side - left - width)
        }
        return PixelSprite(rows)
    }
}

/// Pinta un `PixelSprite` llenando el espacio disponible. Los bordes de cada
/// píxel se ajustan a los píxeles de la pantalla para que se vean nítidos.
struct PixelArtView: View {
    let sprite: PixelSprite
    let palette: [Character: Color]

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let scale = max(1, context.environment.displayScale)
            let columns = sprite.rows.map(\.count).max() ?? 1
            let lines = sprite.rows.count
            func edge(_ index: Int, count: Int, length: CGFloat) -> CGFloat {
                (CGFloat(index) * length / CGFloat(count) * scale).rounded() / scale
            }
            var paths: [Character: Path] = [:]
            for (y, row) in sprite.rows.enumerated() {
                let top = edge(y, count: lines, length: size.height)
                let bottom = edge(y + 1, count: lines, length: size.height)
                for (x, character) in row.enumerated() where character != "." {
                    let left = edge(x, count: columns, length: size.width)
                    let right = edge(x + 1, count: columns, length: size.width)
                    paths[character, default: Path()].addRect(
                        CGRect(x: left, y: top, width: right - left, height: bottom - top)
                    )
                }
            }
            // Orden estable: los papeles se pintan según la paleta.
            for (character, path) in paths.sorted(by: { $0.key < $1.key }) {
                if let color = palette[character] {
                    context.fill(path, with: .color(color))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Sprites de Cazaminas

/// Sprites propios de Cazaminas (dibujados por App-Zilla).
enum PixelSprites {
    /// Casilla tapada: `B` base, `H` luz arriba e izquierda, `S` sombra abajo y derecha.
    static let covered: PixelSprite = {
        let n = PixelSprite.side
        let rows = (0..<n).map { y in
            String((0..<n).map { x -> Character in
                let edge = 2
                let lit = (y < edge || x < edge) && x + y < n - 1
                let shaded = (y >= n - edge || x >= n - edge) && x + y >= n - 1
                return lit ? "H" : shaded ? "S" : "B"
            })
        }
        return PixelSprite(rows)
    }()

    /// Casilla destapada: `B` base y `G` línea de rejilla arriba e izquierda.
    static let revealed: PixelSprite = {
        let n = PixelSprite.side
        let rows = (0..<n).map { y in
            String((0..<n).map { x -> Character in (x == 0 || y == 0) ? "G" : "B" })
        }
        return PixelSprite(rows)
    }()

    /// Mina: `M` cuerpo y púas, `W` brillo.
    static let mine = PixelSprite([
        "................",
        ".......MM.......",
        "..M....MM....M..",
        "...M..MMMM..M...",
        "....MMMMMMMM....",
        "....MWWMMMMM....",
        "...MMWWMMMMMM...",
        ".MMMMMMMMMMMMMM.",
        ".MMMMMMMMMMMMMM.",
        "...MMMMMMMMMM...",
        "....MMMMMMMM....",
        "....MMMMMMMM....",
        "...M..MMMM..M...",
        "..M....MM....M..",
        ".......MM.......",
        "................",
    ])

    /// Bandera: `F` tela, `P` mástil y base.
    static let flag = PixelSprite.centered([
        "....FFPP",
        "..FFFFPP",
        "FFFFFFPP",
        "..FFFFPP",
        "....FFPP",
        "......PP",
        "......PP",
        "....PPPPPP",
        "..PPPPPPPPPP",
    ], dy: 1)

    /// Aspa de bandera equivocada: `X`.
    static let cross = PixelSprite.centered([
        "XX......XX",
        "XXX....XXX",
        ".XXX..XXX.",
        "..XXXXXX..",
        "...XXXX...",
        "...XXXX...",
        "..XXXXXX..",
        ".XXX..XXX.",
        "XXX....XXX",
        "XX......XX",
    ])

    /// Marca «?»: `Q`.
    static let question = PixelSprite.centered([
        ".####.",
        "##..##",
        "....##",
        "...##.",
        "..##..",
        "..##..",
        "......",
        "..##..",
    ].map { $0.replacingOccurrences(of: "#", with: "Q") })

    /// Números 1–8: `N`.
    static func number(_ value: Int) -> PixelSprite {
        digits[(value - 1).clamped(to: 0...7)]
    }

    private static let digits: [PixelSprite] = [
        ["..##..", ".###..", "####..", "..##..", "..##..", "..##..", "..##..", "######"],
        [".####.", "##..##", "....##", "...##.", "..##..", ".##...", "##....", "######"],
        [".####.", "##..##", "....##", "..###.", "....##", "....##", "##..##", ".####."],
        ["...###", "..####", ".##.##", "##..##", "######", "....##", "....##", "....##"],
        ["######", "##....", "#####.", "....##", "....##", "....##", "##..##", ".####."],
        [".####.", "##....", "##....", "#####.", "##..##", "##..##", "##..##", ".####."],
        ["######", "....##", "...##.", "...##.", "..##..", "..##..", "..##..", "..##.."],
        [".####.", "##..##", "##..##", ".####.", "##..##", "##..##", "##..##", ".####."],
    ].map { glyph in
        PixelSprite.centered(glyph.map { $0.replacingOccurrences(of: "#", with: "N") })
    }
}
