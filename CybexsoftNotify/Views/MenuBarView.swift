import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var coordinator: ConnectionCoordinator

    var body: some View {
        if coordinator.managers.isEmpty {
            Text("No accounts — open Settings to add one")
                .foregroundColor(.secondary)
        } else {
            ForEach(coordinator.managers) { manager in
                statusRow(for: manager)
            }
        }

        Divider()

        Button("Settings…") {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit CybexsoftNotify") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    @ViewBuilder
    private func statusRow(for manager: AccountManager) -> some View {
        let name = manager.account.label.isEmpty
            ? (URL(string: manager.account.serverUrl)?.host ?? manager.account.serverUrl)
            : manager.account.label

        Label {
            Text("\(name) — \(manager.state.label)")
        } icon: {
            Image(systemName: manager.state.sfSymbol)
                .foregroundColor(color(for: manager.state))
        }
    }

    private func color(for state: ConnectionState) -> Color {
        switch state {
        case .connected:  return .green
        case .connecting: return .yellow
        case .failed:     return .red
        case .idle:       return .secondary
        }
    }
}
