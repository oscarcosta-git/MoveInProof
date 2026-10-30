import Foundation
import Observation

/// Edits a copy of the issue; nothing is stored until Save.
@Observable
final class IssueDetailViewModel {
    let issue: Issue
    var draft: IssueDraft
    var errorMessage: String?

    @ObservationIgnored private let updateIssue: UpdateIssueUseCase

    init(issue: Issue, updateIssue: UpdateIssueUseCase) {
        self.issue = issue
        self.updateIssue = updateIssue
        draft = IssueDraft(
            title: issue.title,
            kind: issue.suggestion,
            severity: issue.severity,
            notes: issue.notes
        )
    }

    var photo: Photo? { issue.sortedPhotos.first }
    var subtitle: String { "\(issue.room?.name ?? "") · \(issue.photos.count.counted("photo"))" }

    func changeKind(to kind: String) {
        draft.kind = kind
    }

    /// Returns false, with an error message, if the edits are invalid or couldn't be saved.
    func save() -> Bool {
        do {
            try updateIssue.execute(issue, with: draft)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete() -> Bool {
        do {
            try updateIssue.delete(issue)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
