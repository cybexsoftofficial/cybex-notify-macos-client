import Foundation

struct AccountSettings: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var label: String = ""
    var serverUrl: String = "ws://localhost:8080/ws"
    var deviceId: String = ""
    var deviceToken: String = ""
    var enabled: Bool = true
}

struct AppSettings: Codable {
    var accounts: [AccountSettings] = []
}
