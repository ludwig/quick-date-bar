import AppKit

// Renders a 1024x1024 macOS app icon: rounded-rect blue gradient with the
// "calendar" SF Symbol, matching the menu bar glyph in StatusBarController.
// Run via `just icon`; it regenerates every size in AppIcon.appiconset.
let canvas: CGFloat = 1024
let out = CommandLine.arguments[1]

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(canvas), pixelsHigh: Int(canvas),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: canvas, height: canvas)
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
ctx.cgContext.clear(CGRect(x: 0, y: 0, width: canvas, height: canvas))

// Apple's macOS icon grid: 824pt artwork centered on a 1024pt canvas.
let side: CGFloat = 824
let inset = (canvas - side) / 2
let tile = NSRect(x: inset, y: inset, width: side, height: side)
let path = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.shadowBlurRadius = 28
NSGraphicsContext.saveGraphicsState()
shadow.set()
NSColor.black.setFill()
path.fill()
NSGraphicsContext.restoreGraphicsState()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.29, green: 0.62, blue: 1.00, alpha: 1),
    NSColor(calibratedRed: 0.05, green: 0.34, blue: 0.85, alpha: 1),
])!
gradient.draw(in: path, angle: -90)

// Subtle top highlight.
let highlight = NSGradient(colors: [NSColor.white.withAlphaComponent(0.22), NSColor.white.withAlphaComponent(0)])!
highlight.draw(in: path, angle: -90)

let config = NSImage.SymbolConfiguration(pointSize: 520, weight: .medium)
let symbol = NSImage(systemSymbolName: "calendar", accessibilityDescription: nil)!
    .withSymbolConfiguration(config)!
let symbolSize = symbol.size
let symbolRect = NSRect(x: (canvas - symbolSize.width) / 2,
                        y: (canvas - symbolSize.height) / 2,
                        width: symbolSize.width, height: symbolSize.height)

// Draw the template symbol, then recolor its opaque pixels white.
let glyph = NSImage(size: symbolSize)
glyph.lockFocus()
symbol.draw(in: NSRect(origin: .zero, size: symbolSize))
NSColor.white.set()
NSRect(origin: .zero, size: symbolSize).fill(using: .sourceAtop)
glyph.unlockFocus()

let glyphShadow = NSShadow()
glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
glyphShadow.shadowOffset = NSSize(width: 0, height: -6)
glyphShadow.shadowBlurRadius = 14
NSGraphicsContext.saveGraphicsState()
glyphShadow.set()
glyph.draw(in: symbolRect)
NSGraphicsContext.restoreGraphicsState()

NSGraphicsContext.restoreGraphicsState()
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out) \(Int(canvas))x\(Int(canvas)) symbol=\(symbolSize)")
