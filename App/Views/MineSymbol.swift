// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import SwiftUI

/// Dibujo de una mina: esfera con púas y un brillo.
struct MineSymbol: View {
    var color: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .frame(width: side * 0.09, height: side * 0.9)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
                Circle()
                    .fill(color)
                    .frame(width: side * 0.62, height: side * 0.62)
                Circle()
                    .fill(.white.opacity(0.85))
                    .frame(width: side * 0.16, height: side * 0.16)
                    .offset(x: -side * 0.11, y: -side * 0.11)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    MineSymbol(color: .primary).frame(width: 60, height: 60).padding()
}
