# MoveIn Proof

**Rental condition reports, proven on your iPhone.**

MoveIn Proof helps renters document a property's condition when they move in, so they can protect their bond when they move out. Walk each room, take date-stamped photos, flag existing damage, and export a professional condition report as a PDF. Everything stays on the device.

> 40005 Advanced iOS Applications - Assessment 4
> Oscar Costa - 25859366

## Features

- **Guided room-by-room capture** with the back camera. Every photo has its date and time burned into the image, so the timestamp survives sharing.
- **Flag damage as you shoot** (scuff, crack, stain and more), then add severity and notes.
- **Key dates at a glance**: condition report due date, move-out inspection and lease end.
- **PDF condition report** with a cover summary, each room's issues and a photo grid. Share it or save it to Files.
- **Home Screen widget** (WidgetKit) showing days until the report is due and the lease ends.
- **Private by design**: no account, no network, no analytics. Data stays in on-device SwiftData storage and photo files.
- Light and Dark Mode, Dynamic Type up to accessibility sizes, and graceful handling when camera access is denied.

## Requirements

- Built and tested with Xcode 27; iOS 18.0+ deployment target; Swift 6 language mode
- No third-party packages

## Build and run

1. Open `MoveInProof.xcodeproj`.
2. Choose the **MoveInProof** scheme and an iPhone Simulator.
3. Run (⌘R).

The Simulator has no camera, so capture falls back to a drawn placeholder scene that is still timestamped and saved like a real photo.

**Launch arguments for testing** (Scheme → Run → Arguments):

| Argument | Effect |
|---|---|
| `-resetData` | Wipes the tenancy, all records and photo files on launch |
| `-seedSampleData` | Fills an empty store with a sample tenancy (8 rooms, 47 photos, 3 issues) |

The widget shares data with the app through an App Group (`group.com.oscarcosta.MoveInProof`).

## Tests

Run with ⌘U, or:

```bash
xcodebuild test -project MoveInProof.xcodeproj -scheme MoveInProof -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

`MoveInProofTests` uses Swift Testing with mock repositories (`MoveInProofTests/Mocks.swift`). The 20 tests cover the domain use cases: lease and room validation rules, mapping storage failures to domain errors, cleaning up photo files when a save fails, creating issues from tagged photos, and export filtering.

## Architecture

MVVM with a Use Case layer and the Repository pattern. Views never touch SwiftData directly.

```
SwiftUI Views ──▶ @Observable ViewModels ──▶ Use Cases ──▶ Repository protocols
     ▲                    │                  (rules +            │
     └──── state ─────────┘                MoveInError)          ▼
                                                    SwiftData / files / PDF renderer
```

| Layer | Location | Contents |
|---|---|---|
| Presentation | `MoveInProof/Features/*/*View.swift`, `Components/`, `Theme/` | SwiftUI screens, reusable components, design tokens, Dynamic Type helper |
| ViewModels | `MoveInProof/Features/*/*ViewModel.swift`, `App/RootViewModel.swift` | `@Observable`, main-actor isolated; turn domain errors into user-facing messages |
| Domain | `MoveInProof/Domain/` | `@Model` entities (`Tenancy`, `Room`, `Photo`, `Issue`), `MoveInError`, repository protocols, use cases |
| Data | `MoveInProof/Data/` | SwiftData repositories, photo file storage, PDF renderer, widget sync |
| Composition | `MoveInProof/App/AppDependencies.swift` | Builds repositories once and creates each screen's ViewModel |
| Widget | `MoveInProofWidgets/`, `Shared/` | WidgetKit extension; `TenancySnapshot` is shared with the app via the App Group |

**Use cases:** `LoadTenancy`, `CreateTenancy`, `UpdateTenancy`, `ManageRooms`, `DeleteAllData`, `CapturePhoto`, `CompleteRoom`, `FlagIssue`, `UpdateIssue`, `DeletePhoto`, `ExportReport`.

**Data flow example (taking a photo):** `CaptureView` → `CaptureViewModel.takePhoto` → `CapturePhotoUseCase` writes the image through `PhotoFileStorage` and the record through `InspectionRepository` (and deletes the file if the record fails) → `SwiftDataInspectionRepository.saveChanges()` posts `.moveInStoreDidChange` → SwiftData's change tracking updates the views, and `WidgetSync` refreshes the widget.

## Apple frameworks used

SwiftUI, SwiftData, AVFoundation (camera), WidgetKit, UIKit (PDF rendering, share sheet), Observation, Swift Testing.

## Git workflow

- `main`: release-ready; changes arrive by pull request.
- `develop`: integration branch.
- Feature branches: `feat/…`, `fix/…`, `test/…`, `docs/…`
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`). Earlier commits on the original feature branches predate this convention.

## Privacy

- **No data is collected or leaves the device.** No accounts, analytics, tracking or network calls.
- **Camera** (`NSCameraUsageDescription`): photographs the condition of each room. If access is denied, the app explains how to turn it on in Settings.
- **Privacy manifests** (`PrivacyInfo.xcprivacy` in the app and the widget) declare no tracking and no collected data. They list one required-reason API: `UserDefaults` (reason `1C8F.1`) for the App Group shared with the widget.

## AI assistance declaration

Claude Code (Anthropic) was used as a coding assistant for implementation, refactoring, unit tests and debugging. All code was reviewed and tested, and I remain accountable for everything submitted.

## Author

Oscar Costa - 25859366 - [oscarcosta-git](https://github.com/oscarcosta-git)
