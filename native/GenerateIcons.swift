import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1])

func rgb(_ value: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: CGFloat((value >> 16) & 255) / 255,
            green: CGFloat((value >> 8) & 255) / 255,
            blue: CGFloat(value & 255) / 255, alpha: alpha)
}

let plum = rgb(0x241A38)
let cream = rgb(0xFFF0D8)
let lavender = rgb(0xB8A8F2)
let coral = rgb(0xF47E78)

func line(_ points: [NSPoint], color: NSColor = cream, width: CGFloat = 3) {
    guard let first = points.first else { return }
    let path = NSBezierPath()
    path.move(to: first)
    for point in points.dropFirst() { path.line(to: point) }
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func outline(_ path: NSBezierPath, color: NSColor = cream, width: CGFloat = 3) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func shell(_ name: String) {
    let path = NSBezierPath(roundedRect: NSRect(x: 3, y: 3, width: 66, height: 66), xRadius: 15, yRadius: 15)
    (name == "dictate-stop" ? rgb(0x49263B) : plum).setFill()
    path.fill()
    outline(path, color: name == "dictate-stop" ? coral : rgb(0x766392), width: 1.6)
    line([NSPoint(x: 15, y: 61), NSPoint(x: 27, y: 63), NSPoint(x: 43, y: 63)],
         color: rgb(0xD7C7FF, alpha: 0.35), width: 1.3)
}

func mic(x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1) {
    func p(_ a: CGFloat, _ b: CGFloat) -> NSPoint { NSPoint(x: x + a * scale, y: y + b * scale) }
    let capsule = NSBezierPath(roundedRect: NSRect(x: x + 29 * scale, y: y + 30 * scale,
                                                   width: 14 * scale, height: 24 * scale),
                               xRadius: 7 * scale, yRadius: 7 * scale)
    outline(capsule, width: 3.4 * scale)
    let cradle = NSBezierPath()
    cradle.move(to: p(23, 38))
    cradle.curve(to: p(49, 38), controlPoint1: p(23, 17), controlPoint2: p(49, 17))
    outline(cradle, width: 3.4 * scale)
    line([p(36, 24), p(36, 17)], width: 3.4 * scale)
    line([p(28, 17), p(44, 17)], width: 3.4 * scale)
}

func symbol(_ name: String) {
    switch name {
    case "open":
        let font = NSFont.systemFont(ofSize: 43, weight: .bold)
        let text = NSAttributedString(string: "M", attributes: [.font: font, .foregroundColor: cream])
        let size = text.size()
        text.draw(at: NSPoint(x: (72 - size.width) / 2, y: (72 - size.height) / 2 + 2))
    case "side-chat":
        let rear = NSBezierPath(roundedRect: NSRect(x: 13, y: 29, width: 37, height: 27), xRadius: 8, yRadius: 8)
        outline(rear, color: lavender, width: 3)
        let front = NSBezierPath(roundedRect: NSRect(x: 22, y: 18, width: 37, height: 28), xRadius: 8, yRadius: 8)
        plum.setFill(); front.fill(); outline(front, width: 3)
        line([NSPoint(x: 36, y: 32), NSPoint(x: 46, y: 32)], color: lavender, width: 3.2)
        line([NSPoint(x: 41, y: 27), NSPoint(x: 41, y: 37)], color: lavender, width: 3.2)
    case "dictate":
        mic()
        let dot = NSBezierPath(ovalIn: NSRect(x: 53, y: 52, width: 7, height: 7))
        lavender.setFill(); dot.fill()
    case "dictate-stop":
        let stop = NSBezierPath(roundedRect: NSRect(x: 23, y: 23, width: 26, height: 26), xRadius: 5, yRadius: 5)
        cream.setFill(); stop.fill()
        let dot = NSBezierPath(ovalIn: NSRect(x: 53, y: 52, width: 7, height: 7))
        coral.setFill(); dot.fill()
    case "finish-send":
        mic(x: -9, y: 4, scale: 0.75)
        line([NSPoint(x: 40, y: 24), NSPoint(x: 55, y: 36), NSPoint(x: 40, y: 48)], color: coral, width: 4)
        line([NSPoint(x: 44, y: 36), NSPoint(x: 55, y: 36)], color: coral, width: 4)
    case "send-prompt":
        let page = NSBezierPath(roundedRect: NSRect(x: 18, y: 14, width: 35, height: 44), xRadius: 5, yRadius: 5)
        outline(page, width: 3)
        line([NSPoint(x: 25, y: 46), NSPoint(x: 43, y: 46)], color: lavender, width: 2.5)
        line([NSPoint(x: 25, y: 39), NSPoint(x: 38, y: 39)], color: lavender, width: 2.5)
        line([NSPoint(x: 38, y: 27), NSPoint(x: 55, y: 27)], color: coral, width: 3.5)
        line([NSPoint(x: 49, y: 33), NSPoint(x: 55, y: 27), NSPoint(x: 49, y: 21)], color: coral, width: 3.5)
    default: break
    }
}

func draw(_ name: String, size: Int, at url: URL) throws {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                       bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                       isPlanar: false, colorSpaceName: .deviceRGB,
                                       bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    context.cgContext.scaleBy(x: CGFloat(size) / 72, y: CGFloat(size) / 72)
    shell(name)
    symbol(name)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])?.write(to: url)
}

for name in ["open", "side-chat", "dictate", "dictate-stop", "finish-send", "send-prompt"] {
    let directory = root.appendingPathComponent(name)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try draw(name, size: 72, at: directory.appendingPathComponent("key.png"))
    try draw(name, size: 144, at: directory.appendingPathComponent("key@2x.png"))
    try draw(name, size: 28, at: directory.appendingPathComponent("icon.png"))
    try draw(name, size: 56, at: directory.appendingPathComponent("icon@2x.png"))
}

let pluginDirectory = root.deletingLastPathComponent().appendingPathComponent("plugin")
try draw("open", size: 28, at: pluginDirectory.appendingPathComponent("category-icon.png"))
try draw("open", size: 56, at: pluginDirectory.appendingPathComponent("category-icon@2x.png"))
try draw("open", size: 288, at: pluginDirectory.appendingPathComponent("marketplace.png"))
try draw("open", size: 512, at: pluginDirectory.appendingPathComponent("marketplace@2x.png"))
