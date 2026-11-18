#!/usr/bin/env python3
# Cazaminas — © 2026 App-Zilla. Licencia MIT.
#
# Comprueba el contraste (WCAG) de los números de cada tema sobre las casillas
# destapadas, en modo claro y oscuro. Uso, desde la raíz del repositorio:
#
#     python3 Tools/Contrast/check-contrast.py
#
# Falla (código 1) si algún número baja de 4,5:1.
import re
import sys

MINIMUM = 4.5
source = open("App/Views/BoardTheme.swift", encoding="utf-8").read()


def luminance(hex_value):
    channels = [((hex_value >> shift) & 0xFF) / 255 for shift in (16, 8, 0)]
    channels = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def ratio(a, b):
    high, low = sorted([luminance(a), luminance(b)], reverse=True)
    return (high + 0.05) / (low + 0.05)


failed = False
for theme in re.findall(r"static let (\w+) = BoardTheme\(", source):
    block = source[source.index(f"static let {theme} = BoardTheme("):]
    block = block[: block.index("\n    )\n")]
    light_bg, dark_bg = (int(v, 16) for v in re.search(
        r"cellRevealed: \.dynamic\(light: 0x(\w+), dark: 0x(\w+)\)", block).groups())
    numbers = re.findall(r"\.dynamic\(light: 0x(\w+), dark: 0x(\w+)\)", block[block.index("numbers:"):])
    light = min(ratio(int(l, 16), light_bg) for l, _ in numbers)
    dark = min(ratio(int(d, 16), dark_bg) for _, d in numbers)
    ok = light >= MINIMUM and dark >= MINIMUM
    failed |= not ok
    print(f"{'✔' if ok else '✘'} {theme}: mínimo {light:.2f}:1 en claro, {dark:.2f}:1 en oscuro")

sys.exit(1 if failed else 0)
