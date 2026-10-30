import Foundation
import Observation

@Observable
final class ExportViewModel {
    let tenancy: Tenancy
    var options = ReportOptions()
    private(set) var isGenerating = false
    var errorMessage: String?

    @ObservationIgnored private let exportReport: ExportReportUseCase

    init(tenancy: Tenancy, exportReport: ExportReportUseCase) {
        self.tenancy = tenancy
        self.exportReport = exportReport
    }

    var includedRooms: [Room] { exportReport.rooms(in: tenancy, options: options) }
    var includedPhotoCount: Int { includedRooms.reduce(0) { $0 + $1.photos.count } }
    var canExport: Bool { !includedRooms.isEmpty && !isGenerating }

    var summary: String {
        // Estimated from the PDF layout: a cover page, then each room starts a page that fits
        // about nine photos, at roughly 15 KB per photo once downsized.
        let roomPages = includedRooms.reduce(0) { total, room in
            total + (options.includePhotos ? max(1, (room.photos.count + 3 + 8) / 9) : 1)
        }
        let pages = 1 + roomPages
        let bytes = Int64(10_000 * pages + (options.includePhotos ? 15_000 * includedPhotoCount : 0))
        return "\(tenancy.streetAddress) · about \(pages.counted("page")) · \(bytes.formatted(.byteCount(style: .file)))"
    }

    /// Builds the PDF and returns its file, or nil with an error message.
    func generate() async -> URL? {
        isGenerating = true
        defer { isGenerating = false }
        // Let the button show its spinner before the main thread is busy drawing.
        await Task.yield()
        do {
            return try exportReport.execute(tenancy, options: options)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
