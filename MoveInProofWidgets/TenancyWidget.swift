import SwiftUI
import WidgetKit

// MARK: - Timeline

struct TenancyEntry: TimelineEntry {
    var date: Date
    var reportDue: Date
    var leaseEnds: Date
    var moveOutInspection: Date?
    var issuesFlagged: Int

    var reportDaysLeft: Int { daysBetween(date, reportDue) }
    var leaseDaysLeft: Int { daysBetween(date, leaseEnds) }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
        return max(days, 0)
    }

    /// Placeholder tenancy matching the mockups.
    /// TODO: Read the real tenancy from an App Group shared with the app.
    static func sample(at date: Date = .now) -> TenancyEntry {
        let calendar = Calendar.current
        return TenancyEntry(
            date: date,
            reportDue: calendar.date(from: DateComponents(year: 2026, month: 10, day: 26)) ?? date,
            leaseEnds: calendar.date(from: DateComponents(year: 2027, month: 10, day: 18)) ?? date,
            moveOutInspection: nil,
            issuesFlagged: 3
        )
    }
}

struct TenancyProvider: TimelineProvider {
    func placeholder(in context: Context) -> TenancyEntry {
        .sample()
    }

    func getSnapshot(in context: Context, completion: @escaping (TenancyEntry) -> Void) {
        completion(.sample())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TenancyEntry>) -> Void) {
        // Day counts only change at midnight, so refresh then.
        let now = Date.now
        let nextMidnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [.sample(at: now)], policy: .after(nextMidnight)))
    }
}

// MARK: - Widget

struct TenancyWidget: Widget {
    let kind = "TenancyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TenancyProvider()) { entry in
            TenancyWidgetView(entry: entry)
                .containerBackground(WidgetTheme.background, for: .widget)
        }
        .configurationDisplayName("Tenancy dates")
        .description("Days until your condition report is due and your lease ends.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TenancyWidgetView: View {
    var entry: TenancyEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: LeaseWidgetView(entry: entry)
        default: ReportDueWidgetView(entry: entry)
        }
    }
}

// MARK: - Small: report due

private struct ReportDueWidgetView: View {
    var entry: TenancyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "house")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(WidgetTheme.brand, in: .rect(cornerRadius: 7))
                Text("Report due")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }

            Spacer(minLength: 0)

            Text("\(entry.reportDaysLeft)")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(WidgetTheme.warning)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(entry.reportDaysLeft == 1 ? "day left" : "days left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(WidgetTheme.textPrimary)

            Spacer(minLength: 4)

            Text(entry.reportDue.widgetFormatted(includeYear: true))
                .font(.system(size: 14))
                .foregroundStyle(WidgetTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Medium: lease ends + summary

private struct LeaseWidgetView: View {
    var entry: TenancyEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Lease ends")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textSecondary)
                Spacer(minLength: 0)
                Text("\(entry.leaseDaysLeft)")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(WidgetTheme.brandStrong)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text(entry.leaseDaysLeft == 1 ? "day left" : "days left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textPrimary)
                Spacer(minLength: 4)
                Text(entry.leaseEnds.widgetFormatted(includeYear: true))
                    .font(.system(size: 14))
                    .foregroundStyle(WidgetTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            Rectangle()
                .fill(WidgetTheme.divider)
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 0) {
                SummaryItem(label: "Report due", value: entry.reportDue.widgetFormatted(includeYear: false), valueColor: WidgetTheme.warning)
                Spacer(minLength: 4)
                SummaryItem(label: "Move-out inspection", value: entry.moveOutInspection?.widgetFormatted(includeYear: false) ?? "Not booked")
                Spacer(minLength: 4)
                SummaryItem(label: "Issues flagged", value: "\(entry.issuesFlagged)")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private struct SummaryItem: View {
    var label: String
    var value: String
    var valueColor: Color = WidgetTheme.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(WidgetTheme.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private extension Date {
    /// "Mon 26 Oct 2026", or "Mon 26 Oct" without the year.
    func widgetFormatted(includeYear: Bool) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(includeYear ? "EEE d MMM yyyy" : "EEE d MMM")
        return formatter.string(from: self).replacingOccurrences(of: ",", with: "")
    }
}

// MARK: - Previews

#Preview("Report due", as: .systemSmall) {
    TenancyWidget()
} timeline: {
    TenancyEntry.sample()
}

#Preview("Lease ends", as: .systemMedium) {
    TenancyWidget()
} timeline: {
    TenancyEntry.sample()
}
