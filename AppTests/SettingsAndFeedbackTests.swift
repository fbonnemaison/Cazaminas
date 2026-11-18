// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import CazaminasCore
import Foundation
import Testing
@testable import Cazaminas

/// Sonido falso que apunta lo que se reproduce.
@MainActor
final class RecordingSound: SoundPlaying {
    var played: [SoundEffect] = []
    func play(_ effect: SoundEffect) { played.append(effect) }
}

/// Háptica falsa que apunta lo que se produce.
@MainActor
final class RecordingHaptics: HapticPlaying {
    var performed: [HapticPattern] = []
    func perform(_ pattern: HapticPattern) { performed.append(pattern) }
}

@MainActor
@Suite("Ajustes")
struct SettingsTests {
    private func makeDefaults() -> (UserDefaults, cleanup: () -> Void) {
        let suite = "CazaminasTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (defaults, { defaults.removePersistentDomain(forName: suite) })
    }

    @Test("Valores por defecto")
    func defaults() {
        let settings = AppSettings()
        #expect(settings.allowsQuestionMarks)
        #expect(settings.soundEnabled)
        #expect(settings.hapticsEnabled)
        #expect(settings.theme == .relief)
        #expect(settings.cellSize == 28)
    }

    @Test("Los ajustes se guardan y se recuperan")
    func persistence() {
        let (defaults, cleanup) = makeDefaults()
        defer { cleanup() }
        let settings = AppSettings(defaults: defaults)
        settings.allowsQuestionMarks = false
        settings.soundEnabled = false
        settings.theme = .highContrast
        settings.zoomIn()

        let reopened = AppSettings(defaults: defaults)
        #expect(!reopened.allowsQuestionMarks)
        #expect(!reopened.soundEnabled)
        #expect(reopened.hapticsEnabled)
        #expect(reopened.theme == .highContrast)
        #expect(reopened.cellSize == 32)
    }

    @Test("Valores guardados inválidos vuelven al valor por defecto")
    func invalidStoredValues() {
        let (defaults, cleanup) = makeDefaults()
        defer { cleanup() }
        defaults.set("neón", forKey: AppSettings.Key.theme)
        defaults.set(31.0, forKey: AppSettings.Key.cellSize)
        let settings = AppSettings(defaults: defaults)
        #expect(settings.theme == .relief)
        #expect(settings.cellSize == 28)
    }

    @Test("El zoom se mueve por los tamaños permitidos y se detiene en los extremos")
    func zoom() {
        let settings = AppSettings()
        for _ in 0..<10 { settings.zoomIn() }
        #expect(settings.cellSize == AppSettings.cellSizes.last)
        #expect(!settings.canZoomIn)
        for _ in 0..<10 { settings.zoomOut() }
        #expect(settings.cellSize == AppSettings.cellSizes.first)
        #expect(!settings.canZoomOut)
        settings.resetZoom()
        #expect(settings.cellSize == AppSettings.defaultCellSize)
    }

    @Test("Desactivar «?» se aplica a la partida en curso")
    func questionMarksSetting() throws {
        let settings = AppSettings()
        let model = GameViewModel(settings: settings, store: nil, statisticsStore: nil)
        let position = Position(row: 0, column: 0)
        settings.allowsQuestionMarks = false
        model.toggleMark(at: position)
        model.toggleMark(at: position)
        #expect(model.appearance(at: position) == .covered)
    }

    @Test("Cada tema tiene ocho colores de número")
    func themes() {
        for id in ThemeID.allCases {
            #expect(id.theme.numbers.count == 8)
            #expect(id.theme.id == id)
        }
    }
}

@MainActor
@Suite("Eventos, sonido y háptica")
struct FeedbackTests {
    private func P(_ row: Int, _ column: Int) -> Position { Position(row: row, column: column) }

    /// 3×3 con una mina en la esquina.
    private func makeModel() throws -> (GameViewModel, events: () -> [GameEvent]) {
        let configuration = try BoardConfiguration(width: 3, height: 3, mines: 1)
        let model = GameViewModel(game: Game(configuration: configuration, minePositions: [P(0, 0)]))
        var events: [GameEvent] = []
        model.onEvent = { events.append($0) }
        return (model, { events })
    }

    @Test("La partida emite eventos de destapar, marcar y ganar")
    func events() throws {
        let (model, events) = try makeModel()
        model.primaryAction(at: P(1, 1))
        model.toggleMark(at: P(0, 0))
        model.toggleMark(at: P(0, 0))
        model.toggleMark(at: P(0, 0))
        model.toggleMark(at: P(0, 0))
        model.primaryAction(at: P(1, 1)) // chording: gana
        #expect(events() == [.revealed(count: 1), .flagged, .questioned, .unmarked, .flagged, .won])
        #expect(model.winCount == 1)
    }

    @Test("Perder emite un evento y la onda sale de la mina detonada")
    func lossEvent() throws {
        let (model, events) = try makeModel()
        model.primaryAction(at: P(2, 2))
        #expect(model.status == .won) // la cascada lo abre todo
        let (other, otherEvents) = try makeModel()
        other.primaryAction(at: P(0, 0))
        #expect(otherEvents() == [.lost])
        #expect(other.lossCount == 1)
        #expect(other.revealOrigin == P(0, 0))
        #expect(events() == [.won])
    }

    @Test("Una acción sin efecto no emite nada")
    func noEventWhenNothingHappens() throws {
        let (model, events) = try makeModel()
        model.primaryAction(at: P(1, 1))
        model.primaryAction(at: P(1, 1)) // chording sin banderas
        #expect(events() == [.revealed(count: 1)])
    }

    @Test("La onda de la cascada se retrasa con la distancia")
    func revealDelay() throws {
        let configuration = try BoardConfiguration(width: 9, height: 9, mines: 1)
        let model = GameViewModel(game: Game(configuration: configuration, minePositions: [P(8, 8)]))
        model.primaryAction(at: P(0, 0))
        #expect(model.revealDelay(at: P(0, 0)) == 0)
        #expect(model.revealDelay(at: P(0, 3)) > model.revealDelay(at: P(0, 1)))
        #expect(model.revealDelay(at: P(8, 8)) == 0) // la mina no se destapó
        model.newGame()
        #expect(model.revealDelay(at: P(0, 3)) == 0)
    }

    @Test("Cada evento suena y vibra según los ajustes")
    func feedbackPlayerRespectsSettings() {
        let settings = AppSettings()
        let sound = RecordingSound()
        let haptics = RecordingHaptics()
        let player = FeedbackPlayer(settings: settings, sound: sound, haptics: haptics)

        player.handle(.revealed(count: 1))
        player.handle(.revealed(count: 12))
        player.handle(.flagged)
        player.handle(.lost)
        #expect(sound.played == [.reveal, .cascade, .flag, .explosion])
        #expect(haptics.performed == [.light, .strong])

        settings.soundEnabled = false
        settings.hapticsEnabled = false
        player.handle(.won)
        #expect(sound.played.count == 4)
        #expect(haptics.performed.count == 2)
    }

    @Test("Todos los sonidos se sintetizan sin saturar", arguments: SoundEffect.allCases)
    func synthesizedSounds(effect: SoundEffect) {
        let samples = SoundSynth.samples(for: effect)
        #expect(!samples.isEmpty)
        #expect(samples.count < Int(SoundSynth.sampleRate)) // menos de 1 s
        #expect(samples.allSatisfy { abs($0) <= 1 })
        #expect(samples.contains { abs($0) > 0.01 }) // no es silencio
        #expect(abs(samples.last!) < 0.01) // termina sin chasquido
    }
}
