// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// Sacudida horizontal: cada incremento de `animatableData` en 1 produce tres vaivenes.
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 6) * 7
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// Lluvia de confeti al ganar. Se dispara cada vez que cambia `trigger`.
struct ConfettiView: View {
    let trigger: Int

    @State private var start: Date?
    private static let duration: TimeInterval = 2.6
    private static let palette: [Color] = [
        Color(red: 0.24, green: 0.39, blue: 1.0),
        Color(red: 0.42, green: 0.17, blue: 0.94),
        Color(red: 0.30, green: 0.85, blue: 0.98),
        Color(red: 1.0, green: 0.78, blue: 0.2),
        Color(red: 1.0, green: 0.4, blue: 0.55),
    ]

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { context in
            Canvas { canvas, size in
                guard let start else { return }
                draw(in: &canvas, size: size, time: context.date.timeIntervalSince(start))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: trigger) {
            guard trigger > 0 else { return }
            start = .now
            try? await Task.sleep(for: .seconds(Self.duration))
            start = nil
        }
    }

    private func draw(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        guard time < Self.duration else { return }
        var random = SeededRandomNumberGenerator(seed: UInt64(trigger) &* 7_919)
        func value(_ range: ClosedRange<Double>) -> Double {
            range.lowerBound + Double(random.next() % 10_000) / 10_000 * (range.upperBound - range.lowerBound)
        }

        let gravity = 900.0
        let fade = min(1, (Self.duration - time) / 0.6)
        for index in 0..<110 {
            // Salen hacia arriba desde la parte baja del tablero y caen.
            let x0 = value(0.1...0.9) * size.width
            let y0 = size.height * value(0.55...0.8)
            let vx = value(-160...160)
            let vy = -value(420...820)
            let spin = value(-9...9)
            let x = x0 + vx * time
            let y = y0 + vy * time + 0.5 * gravity * time * time
            guard y < size.height + 20 else { continue }

            var piece = canvas
            piece.opacity = fade
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(spin * time))
            let rect = CGRect(x: -3, y: -5, width: 6, height: 10)
            piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(Self.palette[index % Self.palette.count]))
        }
    }
}
