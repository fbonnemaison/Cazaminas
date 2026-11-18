# Cazaminas

Juego de lógica para un jugador para macOS: despeja una cuadrícula de casillas ocultas sin detonar ninguna de las minas escondidas.

> Proyecto en desarrollo. Consulta el plan por fases en [TODO.md](TODO.md).

## Cómo se juega

- **El primer clic es seguro:** nunca contiene una mina y suele abrir un área amplia.
- **Números:** cada número (1–8) indica cuántas minas hay en las 8 casillas que lo rodean, diagonales incluidas.
- **Banderas:** clic derecho (o Control-clic) para marcar una casilla donde deduces que hay una mina.
- **Victoria:** abre todas las casillas seguras del tablero, en el menor tiempo posible.

## Requisitos

- macOS 15 Sequoia o posterior.
- Para compilar: Xcode 16 o posterior y [XcodeGen](https://github.com/yonaskolb/XcodeGen) (solo si cambias `project.yml`).

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `CazaminasCore/` | Paquete Swift con la lógica del juego, sin interfaz (macOS e iOS). |
| `App/` | App de macOS en SwiftUI. |
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

## Abrir la app la primera vez

Cazaminas se distribuye gratis con firma ad hoc, sin notarizar por Apple, así que macOS la bloquea la primera vez que la abres:

1. Abre Cazaminas; macOS mostrará un aviso de que no puede verificar la app. Pulsa **OK**.
2. Ve a **Ajustes del Sistema › Privacidad y seguridad**.
3. Baja hasta el mensaje sobre Cazaminas y pulsa **Abrir igualmente**.
4. Confirma con tu contraseña o Touch ID. A partir de entonces se abrirá con normalidad.

## Licencia

[MIT](LICENSE) © 2026 App-Zilla
