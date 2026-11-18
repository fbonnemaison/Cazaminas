# Cazaminas

Juego de lógica para un jugador para macOS: despeja una cuadrícula de casillas ocultas sin detonar ninguna de las minas escondidas.

> Proyecto en desarrollo. Consulta el plan por fases en [TODO.md](TODO.md).

## Cómo se juega

- **El primer clic es seguro:** nunca contiene una mina y suele abrir un área amplia.
- **Números:** cada número (1–8) indica cuántas minas hay en las 8 casillas que lo rodean, diagonales incluidas.
- **Banderas:** clic derecho (o Control-clic) para marcar una casilla donde deduces que hay una mina. Un segundo clic la cambia por «?».
- **Chording:** clic (o clic central) sobre un número que ya tiene todas sus banderas alrededor destapa el resto de sus vecinas.
- **Nueva partida:** botón central o ⌘N.
- **Dificultad:** menú «Juego» › Principiante (⌘1), Intermedio (⌘2), Experto (⌘3) o Personalizado… (⌘4). Se recuerda la última elegida.
- **Victoria:** abre todas las casillas seguras del tablero, en el menor tiempo posible.
- **Ajustes (⌘,):** marca «?», sonido, respuesta háptica (trackpad Force Touch), tema (Relieve, Plano, Alto contraste) y tamaño de casilla.
- **Sin adivinar (⌘G):** tableros que siempre se pueden resolver con lógica desde el primer clic, con sus propios récords.
- **Pista (⌘J):** resalta una casilla segura (verde) o una mina (naranja). Ganar con pistas no cuenta para la tabla de récords.
- **Teclado:** flechas para moverse, Espacio destapa, F pone bandera e Intro hace chording.
- **Pausa (⌘P):** también automática al cambiar de app o minimizar; el tablero se oculta y el tiempo se detiene.
- **Zoom:** menú «Visualización» › Ampliar (⌘+), Reducir (⌘−) o Tamaño normal (⌘0).
- **Estadísticas:** menú «Juego» › Estadísticas… (⌘⇧S): partidas, % de victorias, rachas y los 10 mejores tiempos de cada nivel. Abandonar una partida empezada cuenta como derrota.

## Requisitos

- macOS 15 Sequoia o posterior.
- Para compilar: Xcode 16 o posterior y [XcodeGen](https://github.com/yonaskolb/XcodeGen) (solo si cambias `project.yml`).

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `CazaminasCore/` | Paquete Swift con la lógica del juego, sin interfaz (macOS e iOS). |
| `App/` | App de macOS en SwiftUI. El código exclusivo de Mac vive en `App/Platform/macOS/`. |
| `AppTests/` | Tests de la capa de presentación (`GameViewModel`). |
| `Tools/Contrast/` | Comprobación del contraste de los números de cada tema. |
| `Tools/AppIcon/` | Script que dibuja el icono de la app: `swift Tools/AppIcon/make-icon.swift App/Assets.xcassets/AppIcon.appiconset`. |
| `project.yml` | Definición del proyecto de Xcode para XcodeGen. |

## Compilar

```bash
open Cazaminas.xcodeproj
```

Si modificas `project.yml`, regenera el proyecto:

```bash
xcodegen generate
```

Tests del motor del juego:

```bash
swift test --package-path CazaminasCore
```

## Idiomas y accesibilidad

- La app está en español e inglés y sigue el idioma del sistema. Las traducciones están en `App/Localizable.xcstrings` (ábrelo en Xcode para editarlas).
- Funciona con VoiceOver: cada casilla describe su estado y se puede destapar o marcar con las acciones de VoiceOver.
- Respeta «Reducir movimiento» del sistema. Para comprobar el contraste de los temas:

```bash
python3 Tools/Contrast/check-contrast.py
```

## Abrir la app la primera vez

Cazaminas se distribuye gratis con firma ad hoc, sin notarizar por Apple, así que macOS la bloquea la primera vez que la abres:

1. Abre Cazaminas; macOS mostrará un aviso de que no puede verificar la app. Pulsa **OK**.
2. Ve a **Ajustes del Sistema › Privacidad y seguridad**.
3. Baja hasta el mensaje sobre Cazaminas y pulsa **Abrir igualmente**.
4. Confirma con tu contraseña o Touch ID. A partir de entonces se abrirá con normalidad.

## Licencia

[MIT](LICENSE) © 2026 App-Zilla
