// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation

/// Efectos de sonido del juego.
enum SoundEffect: CaseIterable, Sendable {
    case reveal
    case cascade
    case flag
    case unflag
    case explosion
    case victory
}

/// Sintetiza los efectos de sonido a partir de ondas simples.
///
/// Todos los sonidos son originales y se generan al vuelo: no hay archivos de audio
/// en el proyecto ni dependencias de terceros.
enum SoundSynth {
    static let sampleRate = 44_100.0

    /// Muestras mono en [-1, 1] para un efecto.
    static func samples(for effect: SoundEffect) -> [Float] {
        let raw: [Double]
        switch effect {
        case .reveal:
            raw = tone(from: 900, to: 620, duration: 0.05, volume: 0.22, decay: 55)
        case .cascade:
            raw = tone(from: 520, to: 1250, duration: 0.14, volume: 0.2, decay: 20, harmonic: 0.25)
        case .flag:
            raw = tone(from: 1400, to: 1400, duration: 0.03, volume: 0.16, decay: 80)
                + tone(from: 1900, to: 1900, duration: 0.045, volume: 0.16, decay: 60)
        case .unflag:
            raw = tone(from: 1100, to: 850, duration: 0.045, volume: 0.13, decay: 70)
        case .explosion:
            raw = explosion()
        case .victory:
            let notes = [523.25, 659.25, 783.99]
            raw = notes.flatMap { tone(from: $0, to: $0, duration: 0.11, volume: 0.18, decay: 14, harmonic: 0.35) }
                + tone(from: 1046.5, to: 1046.5, duration: 0.5, volume: 0.2, decay: 5, harmonic: 0.35)
        }
        return raw.map { Float(max(-1, min(1, $0))) }
    }

    /// Tono con barrido de frecuencia, ataque corto y caída exponencial.
    static func tone(
        from startFrequency: Double,
        to endFrequency: Double,
        duration: Double,
        volume: Double,
        decay: Double,
        harmonic: Double = 0
    ) -> [Double] {
        let count = Int(duration * sampleRate)
        var phase = 0.0
        var output: [Double] = []
        output.reserveCapacity(count)
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let progress = time / duration
            let frequency = startFrequency + (endFrequency - startFrequency) * progress
            phase += 2 * .pi * frequency / sampleRate
            let wave = sin(phase) + harmonic * sin(2 * phase)
            output.append(wave * envelope(time: time, duration: duration, decay: decay) * volume)
        }
        return output
    }

    /// Ruido filtrado que se oscurece con el tiempo más un golpe grave.
    static func explosion() -> [Double] {
        let duration = 0.9
        let count = Int(duration * sampleRate)
        var generator = SeededRandomNumberGenerator(seed: 0xB00B5)
        var filtered = 0.0
        var output: [Double] = []
        output.reserveCapacity(count)
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let cutoff = 3_000 * exp(-3.2 * time) + 200
            let alpha = 1 - exp(-2 * .pi * cutoff / sampleRate)
            let noise = Double(generator.next()) / Double(UInt64.max) * 2 - 1
            filtered += alpha * (noise - filtered)
            let thump = sin(2 * .pi * 55 * time) * exp(-6 * time) * 0.9
            let sample = (filtered * 1.6 + thump) * envelope(time: time, duration: duration, decay: 4.5) * 0.5
            output.append(sample)
        }
        return output
    }

    /// Ataque de 3 ms, caída exponencial y desvanecido final de 5 ms (evita chasquidos).
    private static func envelope(time: Double, duration: Double, decay: Double) -> Double {
        let attack = min(1, time / 0.003)
        let release = min(1, (duration - time) / 0.005)
        return attack * max(0, release) * exp(-decay * time)
    }
}
