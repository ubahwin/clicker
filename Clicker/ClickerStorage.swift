import Foundation

protocol ClickerStorageProtocol {

    func setHotkey(_ hotKey: InputKey?, for setting: ClickedButtonSettings) async

    func setTimeout(_ timeoutMs: Double, for setting: ClickedButtonSettings) async

    func loadSettings() async -> [ClickedButtonSettings]
}

final actor ClickerStorage: ClickerStorageProtocol {

    // MARK: Properties

    private let userDefaults = UserDefaults.standard
    private let storageKey = "ClickedButtonSettings"

    // MARK: Public Methods

    func setHotkey(_ hotKey: InputKey?, for setting: ClickedButtonSettings) {
        let current = loadSettings()
        if let existing = current.first(where: { $0.type == setting.type }) {
            existing.hotkey = hotKey
            save(updated: existing, in: current)
        }
    }

    func setTimeout(_ timeoutMs: Double, for setting: ClickedButtonSettings) {
        let current = loadSettings()
        if let existing = current.first(where: { $0.type == setting.type }) {
            existing.timeoutMs = timeoutMs
            save(updated: existing, in: current)
        }
    }

    func loadSettings() -> [ClickedButtonSettings] {
        guard let stored = userDefaults.array(forKey: storageKey) as? [[String: Any]] else {
            return ClickedButtonType.allCases.map {
                ClickedButtonSettings(type: $0, timeoutMs: Constants.defaultTimeoutMs)
            }
        }

        return stored.compactMap { dict in
            guard
                let typeRaw = dict["type"] as? String,
                let type = ClickedButtonType(rawValue: typeRaw),
                let timeout = dict["timeoutMs"] as? Double
            else {
                return nil
            }

            let hotkeyString = dict["hotkey"] as? String
            let hotkey = hotkeyString.flatMap { InputKey(stringValue: $0) }

            let setting = ClickedButtonSettings(type: type, timeoutMs: timeout)
            setting.hotkey = hotkey
            return setting
        }
    }

    // MARK: Private Methods

    private func save(updated setting: ClickedButtonSettings, in current: [ClickedButtonSettings]) {
        var updated = current
        if let index = updated.firstIndex(where: { $0.type == setting.type }) {
            updated[index] = setting
        } else {
            updated.append(setting)
        }

        let dictArray = updated.map { setting in
            return [
                "type": setting.type.rawValue,
                "timeoutMs": setting.timeoutMs,
                "hotkey": setting.hotkey?.stringValue ?? ""
            ]
        }

        userDefaults.set(dictArray, forKey: storageKey)
    }
}
