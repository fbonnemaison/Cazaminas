// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import SwiftUI

/// Vista provisional hasta que exista el tablero (Fase 2).
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Cazaminas")
                .font(.largeTitle.bold())
            Text("Motor v\(CazaminasCore.version)")
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(minWidth: 320, minHeight: 240)
    }
}

#Preview {
    ContentView()
}
