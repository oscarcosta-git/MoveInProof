import SwiftUI

struct IssueDetailView: View {
    @State private var viewModel: IssueDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isChangingSuggestion = false
    @State private var isConfirmingDelete = false

    init(viewModel: IssueDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var photo: Photo? { viewModel.photo }
    private var draft: IssueDraft { viewModel.draft }

    var body: some View {
        @Bindable var viewModel = viewModel
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
                    TimestampLabel(text: "Move-in · \((photo?.capturedAt ?? viewModel.issue.createdAt).timestampText)").padding(14)
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Where is it?", text: $viewModel.draft.title, axis: .vertical)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(viewModel.subtitle)
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textSecondary)
                }

                suggestionCard

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Severity")
                    SeverityPicker(selection: $viewModel.draft.severity)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Notes")
                    TextField("Describe the damage", text: $viewModel.draft.notes, axis: .vertical)
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
                if viewModel.save() { dismiss() }
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.background)
        }
        .confirmationDialog("Delete this issue?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete issue", role: .destructive) {
                if viewModel.delete() { dismiss() }
            }
        } message: {
            Text("Its photos stay in the room.")
        }
        .confirmationDialog("What kind of damage is it?", isPresented: $isChangingSuggestion, titleVisibility: .visible) {
            ForEach(SampleData.suggestionOptions, id: \.self) { option in
                Button(option.capitalized) { viewModel.changeKind(to: option) }
            }
        }
        .errorAlert($viewModel.errorMessage)
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: draft.isKindConfirmed ? "checkmark.circle.fill" : "sparkle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.isKindConfirmed ? "Marked as \(draft.kind)" : "Suggested: \(draft.kind)")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Theme.brandStrong)
                    Text("Found on this iPhone. Your photos stay on your device.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                if draft.isKindConfirmed {
                    Button("Change") { isChangingSuggestion = true }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.brandStrong)
                }
            }

            if !draft.isKindConfirmed {
                HStack(spacing: 14) {
                    Button("Confirm") { withAnimation { viewModel.confirmKind() } }
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
    NavigationStack {
        IssueDetailView(viewModel: AppDependencies.preview.issueDetailViewModel(for: AppStore.previewTenancy.sortedRooms[2].sortedIssues[0]))
    }
}
