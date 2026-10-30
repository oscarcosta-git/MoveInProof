import UIKit

/// Builds the condition report as an A4 PDF: a cover page with the tenancy and a room summary,
/// then a section per room with its flagged issues and timestamped photos.
struct ConditionReportPDF {
    var tenancy: Tenancy
    var rooms: [Room]
    var includePhotos: Bool
    var flaggedOnly: Bool

    /// Writes the PDF to a temporary file and returns its URL.
    func write() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: fileName)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Condition report – \(tenancy.streetAddress)",
            kCGPDFContextCreator as String: "MoveIn Proof",
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: Layout.page, format: format)
        try renderer.writePDF(to: url) { context in
            var page = PageWriter(context: context, footer: tenancy.streetAddress)
            drawCover(on: &page)
            for room in rooms {
                drawRoom(room, on: &page)
            }
        }
        return url
    }

    var fileName: String {
        let safe = tenancy.streetAddress
            .components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespaces)
        return "Condition report – \(safe.isEmpty ? "MoveIn Proof" : safe).pdf"
    }

    // MARK: - Cover

    private func drawCover(on page: inout PageWriter) {
        page.newPage()
        page.accentBar()
        page.text("Condition report", style: .title)
        page.text(tenancy.streetAddress, style: .heading)
        if !tenancy.suburb.isEmpty {
            page.text(tenancy.suburb, style: .body, color: Layout.secondary)
        }
        page.space(18)

        page.keyValue("Lease", "\(tenancy.leaseStart.longText) – \(tenancy.leaseEnd.longText)")
        page.keyValue("Condition report due", tenancy.reportDue.longText)
        page.keyValue("Move-out inspection", tenancy.moveOutInspection?.longText ?? "Not booked")
        page.keyValue("Report created", Date.now.timestampText)
        page.space(18)

        page.text("Summary", style: .subheading)
        page.text(
            "\(tenancy.rooms.count.counted("room")) · \(tenancy.photoCount.counted("photo")) · \(tenancy.issueCount.counted("issue")) flagged",
            style: .body
        )
        if flaggedOnly {
            page.text("This report only includes rooms with flagged issues.", style: .small, color: Layout.secondary)
        }
        page.space(12)

        for room in tenancy.sortedRooms {
            let status = room.isComplete ? "Done" : (room.photos.isEmpty ? "Not started" : "In progress")
            page.tableRow(room.name, "\(room.photos.count.counted("photo")) · \(room.issues.count.counted("issue")) · \(status)")
        }

        page.space(24)
        page.text(
            "Every photo in this report was taken in MoveIn Proof and is stamped with the date and time it was taken on this iPhone. Photos have not been edited.",
            style: .small,
            color: Layout.secondary
        )
    }

    // MARK: - Rooms

    private func drawRoom(_ room: Room, on page: inout PageWriter) {
        page.newPage()
        page.accentBar()
        page.text(room.name, style: .title)
        let status = room.isComplete ? "Done" : "In progress"
        page.text("\(room.photos.count.counted("photo")) · \(room.issues.count.counted("issue")) · \(status)", style: .body, color: Layout.secondary)
        page.space(14)

        if !room.issues.isEmpty {
            page.text("Flagged issues", style: .subheading)
            for issue in room.sortedIssues {
                drawIssue(issue, on: &page)
            }
            page.space(10)
        }

        let photos = room.sortedPhotos
        guard !photos.isEmpty else { return }
        page.text("Photos", style: .subheading)
        if includePhotos {
            page.photoGrid(photos)
        } else {
            page.text("\(photos.count.counted("photo")) taken. Photos are left out of this copy of the report.", style: .body, color: Layout.secondary)
        }
    }

    private func drawIssue(_ issue: Issue, on page: inout PageWriter) {
        let thumb = includePhotos ? issue.sortedPhotos.first : nil
        let textX = thumb == nil ? Layout.margin : Layout.margin + Layout.issueThumb.width + 12
        let textWidth = Layout.contentWidth - (textX - Layout.margin)

        let kind = issue.typeName
        let detail = "\(issue.severity.rawValue) · \(kind) · \(issue.photos.count.counted("photo"))"
        let blocks: [(String, TextStyle, UIColor)] = [
            (issue.title, .bodyBold, Layout.primary),
            (detail, .small, Layout.secondary),
        ] + (issue.notes.isEmpty ? [] : [(issue.notes, .body, Layout.primary)])

        let textHeight = blocks.reduce(0) { $0 + PageWriter.height(of: $1.0, style: $1.1, width: textWidth) + 2 }
        let rowHeight = max(textHeight, thumb == nil ? 0 : Layout.issueThumb.height) + 12
        page.ensureSpace(rowHeight)

        let top = page.y
        if let thumb {
            page.drawPhoto(thumb, in: CGRect(origin: CGPoint(x: Layout.margin, y: top), size: Layout.issueThumb))
        }
        var y = top
        for (string, style, color) in blocks {
            y += PageWriter.draw(string, style: style, color: color, at: CGPoint(x: textX, y: y), width: textWidth) + 2
        }
        page.y = top + rowHeight
    }
}

