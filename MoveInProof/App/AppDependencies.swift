import SwiftData
import SwiftUI

/// Composition root: builds the repositories once and hands out use cases and ViewModels.
/// Views get this from the environment and never touch SwiftData themselves.
@Observable
final class AppDependencies {
    @ObservationIgnored let tenancies: TenancyRepository
    @ObservationIgnored let inspections: InspectionRepository
    @ObservationIgnored let files: PhotoFileStorage
    @ObservationIgnored let reports: ReportRenderer

    init(tenancies: TenancyRepository, inspections: InspectionRepository, files: PhotoFileStorage, reports: ReportRenderer) {
        self.tenancies = tenancies
        self.inspections = inspections
        self.files = files
        self.reports = reports
    }

    convenience init(container: ModelContainer) {
        let context = container.mainContext
        self.init(
            tenancies: SwiftDataTenancyRepository(context: context),
            inspections: SwiftDataInspectionRepository(context: context),
            files: LocalPhotoFileStorage(),
            reports: PDFReportRenderer()
        )
    }

    /// Backed by the in-memory preview store.
    static let preview = AppDependencies(container: AppStore.preview)

    // MARK: ViewModels

    func rootViewModel() -> RootViewModel {
        RootViewModel(load: LoadTenancyUseCase(repository: tenancies))
    }

    func setupViewModel() -> SetupViewModel {
        SetupViewModel(createTenancy: CreateTenancyUseCase(repository: tenancies))
    }

    func homeViewModel(for tenancy: Tenancy) -> HomeViewModel {
        HomeViewModel(tenancy: tenancy, updateTenancy: UpdateTenancyUseCase(repository: tenancies))
    }

    func settingsViewModel(for tenancy: Tenancy) -> TenancySettingsViewModel {
        TenancySettingsViewModel(
            tenancy: tenancy,
            updateTenancy: UpdateTenancyUseCase(repository: tenancies),
            manageRooms: ManageRoomsUseCase(repository: tenancies, files: files),
            deleteAll: DeleteAllDataUseCase(repository: tenancies, files: files)
        )
    }

    func captureViewModel(for room: Room) -> CaptureViewModel {
        CaptureViewModel(
            room: room,
            capturePhoto: CapturePhotoUseCase(repository: inspections, files: files),
            completeRoom: CompleteRoomUseCase(repository: inspections)
        )
    }

    func roomDetailViewModel(for room: Room) -> RoomDetailViewModel {
        RoomDetailViewModel(
            room: room,
            flagIssue: FlagIssueUseCase(repository: inspections),
            deletePhoto: DeletePhotoUseCase(repository: inspections, files: files),
            completeRoom: CompleteRoomUseCase(repository: inspections)
        )
    }

    func issueDetailViewModel(for issue: Issue) -> IssueDetailViewModel {
        IssueDetailViewModel(issue: issue, updateIssue: UpdateIssueUseCase(repository: inspections))
    }

    func exportViewModel(for tenancy: Tenancy) -> ExportViewModel {
        ExportViewModel(tenancy: tenancy, exportReport: ExportReportUseCase(renderer: reports))
    }
}
