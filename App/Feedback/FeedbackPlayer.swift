// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Algo que sabe reproducir efectos de sonido.
@MainActor
protocol SoundPlaying {
    func play(_ effect: SoundEffect)
}

/// Intensidad de la respuesta háptica.
enum HapticPattern: Hashable, Sendable {
    case light
    case strong
}

/// Algo que sabe producir respuesta háptica. Una implementación por plataforma.
@MainActor
protocol HapticPlaying {
    func perform(_ pattern: HapticPattern)
}

/// Traduce los eventos de la partida a sonido y háptica, según los ajustes.
@MainActor
final class FeedbackPlayer {
    private let settings: AppSettings
    private let sound: any SoundPlaying
    private let haptics: (any HapticPlaying)?

    init(settings: AppSettings, sound: any SoundPlaying, haptics: (any HapticPlaying)?) {
        self.settings = settings
        self.sound = sound
        self.haptics = haptics
    }

    func handle(_ event: GameEvent) {
        let (effect, haptic) = Self.feedback(for: event)
        if settings.soundEnabled, let effect {
            sound.play(effect)
        }
        if settings.hapticsEnabled, let haptic {
            haptics?.perform(haptic)
        }
    }

    static func feedback(for event: GameEvent) -> (SoundEffect?, HapticPattern?) {
        switch event {
        case .revealed(let count): (count > 1 ? .cascade : .reveal, nil)
        case .flagged: (.flag, .light)
        case .questioned, .unmarked: (.unflag, nil)
        case .lost: (.explosion, .strong)
        case .won: (.victory, .strong)
        }
    }
}
