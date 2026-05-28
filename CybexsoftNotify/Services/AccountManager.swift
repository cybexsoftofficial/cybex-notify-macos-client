import Foundation

class AccountManager: NSObject, ObservableObject, Identifiable {
    let id: UUID
    let account: AccountSettings

    @Published private(set) var state: ConnectionState = .idle

    var onNotification: ((String, String, String, String) -> Void)?

    private var task: URLSessionWebSocketTask?
    private var reconnectTimer: Timer?
    private var reconnectDelay: TimeInterval = 2.0
    private var active = false

    init(account: AccountSettings) {
        self.id = account.id
        self.account = account
    }

    // MARK: - Public

    func connect() {
        active = true
        reconnectDelay = 2.0
        performConnect()
    }

    func disconnect() {
        active = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        state = .idle
    }

    // MARK: - Private

    private func performConnect() {
        guard active else { return }
        guard !account.serverUrl.isEmpty, !account.deviceToken.isEmpty else {
            state = .failed("Missing server URL or device token")
            return
        }

        guard var comps = URLComponents(string: account.serverUrl) else {
            state = .failed("Invalid server URL")
            return
        }
        if comps.scheme == "http"  { comps.scheme = "ws" }
        if comps.scheme == "https" { comps.scheme = "wss" }
        guard let url = comps.url else {
            state = .failed("Could not build URL")
            return
        }

        state = .connecting

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        // Delegate queue = main so all callbacks (receive + delegate) run on main thread
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        task = session.webSocketTask(with: url)
        task?.resume()

        sendAuth()
        listen()
    }

    private func sendAuth() {
        let msg: [String: Any] = [
            "type":        "auth",
            "deviceId":    account.deviceId,
            "deviceToken": account.deviceToken
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: msg),
              let str  = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(str)) { _ in }
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self, self.active else { return }
            switch result {
            case .success(let message):
                self.reconnectDelay = 2.0
                self.state = .connected
                self.handle(message)
                self.listen()
            case .failure(let error):
                self.state = .failed(error.localizedDescription)
                self.scheduleReconnect()
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let raw: Data?
        switch message {
        case .string(let s): raw = s.data(using: .utf8)
        case .data(let d):   raw = d
        @unknown default:    return
        }

        guard let raw,
              let json  = try? JSONSerialization.jsonObject(with: raw) as? [String: Any],
              let type  = json["type"] as? String else { return }

        switch type {
        case "notification":
            let title    = json["title"]    as? String ?? ""
            let body     = json["message"]  as? String ?? json["body"] as? String ?? ""
            let priority = json["priority"] as? String ?? "info"
            let name     = account.label.isEmpty
                ? (URL(string: account.serverUrl)?.host ?? account.serverUrl)
                : account.label
            onNotification?(title, body, priority, name)

        case "auth_success":
            state = .connected

        case "auth_error", "error":
            let msg = json["message"] as? String ?? "Authentication failed"
            state = .failed(msg)
            active = false

        default:
            break
        }
    }

    private func scheduleReconnect() {
        guard active else { return }
        let delay = reconnectDelay
        reconnectDelay = min(reconnectDelay * 2, 60)

        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.task = nil
            self?.performConnect()
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension AccountManager: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        reconnectDelay = 2.0
        state = .connected
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        guard active else { return }
        state = .failed("Connection closed (\(closeCode.rawValue))")
        scheduleReconnect()
    }
}

// MARK: - URLSessionTaskDelegate

extension AccountManager: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, active else { return }
        state = .failed(error.localizedDescription)
        scheduleReconnect()
    }
}
