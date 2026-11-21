# Changelog

Todos los cambios importantes de Cazaminas se anotan aquí.
El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y las versiones siguen [Versionado Semántico](https://semver.org/lang/es/).

Autor: App-Zilla.

## [1.1.0] - 2026-11-21

### Añadido

- Estilo gráfico **Pixel art**, a elegir en Ajustes › Apariencia junto al estilo actual, que pasa a llamarse **HD**. Casillas con relieve, números, banderas, «?» y minas dibujados en pixel art de 16 × 16 con los colores del tema elegido, tablero de esquinas rectas y contadores con la fuente Public Pixel (CC0).

### Cambiado

- Nuevo icono de la app: mina pixel art sobre fondo azul y violeta.

## [1.0.0] - 2026-11-17

Primera versión.

### Juego

- Niveles Principiante (9×9, 10 minas), Intermedio (16×16, 40) y Experto (30×16, 99), y tableros personalizados de 5×5 a 40×24.
- Primer clic seguro: ni la casilla ni sus vecinas tienen mina.
- Banderas, marca «?» opcional y chording (clic o clic central sobre un número).
- Modo sin adivinar: tableros que siempre se pueden resolver con lógica desde el primer clic.
- Pistas que señalan la siguiente casilla segura o mina deducible.
- Pausa manual y automática al cambiar de app o minimizar.

### Estadísticas

- Partidas, % de victorias, rachas y los 10 mejores tiempos por nivel y modo.
- Las partidas abandonadas cuentan como derrota; las ganadas con pistas no entran en los récords.

### Apariencia y sonido

- Temas Relieve, Plano y Alto contraste, en modo claro y oscuro.
- Zoom del tablero (20–44 pt).
- Animaciones de cascada, explosión y confeti, que respetan «Reducir movimiento».
- Efectos de sonido sintetizados y respuesta háptica en trackpads Force Touch.

### Accesibilidad e idiomas

- VoiceOver: cada casilla describe su estado y se puede destapar o marcar.
- Control completo por teclado.
- Contraste de los números de nivel AA (4,5:1) en todos los temas.
- Español e inglés.

### Distribución

- App universal (Apple Silicon e Intel) para macOS 15 o posterior, con firma ad hoc y sin notarizar.
- `.dmg` y `.zip` con sumas SHA-256, publicados automáticamente con GitHub Actions.

[1.1.0]: ../../releases/tag/v1.1.0
[1.0.0]: ../../releases/tag/v1.0.0
