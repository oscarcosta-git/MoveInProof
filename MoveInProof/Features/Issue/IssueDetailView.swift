import SwiftData
import SwiftUI

struct IssueDetailView: View {
    @Bindable var issue: Issue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var isChangingSuggestion = false
    @State private var isConfirmingDelete = false

    private var photo: Photo? { issue.sortedPhotos.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    if let photo {
                        Color.clear.overlay { PhotoThumbnail(fileName: photo.fileName) }
                    } else {
                        BenchtopPhoto(flagExisting: true)
                    }
                }
                .frame(height: 220)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(alignment: .bottomLeading) {
                    TimestampLabel(text: "Move-in · \((photo?.capturedAt ?? issue.createdAt).timestampText)").padding(14)
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Where is it?", text: $issue.title, axis: .vertical)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(issue.room?.name ?? "") · \(issue.photos.count.counted("photo"))")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textSecondary)
                }

                suggestionCard

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Severity")
                    SeverityPicker(selection: $issue.severity)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Notes")
                    TextField("Describe the damage", text: $issue.notes, axis: .vertical)
                        .lineLimit(3...8)
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textPrimary)
                        .card(padding: 18)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Delete", role: .destructive) { isConfirmingDelete = true }
                    .tint(Theme.danger)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Save issue") {
                try? context.save()
                dismiss()
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.background)
        }
        .confirmationDialog("Delete this issue?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete issue", role: .destructive) {
                dismiss()
                context.delete(issue)
                try? context.save()
            }
        } message: {
            Text("Its photos stay in the room.")
        }
        .confirmationDialog("What kind of damage is it?", isPresented: $isChangingSuggestion, titleVisibility: .visible) {
            ForEach(SampleData.suggestionOptions, id: \.self) { option in
                Button(option.capitalized) {
                    issue.suggestion = option
                    issue.isSuggestionConfirmed = true
                }
            }
        }
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: issue.isSuggestionConfirmed ? "checkmark.circle.fill" : "sparkle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.isSuggestionConfirmed ? "Marked as \(issue.suggestion)" : "Suggested: \(issue.suggestion)")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Theme.brandStrong)
                    Text("Found on this iPhone. Your photos stay on your device.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                if issue.isSuggestionConfirmed {
                    Button("Change") { isChangingSuggestion = true }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.brandStrong)
                }
            }

            if !issue.isSuggestionConfirmed {
                HStack(spacing: 14) {
                    Button("Confirm") { withAnimation { issue.isSuggestionConfirmed = true } }
                        .buttonStyle(.primary)
                    Button("Change") { isChangingSuggestion = true }
                        .buttonStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(Theme.brandTint, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.brand.opacity(0.25), lineWidth: 1))
    }
}

private struct SeverityPicker: View {
    @Binding var selection: Severity
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Severity.allCases) { level in
                let isSelected = selection == level
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = level }
                } label: {
                    Text(level.rawValue)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.surface)
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.surfaceSunken, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { IssueDetailView(issue: AppStore.previewTenancy.sortedRooms[2].sortedIssues[0]) }
        .modelContainer(AppStore.preview)
}
