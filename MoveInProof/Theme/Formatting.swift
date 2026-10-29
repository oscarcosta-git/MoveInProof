import Foundation

extension Date {
    /// "Mon 26 Oct 2026"
    var longText: String { formatted(template: "EEE d MMM yyyy") }

    /// "19 Oct 2026"
    var shortText: String { formatted(template: "d MMM yyyy") }

    /// "Thu 22 Oct 2026 · 4:31 pm"
    var timestampText: String { "\(longText) · \(formatted(date: .omitted, time: .shortened))" }

    /// Whole days from today until this date, ignoring the time of day.
    var daysFromToday: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: self)).day ?? 0
    }

    private func formatted(template: String) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: self).replacingOccurrences(of: ",", with: "")
    }
}

extension Int {
    /// "1 photo", "3 photos"
    func counted(_ singular: String, _ plural: String? = nil) -> String {
        "\(self) \(self == 1 ? singular : (plural ?? singular + "s"))"
    }
}