// MARK: - Layout

private enum Layout {
    static let page = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 in points
    static let margin: CGFloat = 40
    static let contentWidth = page.width - margin * 2
    static let bottom = page.height - margin - 14 // leave room for the footer

    static let issueThumb = CGSize(width: 60, height: 80)
    static let gridColumns = 3
    static let gridSpacing: CGFloat = 8
    static let captionHeight: CGFloat = 20
    /// Cell height / width, matching the 3:4 portrait photos so the stamped timestamp is never cropped.
    static let photoAspect: CGFloat = 4 / 3

    static let primary = UIColor(red: 0x11 / 255, green: 0x18 / 255, blue: 0x27 / 255, alpha: 1)
    static let secondary = UIColor(red: 0x5B / 255, green: 0x64 / 255, blue: 0x72 / 255, alpha: 1)
    static let accent = UIColor(red: 0x35 / 255, green: 0x78 / 255, blue: 0x6F / 255, alpha: 1)
    static let rule = UIColor(red: 0xE1 / 255, green: 0xE4 / 255, blue: 0xE9 / 255, alpha: 1)
}

private enum TextStyle {
    case title, heading, subheading, body, bodyBold, small, caption

    var font: UIFont {
        switch self {
        case .title: .systemFont(ofSize: 26, weight: .bold)
        case .heading: .systemFont(ofSize: 16, weight: .semibold)
        case .subheading: .systemFont(ofSize: 13, weight: .semibold)
        case .body: .systemFont(ofSize: 11)
        case .bodyBold: .systemFont(ofSize: 11, weight: .semibold)
        case .small: .systemFont(ofSize: 9.5)
        case .caption: .systemFont(ofSize: 7.5)
        }
    }

    var spacingAfter: CGFloat {
        switch self {
        case .title: 6
        case .heading, .subheading: 6
        default: 3
        }
    }
}

/// Tracks the vertical position on the current page and starts new pages as content fills them.
private struct PageWriter {
    let context: UIGraphicsPDFRendererContext
    let footer: String
    var y: CGFloat = Layout.margin
    private var pageNumber = 0

    init(context: UIGraphicsPDFRendererContext, footer: String) {
        self.context = context
        self.footer = footer
    }

    mutating func newPage() {
        context.beginPage()
        pageNumber += 1
        y = Layout.margin
        let footerY = Layout.page.height - Layout.margin
        Self.draw("\(footer) · Condition report", style: .caption, color: Layout.secondary,
                  at: CGPoint(x: Layout.margin, y: footerY), width: Layout.contentWidth / 2)
        let pageText = "Page \(pageNumber)"
        let pageWidth = Self.width(of: pageText, style: .caption)
        Self.draw(pageText, style: .caption, color: Layout.secondary,
                  at: CGPoint(x: Layout.page.width - Layout.margin - pageWidth, y: footerY), width: pageWidth + 1)
    }

    mutating func ensureSpace(_ height: CGFloat) {
        if y + height > Layout.bottom { newPage() }
    }

    mutating func space(_ amount: CGFloat) {
        y += amount
    }

    mutating func accentBar() {
        Layout.accent.setFill()
        UIRectFill(CGRect(x: Layout.margin, y: y, width: 36, height: 3))
        y += 14
    }

    mutating func text(_ string: String, style: TextStyle, color: UIColor = Layout.primary) {
        let height = Self.height(of: string, style: style, width: Layout.contentWidth)
        ensureSpace(height)
        Self.draw(string, style: style, color: color, at: CGPoint(x: Layout.margin, y: y), width: Layout.contentWidth)
        y += height + style.spacingAfter
    }

    mutating func keyValue(_ key: String, _ value: String) {
        ensureSpace(18)
        Self.draw(key, style: .body, color: Layout.secondary, at: CGPoint(x: Layout.margin, y: y), width: 150)
        Self.draw(value, style: .bodyBold, color: Layout.primary, at: CGPoint(x: Layout.margin + 150, y: y), width: Layout.contentWidth - 150)
        y += 18
    }

