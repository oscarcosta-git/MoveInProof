import SwiftData
import SwiftUI

/// Builds the SwiftData container the app and previews use.
enum AppStore {
    static let schema = Schema([Tenancy.self, Room.self, Photo.self, Issue.self])

    /// The on-device store. Launch arguments help with testing:
    /// `-resetData` wipes everything, `-seedSampleData` fills an empty store with the mockup tenancy.
    static func makeContainer() -> ModelContainer {
        let arguments = ProcessInfo.processInfo.arguments
        do {
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema))
            let context = container.mainContext
            if arguments.contains("-resetData") {
                try context.delete(model: Tenancy.self)
                try context.save()
                PhotoStore.deleteAllFiles()
            }
            if arguments.contains("-seedSampleData"), try context.fetchCount(FetchDescriptor<Tenancy>()) == 0 {
                SampleData.seed(into: context)
                try context.save()
            }
            return container
        } catch {
            fatalError("Couldn't open the on-device store: \(error)")
        }
    }

    /// In-memory store with the sample tenancy, for SwiftUI previews.
    static let preview: ModelContainer = {
        do {
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            SampleData.seed(into: container.mainContext, withPhotoFiles: false)
            return container
        } catch {
            fatalError("Couldn't create the preview store: \(error)")
        }
    }()

    static var previewTenancy: Tenancy {
        (try? preview.mainContext.fetch(FetchDescriptor<Tenancy>()).first) ?? SampleData.seed(into: preview.mainContext, withPhotoFiles: false)
    }
}
