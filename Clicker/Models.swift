import Observation
import SwiftData
import Foundation

enum InputKey: Hashable {
    case mouse(Int)
    case keyboard(title: String, code: Int)

    var stringValue: String {
        switch self {
        case .mouse(let num): return "mouse:\(num)"
        case .keyboard(let title, let num): return "keyboard:\(title):\(num)"
        }
    }

    init?(stringValue: String) {
        let parts = stringValue.split(separator: ":")
        guard let code = Int(parts.last ?? "") else { return nil }

        switch parts[0] {
        case "mouse": self = .mouse(code)
        case "keyboard": self = .keyboard(title: String(parts[1]), code: code)
        default: return nil
        }
    }
}

enum ClickedButtonType: String, Hashable, Equatable, CaseIterable {
    case leftMouse
    case rightMouse
}

@Observable
final class ClickedButtonSettings: Identifiable {

    var type: ClickedButtonType
    var hotkey: InputKey?
    var isActive: Bool = false
    var isListened: Bool = false
    var timeoutMs: Double

    init(type: ClickedButtonType, timeoutMs: Double) {
        self.type = type
        self.timeoutMs = timeoutMs
    }
}
