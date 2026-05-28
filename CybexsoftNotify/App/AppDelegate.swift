import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = ConnectionCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("[Notify] Notification permission error: \(error)") }
        }

        coordinator.reconnectAll()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSettingsChanged),
            name: .settingsChanged,
            object: nil
        )
    }

    @objc private func onSettingsChanged() {
        DispatchQueue.main.async { self.coordinator.reconnectAll() }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("com.cybexsoft.notify.settingsChanged")
}
