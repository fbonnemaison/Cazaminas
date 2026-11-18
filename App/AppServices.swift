// Cazaminas — © 2026 App-Zilla. Licencia MIT.

/// Objetos compartidos de la app, creados una sola vez al arrancar.
@MainActor
final class AppServices {
    let settings: AppSettings
    let model: GameViewModel
    let feedback: FeedbackPlayer

    init() {
        settings = AppSettings(defaults: .standard)
        model = GameViewModel(settings: settings)

        #if os(macOS)
        let haptics: (any HapticPlaying)? = TrackpadHaptics()
        #else
        let haptics: (any HapticPlaying)? = nil // Fase 9: UIFeedbackGenerator
        #endif
        feedback = FeedbackPlayer(settings: settings, sound: SynthSoundService(), haptics: haptics)
        model.onEvent = { [feedback] event in feedback.handle(event) }
    }
}