    mutating func tableRow(_ left: String, _ right: String) {
        ensureSpace(22)
        Layout.rule.setFill()
        UIRectFill(CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: 0.5))
        Self.draw(left, style: .bodyBold, color: Layout.primary, at: CGPoint(x: Layout.margin, y: y + 5), width: 200)
        let rightWidth = Self.width(of: right, style: .body)
        Self.draw(right, style: .body, color: Layout.secondary,
                  at: CGPoint(x: Layout.margin + Layout.contentWidth - rightWidth, y: y + 5), width: rightWidth + 1)
        y += 22
    }

    mutating func photoGrid(_ photos: [Photo]) {
        let columns = CGFloat(Layout.gridColumns)
        let cellWidth = (Layout.contentWidth - Layout.gridSpacing * (columns - 1)) / columns
        let imageHeight = cellWidth * Layout.photoAspect
        let captionHeight = Layout.captionHeight
        let rowHeight = imageHeight + captionHeight + Layout.gridSpacing

        for rowStart in stride(from: 0, to: photos.count, by: Layout.gridColumns) {
            ensureSpace(imageHeight + captionHeight)
            for (column, photo) in photos[rowStart..<min(rowStart + Layout.gridColumns, photos.count)].enumerated() {
                let x = Layout.margin + CGFloat(column) * (cellWidth + Layout.gridSpacing)
                drawPhoto(photo, in: CGRect(x: x, y: y, width: cellWidth, height: imageHeight))
                let flag = photo.issue == nil ? "" : " · Issue"
                Self.draw("\(photo.location)\(flag) · \(photo.capturedAt.timestampText)", style: .caption, color: Layout.secondary,
                          at: CGPoint(x: x, y: y + imageHeight + 3), width: cellWidth)
            }
            y += rowHeight
        }
    }

    /// Draws the whole photo fitted inside the frame. It's never cropped, so the timestamp stamped
    /// in its corner always shows. Images are downsized and re-encoded as JPEG to keep the PDF small.
    func drawPhoto(_ photo: Photo, in frame: CGRect) {
        guard let cg = UIGraphicsGetCurrentContext() else { return }
        cg.saveGState()
        UIBezierPath(roundedRect: frame, cornerRadius: 4).addClip()
        Layout.rule.setFill()
        UIRectFill(frame)

        if let image = PhotoStore.image(named: photo.fileName) {
            let pixelWidth = frame.width * 3
            let size = CGSize(width: pixelWidth, height: pixelWidth * image.size.height / max(image.size.width, 1))
            let prepared = image.preparingThumbnail(of: size)
                .flatMap { $0.jpegData(compressionQuality: 0.7) }
                .flatMap(UIImage.init(data:)) ?? image
            let scale = min(frame.width / prepared.size.width, frame.height / prepared.size.height)
            let drawSize = CGSize(width: prepared.size.width * scale, height: prepared.size.height * scale)
            prepared.draw(in: CGRect(x: frame.midX - drawSize.width / 2, y: frame.midY - drawSize.height / 2,
                                     width: drawSize.width, height: drawSize.height))
        }

        cg.restoreGState()
        if photo.issue != nil {
            UIColor(red: 0x9B / 255, green: 0x2C / 255, blue: 0x22 / 255, alpha: 1).setStroke()
            let outline = UIBezierPath(roundedRect: frame.insetBy(dx: 0.75, dy: 0.75), cornerRadius: 4)
            outline.lineWidth = 1.5
            outline.stroke()
        }
    }

    // MARK: Text helpers

    private static func attributes(_ style: TextStyle, _ color: UIColor) -> [NSAttributedString.Key: Any] {
        [.font: style.font, .foregroundColor: color]
    }

    static func height(of string: String, style: TextStyle, width: CGFloat) -> CGFloat {
        ceil(NSAttributedString(string: string, attributes: attributes(style, Layout.primary))
            .boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            .height)
    }

    static func width(of string: String, style: TextStyle) -> CGFloat {
        ceil(NSAttributedString(string: string, attributes: attributes(style, Layout.primary)).size().width)
    }

    /// Draws wrapped text and returns its height.
    @discardableResult
    static func draw(_ string: String, style: TextStyle, color: UIColor, at origin: CGPoint, width: CGFloat) -> CGFloat {
        let height = height(of: string, style: style, width: width)
        NSAttributedString(string: string, attributes: attributes(style, color))
            .draw(with: CGRect(x: origin.x, y: origin.y, width: width, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return height
    }
}
