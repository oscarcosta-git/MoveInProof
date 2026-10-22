import SwiftUI

struct CompareView: View {
    @State private var selectedRoom = "Kitchen"

    // Rooms with flagged issues first, since that's where disputes happen.
    private let roomNames = SampleData.rooms
        .filter { $0.status == .done }
        .sorted { $0.issues.count > $1.issues.count }
        .map(\.name)
    private var comparison: RoomComparison { SampleData.comparison(for: selectedRoom) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(title: "Compare", subtitle: "\(selectedRoom) · Move-in vs move-out")
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(roomNames, id: \.self) { name in
                            FilterChip(title: name, isSelected: name == selectedRoom) {
                                withAnimation { selectedRoom = name }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top, spacing: 12) {
                        ComparePhoto(title: "Move-in", date: comparison.moveInDate, showNewDamage: false)
                        ComparePhoto(title: "Move-out", date: comparison.moveOutDate, showNewDamage: comparison.count(.new) > 0)
                    }

                    HStack(spacing: 12) {
                        StatTile(value: comparison.count(.existing), label: "Existing", tone: .brand)
                        StatTile(value: comparison.count(.new), label: "New", tone: .danger)
                        StatTile(value: comparison.unchangedCount, label: "No change", tone: .neutral)
                    }

                    DividedStack {
                        ForEach(comparison.items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.rowTitle)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(item.detail)
                                        .font(.rowSubtitle)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Pill(text: item.status.rawValue, tone: item.status.tone)
                            }
                            .padding(.horizontal, 20)
                            .frame(minHeight: 76)
                        }
                    }
                    .card()
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ComparePhoto: View {
    var title: String
    var date: String
    var showNewDamage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            BenchtopPhoto(showNewDamage: showNewDamage)
                .aspectRatio(1.2, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 18))
                .padding(.bottom, 8)
            Text(title)
                .font(.rowTitle)
                .foregroundStyle(Theme.textPrimary)
            Text(date)
                .font(.rowSubtitle)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatTile: View {
    var value: Int
    var label: String
    var tone: PillTone

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 30, weight: .bold))
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(tone.foreground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(tone.background, in: .rect(cornerRadius: 16))
    }
}

private extension CompareStatus {
    var tone: PillTone {
        switch self {
        case .existing: .brand
        case .new: .danger
        case .noChange: .neutral
        }
    }
}

#Preview {
    NavigationStack { CompareView() }
}
