// Cazaminas — © 2026 App-Zilla. Licencia MIT.

#if os(macOS)
import AppKit

/// Respuesta háptica en trackpads Force Touch. Solo se nota con el dedo sobre el trackpad;
/// con ratón no hace nada.
@MainActor
struct TrackpadHaptics: HapticPlaying {
    func perform(_ pattern: HapticPattern) {
        let feedback: NSHapticFeedbackManager.FeedbackPattern = switch pattern {
        case .light: .alignment
        case .strong: .levelChange
        }
        NSHapticFeedbackManager.defaultPerformer.perform(feedback, performanceTime: .now)
    }
}
#endif
