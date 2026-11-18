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

- [ ] `GameViewModel` (`@Observable`) que conecta el motor con la UI.
- [ ] Vista del tablero (`Grid`/`LazyVGrid` o `Canvas` para tableros grandes).
- [ ] Vista de casilla: estados oculta, revelada, número coloreado, bandera, «?», mina, mina detonada, bandera errónea.
- [ ] Interacción: clic izquierdo = revelar; clic derecho y Control-clic = marcar; clic sobre número = chording.
- [ ] Barra superior: contador de minas, botón de reinicio (cara/estado), cronómetro.
- [ ] Cronómetro que arranca con el primer clic y se detiene al terminar.
- [ ] Ventana que se ajusta al tamaño del tablero.
- [ ] Mensajes de victoria/derrota.

## Fase 3 — Dificultades y tablero personalizado

- [ ] Principiante: 9×9, 10 minas.
- [ ] Intermedio: 16×16, 40 minas.
- [ ] Experto: 30×16, 99 minas.
- [ ] Personalizado: ancho, alto y minas con validación (límites razonables, minas < casillas − 9).
- [ ] Menú «Juego» en la barra de menús con atajos (⌘N nueva partida, ⌘1/⌘2/⌘3 dificultades).
- [ ] Recordar la última dificultad usada.

## Fase 4 — Récords y estadísticas

- [ ] Persistencia local (SwiftData o JSON en Application Support).
- [ ] Mejor tiempo por dificultad (top 10 con fecha).
- [ ] Estadísticas: partidas jugadas, ganadas, % de victorias, racha actual y máxima.
- [ ] Ventana/hoja de estadísticas y opción de reiniciarlas.
- [ ] Aviso de nuevo récord al ganar.

## Fase 5 — Ajustes, sonido, háptica y temas

- [ ] Ventana de Ajustes (`Settings` scene): activar «?», sonido, háptica, tema.
- [ ] Efectos de sonido originales (revelar, bandera, explosión, victoria) con `AVAudioPlayer`.
- [ ] Respuesta háptica en trackpad Force Touch (`NSHapticFeedbackManager`) al marcar y al perder.
- [ ] Modo claro/oscuro siguiendo el sistema.
- [ ] Temas visuales seleccionables (p. ej. clásico, moderno plano, alto contraste).
- [ ] Animaciones: revelado en cascada, explosión, celebración al ganar (respetando «Reducir movimiento»).
- [ ] Zoom del tablero (tamaño de casilla ajustable, ⌘+ / ⌘−).

## Fase 6 — Modo «sin adivinar»

- [ ] Solucionador lógico en `CazaminasCore` (reglas simples + análisis de restricciones entre números vecinos).
- [ ] Generador que repite/ajusta tableros hasta que el solucionador los resuelve desde el primer clic sin azar.
- [ ] Límite de intentos y tiempo con fallback razonable; generación en segundo plano (sin bloquear la UI).
- [ ] Tests: todo tablero generado en este modo es resoluble por el solucionador.
- [ ] Opción en Ajustes y récords separados para este modo.
- [ ] (Opcional) Botón de pista que usa el solucionador.

## Fase 7 — Accesibilidad y pulido

- [ ] VoiceOver: etiquetas por casilla («fila 3, columna 5, 2 minas cerca»).
- [ ] Control completo por teclado (flechas, Espacio = revelar, F = bandera, Intro = chording).
- [ ] Colores de números con contraste suficiente y no depender solo del color.
- [ ] Localización: español (base) e inglés con String Catalog.
- [ ] Icono de la app original.
- [ ] Pausa al minimizar / perder foco (ocultando el tablero).

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
