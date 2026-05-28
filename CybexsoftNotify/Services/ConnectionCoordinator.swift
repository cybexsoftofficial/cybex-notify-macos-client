import Foundation
import UserNotifications

class ConnectionCoordinator: ObservableObject {
    @Published private(set) var managers: [AccountManager] = []

    func reconnectAll() {
        managers.forEach { $0.disconnect() }
        managers.removeAll()

        let settings = SettingsService.shared.load()
        for account in settings.accounts where account.enabled && !account.deviceToken.isEmpty {
            let manager = AccountManager(account: account)
            manager.onNotification = { title, body, priority, accountName in
                Self.post(title: title, body: body, priority: priority, subtitle: accountName)
            }
            manager.connect()
            managers.append(manager)
        }
    }

    private static func post(title: String, body: String, priority: String, subtitle: String) {
        let content         = UNMutableNotificationContent()
        content.title       = title
        content.body        = body
        content.subtitle    = subtitle

        switch priority {
        case "critical":
            content.sound = .defaultCritical
            if #available(macOS 12.0, *) { content.interruptionLevel = .critical }
        case "warning":
            content.sound = .default
            if #available(macOS 12.0, *) { content.interruptionLevel = .timeSensitive }
        default:
            content.sound = .default
        }

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
}
