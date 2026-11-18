// Cazaminas — © 2026 App-Zilla. Licencia MIT.
//
// Genera el icono de la app (todas las resoluciones de macOS) con Core Graphics.
// Uso, desde la raíz del repositorio:
//
//     swift Tools/AppIcon/make-icon.swift App/Assets.xcassets/AppIcon.appiconset
//
// Estilo: cuadrado redondeado con degradado azul → violeta y una mina cian brillante
// con 8 púas redondeadas y un botón central.

import AppKit
import CoreGraphics
import Foundation

// MARK: - Utilidades

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func gradient(_ stops: [(UInt32, CGFloat, CGFloat)]) -> CGGradient {
    CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: stops.map { color($0.0, $0.1) } as CFArray,
        locations: stops.map(\.2)
    )!
}

func circle(_ center: CGPoint, _ radius: CGFloat) -> CGRect {
    CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
}

// MARK: - Dibujo (lienzo de 1024 × 1024, origen arriba a la izquierda)

func drawIcon(in ctx: CGContext) {
    let canvas: CGFloat = 1024
    ctx.translateBy(x: 0, y: canvas)
    ctx.scaleBy(x: 1, y: -1)

    // Rejilla de iconos de macOS: cuerpo de 824 pt centrado.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let corner: CGFloat = 185
    let shape = CGPath(roundedRect: body, cornerWidth: corner, cornerHeight: corner, transform: nil)

    // Sombra del icono.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 14), blur: 30, color: color(0x000000, 0.35))
    ctx.addPath(shape)
    ctx.setFillColor(color(0x2A3BF5))
    ctx.fillPath()
    ctx.restoreGState()

    // Fondo: degradado azul eléctrico → violeta.
    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    ctx.drawLinearGradient(
        gradient([(0x3D63FF, 1, 0), (0x1C2BEE, 1, 0.45), (0x6A2BEF, 1, 0.78), (0xB146E6, 1, 1)]),
        start: CGPoint(x: 140, y: 120),
        end: CGPoint(x: 940, y: 900),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    // Resplandor cian detrás de la mina.
    ctx.drawRadialGradient(
        gradient([(0x46D9FF, 0.45, 0), (0x46D9FF, 0, 1)]),
        startCenter: CGPoint(x: 512, y: 500), startRadius: 0,
        endCenter: CGPoint(x: 512, y: 500), endRadius: 420,
        options: []
    )
    // Brillo suave en la parte superior.
    ctx.drawLinearGradient(
        gradient([(0xFFFFFF, 0.16, 0), (0xFFFFFF, 0, 0.35)]),
        start: CGPoint(x: 512, y: 100),
        end: CGPoint(x: 512, y: 924),
        options: []
    )
    ctx.restoreGState()

    // Borde interior de cristal.
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: body.insetBy(dx: 3, dy: 3), cornerWidth: corner - 3, cornerHeight: corner - 3, transform: nil))
    ctx.setStrokeColor(color(0xFFFFFF, 0.22))
    ctx.setLineWidth(4)
    ctx.strokePath()
    ctx.restoreGState()

    drawMine(in: ctx, center: CGPoint(x: 512, y: 505))
}

