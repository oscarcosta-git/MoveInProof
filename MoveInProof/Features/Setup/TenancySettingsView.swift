import SwiftData
import SwiftUI

/// Edit the tenancy details and rooms, or wipe everything and start again.
struct TenancySettingsView: View {
    @Bindable var tenancy: Tenancy

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var newRoomName = ""
    @State private var isConfirmingDeleteAll = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Street address", text: $tenancy.streetAddress)
                    TextField("Suburb, state and postcode", text: $tenancy.suburb)
                }

                Section("Lease") {
                    DatePicker("Lease starts", selection: $tenancy.leaseStart, displayedComponents: .date)
                    DatePicker("Lease ends", selection: $tenancy.leaseEnd, in: tenancy.leaseStart..., displayedComponents: .date)
                    DatePicker("Condition report due", selection: $tenancy.reportDue, displayedComponents: .date)
                }

                Section {
                    ForEach(tenancy.sortedRooms) { room in
                        LabeledContent(room.name, value: room.photos.count.counted("photo"))
                    }
                    .onDelete(perform: deleteRooms)
                    .onMove(perform: moveRooms)
                    HStack {
                        TextField("Add a room", text: $newRoomName)
                            .onSubmit(addRoom)
                        Button("Add", action: addRoom)
                            .disabled(newRoomName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    HStack {
                        Text("Rooms")
                        Spacer()
                        EditButton().font(.footnote.weight(.semibold)).textCase(nil)
                    }
                } footer: {
                    Text("Deleting a room also deletes its photos and issues.")
                }

                Section {
                    Button("Delete all data", role: .destructive) { isConfirmingDeleteAll = true }
                } footer: {
                    Text("Removes this tenancy, every photo and every issue from this iPhone.")
                }
            }
            .navigationTitle("Tenancy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete all data?", isPresented: $isConfirmingDeleteAll, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive, action: deleteAll)
            } message: {
                Text("This can't be undone.")
            }
        }
        .tint(Theme.brand)
    }

    private func addRoom() {
        let name = newRoomName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let room = Room(name: name, order: (tenancy.rooms.map(\.order).max() ?? -1) + 1)
        context.insert(room)
        room.tenancy = tenancy
        newRoomName = ""
    }

    private func deleteRooms(at offsets: IndexSet) {
        let rooms = tenancy.sortedRooms
        for index in offsets {
            for photo in rooms[index].photos {
                PhotoStore.delete(photo, in: context)
            }
            context.delete(rooms[index])
        }
    }

    private func moveRooms(from source: IndexSet, to destination: Int) {
        var rooms = tenancy.sortedRooms
        rooms.move(fromOffsets: source, toOffset: destination)
        for (index, room) in rooms.enumerated() {
            room.order = index
        }
    }

    private func deleteAll() {
        dismiss()
        PhotoStore.deleteAllFiles()
        context.delete(tenancy)
        try? context.save()
    }
}

#Preview {
    TenancySettingsView(tenancy: AppStore.previewTenancy)
        .modelContainer(AppStore.preview)
}
