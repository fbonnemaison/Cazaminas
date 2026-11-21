// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import Cazaminas

@Suite("Pixel art")
struct PixelArtTests {
    private var allSprites: [PixelSprite] {
        [PixelSprites.covered, PixelSprites.revealed, PixelSprites.mine, PixelSprites.flag,
         PixelSprites.cross, PixelSprites.question] + (1...8).map(PixelSprites.number)
    }

    @Test("Todos los sprites miden 16 × 16")
    func spriteSize() {
        for sprite in allSprites {
            #expect(sprite.rows.count == PixelSprite.side)
            #expect(sprite.rows.allSatisfy { $0.count == PixelSprite.side })
        }
    }

    @Test("Cada número tiene un dibujo distinto")
    func distinctDigits() {
        let digits = (1...8).map(PixelSprites.number)
        #expect(Set(digits.map(\.rows)).count == 8)
    }

    @Test("La casilla tapada tiene luz, base y sombra")
    func coveredBevel() {
        let pixels = PixelSprites.covered.rows.joined()
        #expect(pixels.contains("H") && pixels.contains("B") && pixels.contains("S"))
        #expect(PixelSprites.covered.rows.first?.first == "H")
        #expect(PixelSprites.covered.rows.last?.last == "S")
    }
}
