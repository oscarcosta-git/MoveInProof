import SwiftUI

struct IssueDetailView: View {
    @State private var viewModel: IssueDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isChangingType = false
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
                        Theme.surfaceSunken.overlay {
                            Label("No photo", systemImage: "photo")
                                .scaledFont(15, weight: .semibold)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(.rect(cornerRadius: 20))
                .overlay(alignment: .bottomLeading) {
                    TimestampLabel(text: "Move-in · \((photo?.capturedAt ?? viewModel.issue.createdAt).timestampText)").padding(14)
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Where is it?", text: $viewModel.draft.title, axis: .vertical)
                        .scaledFont(26, weight: .bold)
                        .foregroundStyle(Theme.textPrimary)
                    Text(viewModel.subtitle)
                        .scaledFont(17)
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Damage type")
                    damageTypeRow
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Severity")
                    SeverityPicker(selection: $viewModel.draft.severity)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Notes")
                    TextField("Describe the damage", text: $viewModel.draft.notes, axis: .vertical)
                        .lineLimit(3...8)
                        .scaledFont(17)
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
        .confirmationDialog("What kind of damage is it?", isPresented: $isChangingType, titleVisibility: .visible) {
            ForEach(SampleData.damageTypes, id: \.self) { option in
                Button(option.capitalized) { viewModel.changeKind(to: option) }
            }
        }
        .errorAlert($viewModel.errorMessage)
    }

    /// The damage type the tenant tagged. Tap to change it.
    private var damageTypeRow: some View {
        Button { isChangingType = true } label: {
            HStack(spacing: 12) {
                Text(Issue.displayName(forType: draft.kind))
                    .scaledFont(17, weight: .semibold)
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 8)
                Text("Change")
                    .scaledFont(15, weight: .semibold)
                    .foregroundStyle(Theme.brandStrong)
                Image(systemName: "chevron.up.chevron.down")
                    .scaledFont(13, weight: .semibold)
                    .foregroundStyle(Theme.brandStrong)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .card()
        .accessibilityLabel("Damage type: \(Issue.displayName(forType: draft.kind))")
        .accessibilityHint("Changes the type of damage")
    }
}

private struct SeverityPicker: View {
    @Binding var selection: Severity
    @Namespace private var namespace
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // Side by side normally; stacked at accessibility text sizes so the labels never break mid-word.
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
        layout {
            ForEach(Severity.allCases) { level in
                let isSelected = selection == level
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = level }
                } label: {
                    Text(level.rawValue)
                        .scaledFont(17, weight: .semibold)
                        .lineLimit(1)
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
