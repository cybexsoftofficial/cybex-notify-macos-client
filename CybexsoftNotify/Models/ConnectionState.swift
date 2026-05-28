import Foundation

enum ConnectionState: Equatable {
    case idle
    case connecting
    case connected
    case failed(String)

    var label: String {
        switch self {
        case .idle:            return "Disconnected"
        case .connecting:      return "Connecting…"
        case .connected:       return "Connected"
        case .failed(let msg): return "Error: \(msg)"
        }
    }

    var sfSymbol: String {
        switch self {
        case .connected:  return "checkmark.circle.fill"
        case .connecting: return "arrow.clockwise"
        case .failed:     return "exclamationmark.triangle.fill"
        case .idle:       return "circle"
        }
    }
}
