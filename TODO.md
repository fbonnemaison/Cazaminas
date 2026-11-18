# Cazaminas — Plan de desarrollo

Juego de lógica para un jugador inspirado en el clásico de buscar minas: despejar una cuadrícula de casillas ocultas sin detonar ninguna mina.

- **Plataforma:** macOS (app nativa en SwiftUI).
- **Lenguaje:** Swift 6 (concurrencia estricta).
- **Autor:** App-Zilla.
- **Licencia:** MIT.
- **Distribución:** gratuita, firma ad hoc, sin notarización ni App Store (releases en GitHub).
- **Uso:** personal y de código abierto.

---

## Decisiones de diseño

- [x] Versión mínima: **macOS 15 Sequoia** (permite `@Observable` y SwiftUI moderno).
- [x] **Preparado para iOS/iPadOS en el futuro** (ver «Reglas de portabilidad» y Fase 9).
- [x] Estructura: paquete Swift `CazaminasCore` (lógica pura, sin UI, 100 % testeable) + target de app `Cazaminas` (SwiftUI).
- [ ] Identidad visual propia (iconos, colores y sonidos originales; nada copiado del juego de Windows).
- [x] Nombre del bundle: `com.app-zilla.Cazaminas`.

### Reglas de portabilidad (desde el primer día)

Para que añadir iOS más adelante sea añadir un destino y no reescribir la app:

- `CazaminasCore` declara `platforms: [.macOS(.v15), .iOS(.v18)]` y solo importa `Foundation` (nada de AppKit/UIKit).
- Las vistas usan SwiftUI puro; AppKit solo dentro de `#if os(macOS)` y en archivos aislados.
- Interacción a través de acciones abstractas (`reveal`, `toggleFlag`, `chord`): el clic derecho en Mac y la pulsación larga en iOS llaman a las mismas acciones.
- Háptica y sonido detrás de protocolos (`HapticsService`, `SoundService`) con una implementación por plataforma.
- Persistencia (récords/ajustes) con API multiplataforma (SwiftData o JSON + `FileManager`), sin rutas exclusivas de macOS.
- El tamaño del tablero y de las casillas se adapta al espacio disponible (sin medidas fijas de ventana).
- Menús y atajos de teclado en `Commands`, que en iOS simplemente no se usan.

---

## Fase 0 — Preparación del proyecto

- [x] `git init`, `.gitignore` para Xcode/SwiftPM.
- [x] `LICENSE` (MIT, © App-Zilla).
- [x] `README.md` inicial: descripción, requisitos, cómo compilar.
- [x] Proyecto de Xcode con target macOS SwiftUI + paquete local `CazaminasCore` (generado con XcodeGen desde `project.yml`).
- [x] Firma ad hoc (`CODE_SIGN_IDENTITY = "-"`), sin equipo de desarrollo.
- [x] `NSHumanReadableCopyright` = «© 2026 App-Zilla».
- [x] Target de tests (Swift Testing) para el núcleo.

## Fase 1 — Motor del juego (`CazaminasCore`)

- [x] Modelo `Cell`: mina, número de vecinas minadas, estado (oculta / revelada / bandera / interrogación).
- [x] Modelo `Board`: ancho, alto, número de minas, acceso por coordenadas, vecinos (8 direcciones).
- [x] Generador de minas con semilla reproducible (SplitMix64 propio + Fisher–Yates), estable entre versiones de Swift.
- [x] **Primer clic seguro:** las minas se colocan tras el primer clic, excluyendo esa casilla y sus vecinas (para abrir un área amplia).
- [x] Cálculo de números (1–8) por casilla.
- [x] Revelado en cascada (flood fill iterativo, sin recursión) para casillas con 0.
- [x] Ciclo de marcado: oculta → bandera → «?» → oculta (el «?» configurable).
- [x] **Chording:** acción sobre un número revelado cuyo nº de banderas vecinas coincide → revela el resto de vecinas.
- [x] Estados de partida: `ready`, `playing`, `won`, `lost(detonated:)`. Al ganar, las minas se marcan solas con bandera.
- [x] **Victoria:** todas las casillas seguras reveladas (las banderas no son necesarias).
- [x] **Derrota:** revelar una mina; mostrar todas las minas y señalar banderas incorrectas.
- [x] Contador de minas restantes (minas − banderas).
- [x] Tests unitarios de todo lo anterior (35 tests: primer clic, cascada, chording, victoria, derrota, persistencia).

## Fase 2 — Interfaz básica (SwiftUI)

- [x] `GameViewModel` (`@Observable`) que conecta el motor con la UI (con tests en `AppTests`).
- [x] Vista del tablero (filas de `CellView` equatable; valorar `Canvas` si Experto va lento).
- [x] Vista de casilla: estados oculta, revelada, número coloreado, bandera, «?», mina, mina detonada, bandera errónea.
- [x] Interacción: clic izquierdo = revelar (al soltar); clic derecho y Control-clic = marcar; clic sobre número o clic central = chording.
- [x] Barra superior: contador de minas, botón de reinicio con estado (⌘N), cronómetro.
- [x] Cronómetro que arranca con el primer clic y se detiene al terminar (máx. 999).
- [x] Ventana única que se ajusta al tamaño del tablero.
- [x] Mensajes de victoria/derrota.

## Fase 3 — Dificultades y tablero personalizado

