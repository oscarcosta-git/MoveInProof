import SwiftUI
import UIKit

/// Saves photo images as JPEG files in Application Support, so they stay on this iPhone.
enum PhotoStore {
    static var directory: URL {
        URL.applicationSupportDirectory.appending(path: "Photos", directoryHint: .isDirectory)
    }

    static func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    /// Writes the image and returns its file name.
    static func save(_ image: UIImage) throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url(for: fileName), options: [.atomic, .completeFileProtection])
        return fileName
    }

    static func image(named fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path(percentEncoded: false))
    }

    static func deleteFile(named fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    static func deleteAllFiles() {
        try? FileManager.default.removeItem(at: directory)
    }

    /// Shrinks a camera photo to a sensible size and burns the capture time into its corner,
    /// so the timestamp survives however the photo is shared later.
    static func stamped(_ image: UIImage, at date: Date, maxDimension: CGFloat = 2400) -> UIImage {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))

            let fontSize = max(14, size.width * 0.032)
            let text = NSAttributedString(string: date.timestampText, attributes: [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white,
            ])
            let padding = fontSize * 0.6
            let margin = fontSize * 1.2
            let textSize = text.size()
            let badge = CGRect(
                x: margin,
                y: size.height - margin - textSize.height - padding * 2,
                width: textSize.width + padding * 2,
                height: textSize.height + padding * 1.6
            )
            UIColor.black.withAlphaComponent(0.72).setFill()
            UIBezierPath(roundedRect: badge, cornerRadius: fontSize * 0.45).fill()
            text.draw(at: CGPoint(x: badge.minX + padding, y: badge.minY + padding * 0.8))
        }
    }

    /// Renders the drawn viewfinder scene as a stand-in photo where there's no camera (the Simulator).
    static func renderPlaceholderPhoto(at date: Date, size: CGSize = CGSize(width: 900, height: 1200)) -> UIImage? {
        let renderer = ImageRenderer(content: WallScene().frame(width: size.width, height: size.height))
        renderer.scale = 1
        return renderer.uiImage.map { stamped($0, at: date) }
    }
}

/// Shows a stored photo, falling back to a neutral swatch if the file is missing.
struct PhotoThumbnail: View {
    var fileName: String?
    var seed: Int = 0

    var body: some View {
        if let fileName, let image = PhotoStore.image(named: fileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            PhotoSwatch(seed: seed)
        }
    }
}
