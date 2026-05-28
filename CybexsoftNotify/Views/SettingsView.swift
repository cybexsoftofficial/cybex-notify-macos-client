import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var coordinator: ConnectionCoordinator
    @State private var settings: AppSettings = SettingsService.shared.load()
    @State private var selectedId: UUID?

    var body: some View {
        HSplitView {
            accountList
            detailPane
        }
        .frame(minWidth: 600, minHeight: 380)
        .onAppear {
            settings   = SettingsService.shared.load()
            selectedId = settings.accounts.first?.id
        }
    }

    // MARK: - Account list

    private var accountList: some View {
        VStack(spacing: 0) {
            List(selection: $selectedId) {
                ForEach(settings.accounts) { account in
                    accountRow(account)
                        .tag(account.id)
                }
            }
            .listStyle(.inset)

            Divider()

            HStack(spacing: 0) {
                Button { addAccount() } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless)
                    .frame(width: 28, height: 28)

                Button { removeSelected() } label: { Image(systemName: "minus") }
                    .buttonStyle(.borderless)
                    .frame(width: 28, height: 28)
                    .disabled(selectedId == nil)

                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .frame(minWidth: 200, idealWidth: 220, maxWidth: 260)
    }

    @ViewBuilder
    private func accountRow(_ account: AccountSettings) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(account.enabled ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 7, height: 7)
            Text(account.label.isEmpty ? account.serverUrl : account.label)
                .lineLimit(1)
        }
    }

    // MARK: - Detail pane

    @ViewBuilder
    private var detailPane: some View {
        if let idx = selectedIndex {
            AccountDetailView(
                account: $settings.accounts[idx],
                onSave: save
            )
            .id(settings.accounts[idx].id)
            .frame(minWidth: 340)
        } else {
            Text("Select an account or add one")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Helpers

    private var selectedIndex: Int? {
        guard let id = selectedId else { return nil }
        return settings.accounts.firstIndex(where: { $0.id == id })
    }

    private func addAccount() {
        let new = AccountSettings()
        settings.accounts.append(new)
        selectedId = new.id
        save()
    }

    private func removeSelected() {
        guard let id = selectedId else { return }
        settings.accounts.removeAll { $0.id == id }
        selectedId = settings.accounts.first?.id
        save()
    }

    private func save() {
        SettingsService.shared.save(settings)
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
}

// MARK: - AccountDetailView

struct AccountDetailView: View {
    @Binding var account: AccountSettings
    let onSave: () -> Void

    @State private var showToken = false

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Account Name") {
                    TextField("e.g. Production Server", text: $account.label)
                }
                LabeledContent("Enabled") {
                    Toggle("", isOn: $account.enabled)
                }
            }

            Section("Connection") {
                LabeledContent("Server URL") {
                    TextField("ws://your-server:8080/ws", text: $account.serverUrl)
                        .help("Use ws:// for plain or wss:// for TLS")
                }
                LabeledContent("Device ID") {
                    TextField("Device ID from server", text: $account.deviceId)
                }
            }

            Section("Authentication") {
                LabeledContent("Device Token") {
                    HStack {
                        if showToken {
                            TextField("Token", text: $account.deviceToken)
                        } else {
                            SecureField("Token", text: $account.deviceToken)
                        }
                        Button {
                            showToken.toggle()
                        } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Save") { onSave() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.top, 4)
        }
        .formStyle(.grouped)
        .padding()
    }
}
