import AppKit
import Foundation

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: make_icon.swift <output_png>\n", stderr)
    exit(2)
}

let outputPath = CommandLine.arguments[1]
let size = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Failed to allocate bitmap\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let rect = NSRect(x: 48, y: 48, width: 928, height: 928)
let bgPath = NSBezierPath(roundedRect: rect, xRadius: 210, yRadius: 210)
bgPath.addClip()

let grad = NSGradient(colors: [
    NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.28, alpha: 1.0),
    NSColor(calibratedRed: 0.12, green: 0.18, blue: 0.42, alpha: 1.0),
    NSColor(calibratedRed: 0.72, green: 0.21, blue: 0.15, alpha: 1.0),
])
grad?.draw(in: rect, angle: -42)

// Subtle inner highlight
NSColor(calibratedWhite: 1.0, alpha: 0.22).setStroke()
let border = NSBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4), xRadius: 206, yRadius: 206)
border.lineWidth = 6
border.stroke()

// Main "57" emblem
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 380, weight: .heavy),
    .foregroundColor: NSColor.white,
]
let title = "57" as NSString
let titleSize = title.size(withAttributes: titleAttrs)
title.draw(
    at: NSPoint(
        x: (CGFloat(size) - titleSize.width) / 2.0,
        y: 345
    ),
    withAttributes: titleAttrs
)

// Subtle top label
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 64, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.85),
]
let topText = "SOTAO" as NSString
let topSize = topText.size(withAttributes: subAttrs)
topText.draw(
    at: NSPoint(x: (CGFloat(size) - topSize.width) / 2.0, y: 745),
    withAttributes: subAttrs
)

// Bottom tools badge
let pillRect = NSRect(x: 192, y: 155, width: 640, height: 112)
NSColor(calibratedWhite: 0.0, alpha: 0.28).setFill()
let pill = NSBezierPath(roundedRect: pillRect, xRadius: 56, yRadius: 56)
pill.fill()

let pillAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.monospacedSystemFont(ofSize: 48, weight: .bold),
    .foregroundColor: NSColor.white,
]
let pillText = "MAC TOOLS" as NSString
let pillSize = pillText.size(withAttributes: pillAttrs)
pillText.draw(
    at: NSPoint(
        x: pillRect.midX - pillSize.width / 2.0,
        y: pillRect.midY - pillSize.height / 2.0 - 2
    ),
    withAttributes: pillAttrs
)

NSGraphicsContext.restoreGraphicsState()

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}
try pngData.write(to: URL(fileURLWithPath: outputPath))
print("ICON_PNG_OK:", outputPath)
