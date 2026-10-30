// Composes framed 1320×2868 App Store screenshots from raw Simulator captures.
// Run from the repo root:
//   swift Tools/MakeScreenshots.swift <raw-captures-folder> Marketing/AppStoreScreenshots
// Raw captures are named 1-home.png, 2-report.png, 3-capture.png, 4-issue.png, 5-export.png, 6-dark-room.png.

import AppKit

struct Slide {
    let input: String
    let output: String
    let headline: String
    let subtitle: String
    let dark: Bool
}

let slides = [
    Slide(input: "1-home", output: "01-key-dates", headline: "Never miss a key date",
          subtitle: "Every lease date, at a glance.", dark: false),
    Slide(input: "3-capture", output: "02-timestamped-photos", headline: "Timestamped photo evidence",
          subtitle: "Every photo is stamped with the date and time. Tag damage as you shoot.", dark: false),
    Slide(input: "2-report", output: "03-room-checklist", headline: "Walk every room, in order",
          subtitle: "A guided checklist so nothing gets missed.", dark: false),
    Slide(input: "4-issue", output: "04-flag-damage", headline: "Record damage before it's blamed on you",
          subtitle: "Type, severity and notes for every issue.", dark: false),
    Slide(input: "5-export", output: "05-pdf-report", headline: "A professional report in one tap",
          subtitle: "Share a PDF condition report or save it to Files.", dark: false),
    Slide(input: "6-dark-room", output: "06-dark-mode", headline: "Private by design",
          subtitle: "No account, no cloud. Everything stays on your iPhone, in light or dark.", dark: true),
]

let canvas = CGSize(width: 1320, height: 2868)
let args = CommandLine.arguments
let inputDir = URL(fileURLWithPath: args[1])
let outputDir = URL(fileURLWithPath: args[2])

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func centered(_ text: String, font: NSFont, color: NSColor, in rect: CGRect) -> CGFloat {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineBreakMode = .byWordWrapping
    let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
    let bounds = string.boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading])
    string.draw(with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: ceil(bounds.height)), options: [.usesLineFragmentOrigin, .usesFontLeading])
    return ceil(bounds.height)
}

for slide in slides {
    guard let screen = NSImage(contentsOf: inputDir.appending(path: "\(slide.input).png")) else {
        print("Missing \(slide.input).png"); continue
    }
    // Opaque sRGB canvas (App Store screenshots can't have transparency), with y running top to bottom.
    let cg = CGContext(data: nil, width: Int(canvas.width), height: Int(canvas.height), bitsPerComponent: 8, bytesPerRow: 0,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    cg.translateBy(x: 0, y: canvas.height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

    // Background.
    let colors = slide.dark ? [color(0x121A2B), color(0x070B12)] : [color(0x3F8F84), color(0x1B5249)]
    NSGradient(colors: colors)!.draw(in: CGRect(origin: .zero, size: canvas), angle: -90)

    // Headline and subtitle.
    let margin: CGFloat = 96
    var y: CGFloat = 170
    y += centered(slide.headline, font: .systemFont(ofSize: 104, weight: .bold), color: .white,
                  in: CGRect(x: margin, y: y, width: canvas.width - margin * 2, height: 0))
    y += 34
    y += centered(slide.subtitle, font: .systemFont(ofSize: 50, weight: .regular), color: color(0xFFFFFF, 0.82),
                  in: CGRect(x: margin + 20, y: y, width: canvas.width - (margin + 20) * 2, height: 0))

    // Device: the screen inside a black bezel, bleeding off the bottom edge.
    let screenWidth: CGFloat = 1000
    let screenHeight = screenWidth * screen.size.height / screen.size.width
    let bezel: CGFloat = 26
    let deviceTop = max(y + 90, 660)
    let device = CGRect(x: (canvas.width - screenWidth) / 2 - bezel, y: deviceTop, width: screenWidth + bezel * 2, height: screenHeight + bezel * 2)
    let deviceRadius: CGFloat = 170

    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: 30), blur: 80, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    NSColor(white: 0.06, alpha: 1).setFill()
    NSBezierPath(roundedRect: device, xRadius: deviceRadius, yRadius: deviceRadius).fill()
    cg.restoreGState()
    // Thin edge highlight around the bezel.
    color(0x3A4352).setStroke()
    let edge = NSBezierPath(roundedRect: device.insetBy(dx: 2, dy: 2), xRadius: deviceRadius - 2, yRadius: deviceRadius - 2)
    edge.lineWidth = 4
    edge.stroke()

    let screenRect = device.insetBy(dx: bezel, dy: bezel)
    cg.saveGState()
    NSBezierPath(roundedRect: screenRect, xRadius: deviceRadius - bezel, yRadius: deviceRadius - bezel).addClip()
    screen.draw(in: screenRect, from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    cg.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    let png = NSBitmapImageRep(cgImage: cg.makeImage()!).representation(using: .png, properties: [:])!
    try! png.write(to: outputDir.appending(path: "\(slide.output).png"))
    print("Wrote \(slide.output).png")
}
