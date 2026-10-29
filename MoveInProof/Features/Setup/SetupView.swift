import SwiftData
import SwiftUI

/// First-run screen: enter the property, lease dates and rooms.
struct SetupView: View {
    @Environment(\.modelContext) private var context

    @State private var streetAddress = ""
    @State private var suburb = ""
    @State private var leaseStart = Calendar.current.startOfDay(for: .now)
    @State private var leaseEnd = Calendar.current.date(byAdding: DateComponents(year: 1, day: -1), to: Calendar.current.startOfDay(for: .now)) ?? .now
    @State private var reportDue = Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: .now)) ?? .now
    @State private var rooms = SampleData.defaultRoomNames.map { RoomDraft(name: $0) }
    @State private var newRoomName = ""

    private struct RoomDraft: Identifiable {
        let id = UUID()
        var name: String
        var isIncluded = true
    }

    private var canStart: Bool {
        !streetAddress.trimmingCharacters(in: .whitespaces).isEmpty && rooms.contains(where: \.isIncluded)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "house")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Theme.brand)
                            .frame(width: 54, height: 54)
                            .background(Theme.brandTint, in: .rect(cornerRadius: 14))
                        Text("Set up your tenancy")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Everything stays on this iPhone. You can change these details later.")
                            .font(.rowSubtitle)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
                }

                Section("Property") {
                    TextField("Street address", text: $streetAddress)
                        .textContentType(.streetAddressLine1)
                    TextField("Suburb, state and postcode", text: $suburb)
                        .textContentType(.addressCityAndState)
                }

                Section {
                    DatePicker("Lease starts", selection: $leaseStart, displayedComponents: .date)
                    DatePicker("Lease ends", selection: $leaseEnd, in: leaseStart..., displayedComponents: .date)
                    DatePicker("Condition report due", selection: $reportDue, in: leaseStart..., displayedComponents: .date)
                } header: {
                    Text("Lease")
                } footer: {
                    Text("The condition report is usually due about a week after you get the keys. Check your lease.")
                }

                Section {
                    ForEach($rooms) { $room in
                        Toggle(room.name, isOn: $room.isIncluded)
                    }
                    HStack {
                        TextField("Add a room", text: $newRoomName)
                            .onSubmit(addRoom)
                        Button("Add", action: addRoom)
                            .disabled(newRoomName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Rooms")
                } footer: {
                    Text("You'll photograph each room in this order.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                Button("Start move-in report", action: start)
                    .buttonStyle(.primary)
                    .disabled(!canStart)
                    .opacity(canStart ? 1 : 0.5)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.background)
            }
            .onChange(of: leaseStart) { _, start in
                reportDue = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
                leaseEnd = Calendar.current.date(byAdding: DateComponents(year: 1, day: -1), to: start) ?? start
            }
        }
        .tint(Theme.brand)
    }

    private func addRoom() {
        let name = newRoomName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        rooms.append(RoomDraft(name: name))
        newRoomName = ""
    }

    private func start() {
        let tenancy = Tenancy(
            streetAddress: streetAddress.trimmingCharacters(in: .whitespaces),
            suburb: suburb.trimmingCharacters(in: .whitespaces),
            leaseStart: leaseStart,
            leaseEnd: leaseEnd,
            reportDue: reportDue
        )
        context.insert(tenancy)
        for (index, draft) in rooms.filter(\.isIncluded).enumerated() {
            let room = Room(name: draft.name, order: index)
            context.insert(room)
            room.tenancy = tenancy
        }
        try? context.save()
    }
}

#Preview {
    SetupView()
        .modelContainer(for: Tenancy.self, inMemory: true)
}
