// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import Testing
@testable import CazaminasCore

@Suite("CazaminasCore")
struct CazaminasCoreTests {
    @Test("El motor expone una versión")
    func version() {
        #expect(!CazaminasCore.version.isEmpty)
    }
}