- [x] Principiante: 9×9, 10 minas.
- [x] Intermedio: 16×16, 40 minas.
- [x] Experto: 30×16, 99 minas.
- [x] Personalizado: ancho 5–40, alto 5–24, minas hasta casillas − 9 (validado en `CustomBoardLimits`).
- [x] Menú «Juego» en la barra de menús con atajos (⌘N nueva partida, ⌘1/⌘2/⌘3 dificultades, ⌘4 personalizado).
- [x] Recordar la última dificultad usada (UserDefaults).
- [x] Subtítulo de la ventana con la dificultad actual.

## Fase 4 — Récords y estadísticas

- [x] Persistencia local en JSON (Application Support/Cazaminas/statistics.json), portable a iOS.
- [x] Mejor tiempo por dificultad (top 10 con fecha, décimas de segundo). Los tableros personalizados no tienen tabla.
- [x] Estadísticas: partidas jugadas, ganadas, % de victorias, racha actual y máxima.
- [x] Una partida empezada y abandonada (nueva partida o cambio de nivel) cuenta como derrota.
- [x] Ventana de estadísticas (⌘⇧S) con restablecimiento por nivel o total, con confirmación.
- [x] Aviso de nuevo récord (o puesto en la tabla) al ganar.

## Fase 5 — Ajustes, sonido, háptica y temas

- [x] Ventana de Ajustes (`Settings`, ⌘,): marca «?», sonido, háptica, tema y tamaño de casilla.
- [x] Efectos de sonido originales sintetizados al vuelo (`SoundSynth` + `AVAudioEngine`), sin archivos de audio.
- [x] Respuesta háptica en trackpad Force Touch (`NSHapticFeedbackManager`) al marcar, perder y ganar.
- [x] Modo claro/oscuro siguiendo el sistema (todos los colores tienen las dos variantes).
- [x] Temas visuales seleccionables: Relieve, Plano y Alto contraste.
- [x] Animaciones: onda de revelado en cascada, cadena de minas y sacudida al perder, confeti al ganar (respetan «Reducir movimiento»).
- [x] Zoom del tablero (20–44 pt; ⌘+ / ⌘− / ⌘0 en el menú Visualización).

## Fase 6 — Modo «sin adivinar»

- [x] Solucionador lógico en `CazaminasCore`: reglas simples, subconjuntos, enumeración de grupos de frontera y recuento global de minas.
- [x] Generador que prueba tableros (deterministas por semilla) hasta que el solucionador los resuelve desde el primer clic.
- [x] Límite de intentos (3000) y de tiempo (5 s); si no hay tablero posible (muy denso) se juega uno clásico y se avisa. Generación en segundo plano.
- [x] Tests: los tableros generados son resolubles; las pistas nunca llevan a perder. Medido: Experto tarda de mediana 7 ms y como máximo 75 ms.
- [x] Opción en Ajustes y en el menú (⌘G), con estadísticas y récords separados por modo.
- [x] Botón de pista (⌘J): resalta una casilla segura (verde) o una mina (naranja); ganar con pistas no entra en la tabla de récords.

## Fase 7 — Accesibilidad y pulido

- [x] VoiceOver: cada casilla es un botón con descripción («Fila 3, columna 5: 2 minas cerca»), acción principal y acción «Marcar»; avisos al ganar/perder; contadores con etiqueta.
- [x] Control completo por teclado: flechas mueven el cursor, Espacio destapa, F marca, Intro hace chording.
- [x] Contraste de los números ≥ 4,5:1 (WCAG AA) en todos los temas, claro y oscuro (`Tools/Contrast/check-contrast.py`). La pista de mina es discontinua para no depender solo del color.
- [x] Localización: español (base) e inglés con String Catalog (`App/Localizable.xcstrings`).
- [x] Icono de la app original (generado con `Tools/AppIcon/make-icon.swift`).
- [x] Pausa al cambiar de app o minimizar (y manual con ⌘P), ocultando el tablero; el tiempo en pausa no cuenta.

## Fase 8 — Distribución

- [ ] Script de build de Release con firma ad hoc (`codesign --force --deep -s -`).
- [ ] Empaquetado `.zip` o `.dmg`.
- [ ] GitHub Actions: tests en cada push y release al crear un tag.
- [ ] README completo: capturas, instalación y cómo abrir la app sin notarizar la primera vez
      (Ajustes del Sistema › Privacidad y seguridad › «Abrir igualmente»).
- [ ] `CHANGELOG.md` (autor App-Zilla).
- [ ] Publicar v1.0.0.

## Fase 9 — iOS / iPadOS (etapa muy posterior)

- [ ] Añadir destino iOS/iPadOS al target de la app (multiplataforma SwiftUI).
- [ ] Pulsación larga = bandera; toque en número = chording; opción de «modo bandera» con un botón.
- [ ] Zoom y desplazamiento con gestos para tableros grandes (Experto en iPhone).
- [ ] Implementación de `HapticsService` con `UIFeedbackGenerator` / `sensoryFeedback`.
- [ ] Ajustar diseño a iPhone vertical/horizontal e iPad.
- [ ] Distribución sin cuenta de pago: instalación desde Xcode en tus propios dispositivos (la firma gratuita caduca a los 7 días; documentarlo en el README).

---

## Ideas futuras (fuera del alcance de la v1)

- Repetición de partidas (semilla + lista de jugadas).
- Compartir un tablero mediante su semilla.
- Tableros con formas no rectangulares o hexagonales.
