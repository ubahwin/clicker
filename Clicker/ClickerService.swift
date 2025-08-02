import AppKit

protocol ClickerServiceProtocol {

    func click(button: ClickedButtonType) async

    func tappedButtons() async -> AsyncStream<InputKey>
}

final class ClickerService: ClickerServiceProtocol {

    // MARK: Properties

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // MARK: Methods

    func tappedButtons() -> AsyncStream<InputKey> {
        AsyncStream { continuation in
            let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.otherMouseDown.rawValue)

            let callback: CGEventTapCallBack = { _, type, event, userInfo in
                guard let continuationPtr = userInfo?.assumingMemoryBound(to: AsyncStream<InputKey>.Continuation.self) else {
                    return Unmanaged.passUnretained(event)
                }

                let hotkey: InputKey
                switch type {
                case .keyDown:
                    let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
                    let name = keyCodeToName[keyCode] ?? "?"
                    hotkey = .keyboard(title: name, code: Int(keyCode))
                case .otherMouseDown:
                    let button = event.getIntegerValueField(.mouseEventButtonNumber)
                    hotkey = .mouse(Int(button))
                default:
                    return Unmanaged.passUnretained(event)
                }

                continuationPtr.pointee.yield(hotkey)
                return Unmanaged.passUnretained(event)
            }

            let continuationBox = UnsafeMutablePointer<AsyncStream<InputKey>.Continuation>.allocate(capacity: 1)
            continuationBox.initialize(to: continuation)

            self.eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: mask,
                callback: callback,
                userInfo: continuationBox
            )

            if let eventTap = self.eventTap {
                self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
                CFRunLoopAddSource(CFRunLoopGetCurrent(), self.runLoopSource, .commonModes)
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }

            continuation.onTermination = { @Sendable [weak self] _ in
                if let eventTap = self?.eventTap {
                    CGEvent.tapEnable(tap: eventTap, enable: false)
                }
                if let runLoopSource = self?.runLoopSource {
                    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                }

                self?.runLoopSource = nil
                self?.eventTap = nil

                continuationBox.deinitialize(count: 1)
                continuationBox.deallocate()
            }
        }
    }

    func click(button: ClickedButtonType) {
        let location = CGEvent(source: nil)?.location ?? .zero

        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: button.downEvent,
            mouseCursorPosition: location,
            mouseButton: button.cgButton
        )

        let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: button.upEvent,
            mouseCursorPosition: location,
            mouseButton: button.cgButton
        )

        mouseDown?.post(tap: .cgSessionEventTap)
        mouseUp?.post(tap: .cgSessionEventTap)
    }
}

extension ClickedButtonType {

    var cgButton: CGMouseButton {
        switch self {
        case .leftMouse: .left
        case .rightMouse: .right
        }
    }

    var downEvent: CGEventType {
        switch self {
        case .leftMouse: .leftMouseDown
        case .rightMouse: .rightMouseDown
        }
    }

    var upEvent: CGEventType {
        switch self {
        case .leftMouse: .leftMouseUp
        case .rightMouse: .rightMouseUp
        }
    }
}

extension UnsafeMutablePointer: @unchecked @retroactive Sendable {}

fileprivate let keyCodeToName: [CGKeyCode: String] = [
    0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
    8: "C", 9: "V", 10: "§", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
    16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
    24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
    32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'",
    40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
    48: "Tab", 49: "Space", 50: "`", 51: "Delete", 52: "Enter", 53: "Escape",
    55: "Command", 56: "Shift", 57: "Caps Lock", 58: "Option", 59: "Control",
    60: "Right Shift", 61: "Right Option", 62: "Right Control", 63: "Function",
    64: "F17", 65: "Keypad .", 67: "Keypad *", 69: "Keypad +", 71: "Keypad Clear",
    75: "Keypad /", 76: "Keypad Enter", 78: "Keypad -", 81: "Keypad =", 82: "Keypad 0",
    83: "Keypad 1", 84: "Keypad 2", 85: "Keypad 3", 86: "Keypad 4", 87: "Keypad 5",
    88: "Keypad 6", 89: "Keypad 7", 91: "Keypad 8", 92: "Keypad 9", 96: "F5",
    97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13",
    106: "F16", 107: "F14", 109: "F10", 111: "F12", 113: "F15", 114: "Help",
    115: "Home", 116: "Page Up", 117: "Forward Delete", 118: "F4", 119: "End",
    120: "F2", 121: "Page Down", 122: "F1", 123: "Left Arrow", 124: "Right Arrow",
    125: "Down Arrow", 126: "Up Arrow", 179: "Fn"
]
