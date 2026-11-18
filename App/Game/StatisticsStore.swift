// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation
import OSLog

/// Guarda las estadísticas en un archivo JSON dentro de Application Support.
///
/// JSON + FileManager funciona igual en macOS e iOS y el archivo es legible a mano.
struct StatisticsStore {
    let fileURL: URL

    private static let logger = Logger(subsystem: "com.app-zilla.Cazaminas", category: "Statistics")

    /// `~/Library/Application Support/Cazaminas/statistics.json` (dentro del contenedor de la sandbox).
    static var standard: StatisticsStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return StatisticsStore(fileURL: base.appending(path: "Cazaminas/statistics.json"))
    }

    /// Las estadísticas guardadas. Si no hay archivo o está dañado, empieza de cero.
    func load() -> Statistics {
        guard let data = try? Data(contentsOf: fileURL) else { return Statistics() }
        do {
            return try JSONDecoder.statistics.decode(Statistics.self, from: data)
        } catch {
            Self.logger.error("Estadísticas dañadas, se empieza de cero: \(error.localizedDescription)")
            return Statistics()
        }
    }

    func save(_ statistics: Statistics) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder.statistics.encode(statistics)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Self.logger.error("No se pudieron guardar las estadísticas: \(error.localizedDescription)")
        }
    }
}

private extension JSONEncoder {
    static var statistics: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var statistics: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