func drawMine(in ctx: CGContext, center: CGPoint) {
    let bodyRadius: CGFloat = 236
    let spikeInner: CGFloat = 150
    let spikeOuter: CGFloat = 338
    let spikeWidth: CGFloat = 94

    // Resplandor exterior.
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 70, color: color(0x5BE6FF, 0.75))
    ctx.setFillColor(color(0x2BC3E6))
    ctx.fillEllipse(in: circle(center, bodyRadius * 0.95))
    ctx.restoreGState()

    // Púas: 8 cápsulas con volumen cilíndrico.
    for index in 0..<8 {
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: CGFloat(index) * .pi / 4)

        let rect = CGRect(x: -spikeWidth / 2, y: -spikeOuter, width: spikeWidth, height: spikeOuter - spikeInner)
        let capsule = CGPath(roundedRect: rect, cornerWidth: spikeWidth / 2, cornerHeight: spikeWidth / 2, transform: nil)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 6), blur: 14, color: color(0x0A1490, 0.45))
        ctx.addPath(capsule)
        ctx.setFillColor(color(0x1FAFD8))
        ctx.fillPath()
        ctx.restoreGState()

        ctx.addPath(capsule)
        ctx.clip()
        ctx.drawLinearGradient(
            gradient([(0x0F7DB6, 1, 0), (0x3ED0EF, 1, 0.28), (0x7DEEFD, 1, 0.45), (0x2EC0E5, 1, 0.72), (0x0C6AA3, 1, 1)]),
            start: CGPoint(x: -spikeWidth / 2, y: 0),
            end: CGPoint(x: spikeWidth / 2, y: 0),
            options: []
        )
        // Brillo en la punta.
        ctx.drawRadialGradient(
            gradient([(0xFFFFFF, 0.75, 0), (0xFFFFFF, 0, 1)]),
            startCenter: CGPoint(x: -10, y: -spikeOuter + 26), startRadius: 0,
            endCenter: CGPoint(x: -10, y: -spikeOuter + 26), endRadius: 30,
            options: []
        )
        ctx.restoreGState()
    }

    // Cuerpo esférico.
    let sphere = circle(center, bodyRadius)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 18), blur: 36, color: color(0x0A1490, 0.5))
    ctx.setFillColor(color(0x22B4DC))
    ctx.fillEllipse(in: sphere)
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addEllipse(in: sphere)
    ctx.clip()
    ctx.drawRadialGradient(
        gradient([(0xC4FDFF, 1, 0), (0x6BE7F9, 1, 0.35), (0x2CC0E4, 1, 0.75), (0x168FC6, 1, 1)]),
        startCenter: CGPoint(x: center.x - 80, y: center.y - 95), startRadius: 0,
        endCenter: center, endRadius: bodyRadius,
        options: [.drawsAfterEndLocation]
    )
    // Reflejo violeta del fondo en la parte inferior.
    ctx.drawRadialGradient(
        gradient([(0xB070FF, 0.55, 0), (0xB070FF, 0, 1)]),
        startCenter: CGPoint(x: center.x + 40, y: center.y + bodyRadius + 10), startRadius: 0,
        endCenter: CGPoint(x: center.x + 40, y: center.y + bodyRadius + 10), endRadius: 200,
        options: []
    )
    ctx.restoreGState()

    // Brillo especular.
    ctx.saveGState()
    ctx.translateBy(x: center.x - 108, y: center.y - 118)
    ctx.rotate(by: -.pi / 5)
    let highlight = CGRect(x: -62, y: -36, width: 124, height: 72)
    ctx.addEllipse(in: highlight)
    ctx.clip()
    ctx.drawLinearGradient(
        gradient([(0xFFFFFF, 0.95, 0), (0xFFFFFF, 0.15, 1)]),
        start: CGPoint(x: 0, y: -36),
        end: CGPoint(x: 0, y: 36),
        options: []
    )
    ctx.restoreGState()

    // Botón central: anillo y cúpula azul.
    let ring = circle(center, 66)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 10, color: color(0x07307A, 0.5))
    ctx.setFillColor(color(0x2AB9E2))
    ctx.fillEllipse(in: ring)
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addEllipse(in: ring)
    ctx.clip()
    ctx.drawLinearGradient(
        gradient([(0x1792C8, 1, 0), (0x7BEAFB, 1, 1)]),
        start: CGPoint(x: center.x, y: center.y - 66),
        end: CGPoint(x: center.x, y: center.y + 66),
        options: []
    )
    ctx.restoreGState()
    ctx.setStrokeColor(color(0x0E5FA8, 0.9))
    ctx.setLineWidth(7)
    ctx.strokeEllipse(in: ring.insetBy(dx: 3.5, dy: 3.5))

    let dome = circle(center, 40)
    ctx.saveGState()
    ctx.addEllipse(in: dome)
    ctx.clip()
    ctx.drawRadialGradient(
        gradient([(0x6F9BFF, 1, 0), (0x2650E8, 1, 0.55), (0x0B2496, 1, 1)]),
        startCenter: CGPoint(x: center.x - 12, y: center.y - 14), startRadius: 0,
        endCenter: center, endRadius: 40,
        options: [.drawsAfterEndLocation]
    )
    ctx.restoreGState()
    ctx.setFillColor(color(0xFFFFFF, 0.7))
    ctx.fillEllipse(in: CGRect(x: center.x - 22, y: center.y - 26, width: 18, height: 12))
}

// MARK: - Exportación

func renderMaster() -> CGImage {
    let ctx = CGContext(
        data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    drawIcon(in: ctx)
    return ctx.makeImage()!
}

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

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
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
