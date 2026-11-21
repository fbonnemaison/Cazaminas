// Cazaminas — © 2026 App-Zilla. Licencia MIT.
//
// Genera el icono de la app (todas las resoluciones de macOS) a partir de la
// ilustración pixel art `Design/AppIcon-source.png`.
// Uso, desde la raíz del repositorio:
//
//     swift Tools/AppIcon/make-icon.swift Design/AppIcon-source.png App/Assets.xcassets/AppIcon.appiconset
//
// La ilustración es un cuadrado redondeado sobre fondo negro. El script localiza
// el cuadrado (lo que no es negro), lo recorta, lo encaja en el cuerpo de 824 pt
// de la rejilla de iconos de macOS con su máscara redondeada y añade la sombra.

import AppKit
import CoreGraphics
import Foundation

// MARK: - Entrada

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 2 else {
    print("Uso: swift Tools/AppIcon/make-icon.swift <ilustración.png> <AppIcon.appiconset>")
    exit(1)
}
let sourceURL = URL(fileURLWithPath: arguments[0])
let output = URL(fileURLWithPath: arguments[1])

guard let data = try? Data(contentsOf: sourceURL),
      let rep = NSBitmapImageRep(data: data),
      let source = rep.cgImage
else {
    print("No se pudo leer \(sourceURL.path)")
    exit(1)
}

/// Caja del cuadrado redondeado: filas y columnas centrales que no son negras.
func artworkBounds() -> CGRect {
    let w = rep.pixelsWide, h = rep.pixelsHigh
    func isBackground(_ x: Int, _ y: Int) -> Bool {
        guard let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return true }
        return c.redComponent + c.greenComponent + c.blueComponent < 0.25
    }
    let left = (0..<w).first { !isBackground($0, h / 2) } ?? 0
    let right = (0..<w).last { !isBackground($0, h / 2) } ?? w - 1
    let top = (0..<h).first { !isBackground(w / 2, $0) } ?? 0
    let bottom = (0..<h).last { !isBackground(w / 2, $0) } ?? h - 1
    // Un margen de unos píxeles quita el borde suavizado contra el negro.
    let inset = CGFloat(max(right - left, bottom - top)) * 0.004
    return CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1)
        .insetBy(dx: inset, dy: inset)
}

// MARK: - Dibujo (lienzo de 1024 × 1024)

func renderMaster() -> CGImage {
    let canvas = 1024
    let ctx = CGContext(
        data: nil, width: canvas, height: canvas, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    // Rejilla de iconos de macOS: cuerpo de 824 pt centrado (origen abajo).
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let corner: CGFloat = 185
    let shape = CGPath(roundedRect: body, cornerWidth: corner, cornerHeight: corner, transform: nil)

    // Sombra del icono.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: CGColor(gray: 0, alpha: 0.35))
    ctx.addPath(shape)
    ctx.setFillColor(CGColor(srgbRed: 0.2, green: 0.25, blue: 0.95, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // Ilustración recortada y encajada en el cuerpo.
    let crop = source.cropping(to: artworkBounds().integral)!
    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    ctx.interpolationQuality = .high
    ctx.draw(crop, in: body)
    ctx.restoreGState()

    return ctx.makeImage()!
}

// MARK: - Exportación

func resized(_ image: CGImage, to pixels: Int) -> CGImage {
    let ctx = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.interpolationQuality = .high
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    try data.write(to: url)
}

let master = renderMaster()
var images: [[String: String]] = []

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try writePNG(resized(master, to: points * scale), to: output.appendingPathComponent(name))
        images.append(["idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)", "filename": name])
    }
}

let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: output.appendingPathComponent("Contents.json"))
print("Icono generado en \(output.path)")
