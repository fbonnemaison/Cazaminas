// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import AVFoundation
import OSLog

/// Reproduce los efectos sintetizados con AVAudioEngine (macOS e iOS).
@MainActor
final class SynthSoundService: SoundPlaying {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.sampleRate, channels: 1)!
    /// Varios reproductores para que los sonidos rápidos se solapen sin cortarse.
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private static let logger = Logger(subsystem: "com.app-zilla.Cazaminas", category: "Sound")

    init() {
        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
    }

    func play(_ effect: SoundEffect) {
        guard startEngineIfNeeded(), let buffer = buffer(for: effect) else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// El motor se arranca al primer sonido y se rearranca si el sistema lo detuvo
    /// (por ejemplo, al cambiar de salida de audio).
    private func startEngineIfNeeded() -> Bool {
        if engine.isRunning { return true }
        do {
            try engine.start()
            return true
        } catch {
            Self.logger.error("No se pudo iniciar el audio: \(error.localizedDescription)")
            return false
        }
    }

    private func buffer(for effect: SoundEffect) -> AVAudioPCMBuffer? {
        if let cached = buffers[effect] { return cached }
        let samples = SoundSynth.samples(for: effect)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            channel.update(from: source.baseAddress!, count: samples.count)
        }
        buffers[effect] = buffer
        return buffer
    }
}
