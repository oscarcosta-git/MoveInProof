import SwiftData
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

    /// Deletes the record and its file.
    static func delete(_ photo: Photo, in context: ModelContext) {
        try? FileManager.default.removeItem(at: url(for: photo.fileName))
        context.delete(photo)
    }

    static func deleteAllFiles() {
        try? FileManager.default.removeItem(at: directory)
    }

    /// Renders the drawn viewfinder scene as a stand-in photo until real camera capture exists.
    static func renderPlaceholderPhoto(at date: Date, size: CGSize = CGSize(width: 900, height: 1200)) -> UIImage? {
        let content = WallScene()
            .overlay(alignment: .bottomLeading) {
                TimestampLabel(text: date.timestampText)
                    .scaleEffect(2, anchor: .bottomLeading)
                    .padding(32)
            }
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        return renderer.uiImage
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
