import SwiftUI

/// Edit the tenancy details and rooms, or wipe everything and start again.
struct TenancySettingsView: View {
    @State private var viewModel: TenancySettingsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDeleteAll = false

    init(viewModel: TenancySettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Street address", text: $viewModel.streetAddress)
                    TextField("Suburb, state and postcode", text: $viewModel.suburb)
                }

                Section("Lease") {
                    DatePicker("Lease starts", selection: $viewModel.leaseStart, displayedComponents: .date)
                    DatePicker("Lease ends", selection: $viewModel.leaseEnd, in: viewModel.leaseStart..., displayedComponents: .date)
                    DatePicker("Condition report due", selection: $viewModel.reportDue, displayedComponents: .date)
                }

                Section {
                    ForEach(viewModel.rooms) { room in
                        LabeledContent(room.name, value: room.photos.count.counted("photo"))
                    }
                    .onDelete(perform: viewModel.deleteRooms)
                    .onMove(perform: viewModel.moveRooms)
                    HStack {
                        TextField("Add a room", text: $viewModel.newRoomName)
                            .onSubmit(viewModel.addRoom)
                        Button("Add", action: viewModel.addRoom)
                            .disabled(!viewModel.canAddRoom)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if viewModel.save() { dismiss() }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .errorAlert($viewModel.errorMessage)
            .confirmationDialog("Delete all data?", isPresented: $isConfirmingDeleteAll, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    if viewModel.deleteAll() { dismiss() }
                }
            } message: {
                Text("This can't be undone.")
            }
        }
        .tint(Theme.brand)
    }
}

#Preview {
    TenancySettingsView(viewModel: AppDependencies.preview.settingsViewModel(for: AppStore.previewTenancy))
}
