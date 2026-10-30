import SwiftUI

/// First-run screen: enter the property, lease dates and rooms.
struct SetupView: View {
    @State private var viewModel: SetupViewModel

    init(viewModel: SetupViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "house")
                            .scaledFont(22, weight: .medium)
                            .foregroundStyle(Theme.brand)
                            .frame(width: 54, height: 54)
                            .background(Theme.brandTint, in: .rect(cornerRadius: 14))
                        Text("Set up your tenancy")
                            .scaledFont(28, weight: .bold)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Everything stays on this iPhone. You can change these details later.")
                            .font(.rowSubtitle)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
                }

                Section("Property") {
                    TextField("Street address", text: $viewModel.streetAddress)
                        .textContentType(.streetAddressLine1)
                    TextField("Suburb, state and postcode", text: $viewModel.suburb)
                        .textContentType(.addressCityAndState)
                }

                Section {
                    DatePicker("Lease starts", selection: $viewModel.leaseStart, displayedComponents: .date)
                    DatePicker("Lease ends", selection: $viewModel.leaseEnd, in: viewModel.leaseStart..., displayedComponents: .date)
                    DatePicker("Condition report due", selection: $viewModel.reportDue, in: viewModel.leaseStart..., displayedComponents: .date)
                } header: {
                    Text("Lease")
                } footer: {
                    Text("The condition report is usually due about a week after you get the keys. Check your lease.")
                }

                Section {
                    ForEach($viewModel.rooms) { $room in
                        Toggle(room.name, isOn: $room.isIncluded)
                    }
                    HStack {
                        TextField("Add a room", text: $viewModel.newRoomName)
                            .onSubmit(viewModel.addRoom)
                        Button("Add", action: viewModel.addRoom)
                            .disabled(!viewModel.canAddRoom)
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
                Button("Start move-in report", action: viewModel.start)
                    .buttonStyle(.primary)
                    .disabled(!viewModel.canStart)
                    .opacity(viewModel.canStart ? 1 : 0.5)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.background)
            }
            .scrollDismissesKeyboard(.interactively)
            .errorAlert($viewModel.errorMessage)
        }
        .tint(Theme.brand)
    }
}

#Preview {
    SetupView(viewModel: AppDependencies.preview.setupViewModel())
}
