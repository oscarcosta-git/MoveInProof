// Renders the 1024×1024 App Store icon. Run from the repo root:
//   swift Tools/MakeAppIcon.swift MoveInProof/Assets.xcassets/AppIcon.appiconset/AppIcon.png

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MoveIn Proof icon: a white house with a checkmark on a deep teal gradient.
let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
// noneSkipLast: opaque, no alpha channel, as App Store icons require.
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.translateBy(x: 0, y: CGFloat(size)); ctx.scaleBy(x: 1, y: -1) // top-left origin

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let gradient = CGGradient(colorsSpace: space, colors: [rgb(0x3F8F84), rgb(0x1B5249)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 1024), options: [])

// Soft mint glow behind the house.
let glow = CGGradient(colorsSpace: space, colors: [rgb(0x6BCFC2).copy(alpha: 0.35)!, rgb(0x6BCFC2).copy(alpha: 0)!] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 470), startRadius: 0, endCenter: CGPoint(x: 512, y: 470), endRadius: 470, options: [])

// House: roof apex, eaves and walls, with rounded joins.
let house = CGMutablePath()
house.move(to: CGPoint(x: 512, y: 238))
house.addLine(to: CGPoint(x: 806, y: 486))
house.addLine(to: CGPoint(x: 740, y: 486))
house.addLine(to: CGPoint(x: 740, y: 790))
house.addLine(to: CGPoint(x: 284, y: 790))
house.addLine(to: CGPoint(x: 284, y: 486))
house.addLine(to: CGPoint(x: 218, y: 486))
house.closeSubpath()

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 18), blur: 40, color: rgb(0x0B2420).copy(alpha: 0.45))
// One transparency layer so the fill and stroke cast a single shadow.
ctx.beginTransparencyLayer(auxiliaryInfo: nil)
ctx.addPath(house)
ctx.setFillColor(rgb(0xFFFFFF))
ctx.setStrokeColor(rgb(0xFFFFFF))
ctx.setLineWidth(56)
ctx.setLineJoin(.round)
ctx.drawPath(using: .fillStroke)
ctx.endTransparencyLayer()
ctx.restoreGState()

// Checkmark: "proof".
let check = CGMutablePath()
check.move(to: CGPoint(x: 398, y: 618))
check.addLine(to: CGPoint(x: 482, y: 700))
check.addLine(to: CGPoint(x: 640, y: 538))
ctx.addPath(check)
ctx.setStrokeColor(rgb(0x22665C))
ctx.setLineWidth(62)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.strokePath()

let image = ctx.makeImage()!
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
