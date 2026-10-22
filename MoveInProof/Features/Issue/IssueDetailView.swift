import SwiftUI

struct IssueDetailView: View {
    var issue: Issue

    @Environment(\.dismiss) private var dismiss
    @State private var severity: Severity
    @State private var notes: String
    @State private var suggestion: String
    @State private var isSuggestionConfirmed = false
    @State private var isChangingSuggestion = false
    @State private var isConfirmingDelete = false

    private let suggestionOptions = ["chip or scratch", "scuff", "crack", "stain", "dent", "wear and tear"]

    init(issue: Issue) {
        self.issue = issue
        _severity = State(initialValue: issue.severity)
        _notes = State(initialValue: issue.notes)
        _suggestion = State(initialValue: issue.suggestion)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BenchtopPhoto(flagExisting: true)
                    .frame(height: 220)
                    .clipShape(.rect(cornerRadius: 20))
                    .overlay(alignment: .bottomLeading) {
                        TimestampLabel(text: issue.capturedAt).padding(14)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(issue.roomName) · \(issue.photoCount) photos")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textSecondary)
                }

                suggestionCard

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Severity")
                    SeverityPicker(selection: $severity)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Notes")
                    TextField("Describe the damage", text: $notes, axis: .vertical)
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
            Button("Save issue") { dismiss() }
                .buttonStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.background)
        }
        .confirmationDialog("Delete this issue?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete issue", role: .destructive) { dismiss() }
        } message: {
            Text("Its photos stay in the room.")
        }
        .confirmationDialog("What kind of damage is it?", isPresented: $isChangingSuggestion, titleVisibility: .visible) {
            ForEach(suggestionOptions, id: \.self) { option in
                Button(option.capitalized) {
                    suggestion = option
                    isSuggestionConfirmed = true
                }
            }
        }
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isSuggestionConfirmed ? "checkmark.circle.fill" : "sparkle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                VStack(alignment: .leading, spacing: 4) {
                    Text(isSuggestionConfirmed ? "Marked as \(suggestion)" : "Suggested: \(suggestion)")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Theme.brandStrong)
                    Text("Found on this iPhone. Your photos stay on your device.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            if !isSuggestionConfirmed {
                HStack(spacing: 14) {
                    Button("Confirm") { withAnimation { isSuggestionConfirmed = true } }
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
    NavigationStack { IssueDetailView(issue: SampleData.benchtopChip) }
}
