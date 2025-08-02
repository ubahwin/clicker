import SwiftUI
import Combine

@MainActor
protocol ClickerViewModelProtocol: ObservableObject {

    var buttonSettings: [ClickedButtonSettings] { get set }

    func listenHotkey(for button: ClickedButtonSettings)

    func clearHotkey(for button: ClickedButtonSettings)

    func hotkeyDidChange(_ hotkey: InputKey?, for button: ClickedButtonSettings)
    
    func timeoutDidChange(_ timeout: Double, for button: ClickedButtonSettings)
}

final class ClickerViewModel: ClickerViewModelProtocol {

    // MARK: Properties

    @Published var buttonSettings: [ClickedButtonSettings] = []

    private let clickerService: ClickerServiceProtocol
    private let clickerStorage: ClickerStorageProtocol

    // MARK: Init

    init(clickerService: ClickerServiceProtocol, clickerStorage: ClickerStorageProtocol) {
        self.clickerService = clickerService
        self.clickerStorage = clickerStorage

        bind()
    }

    private func bind() {
        Task { [weak self] in
            guard let self else { return }
            for await key in await clickerService.tappedButtons() {
                await handleNewKey(key)
            }
        }

        Task { [weak self] in
            guard let self else { return }
            self.buttonSettings = await self.clickerStorage.loadSettings()
        }
    }

    // MARK: Methods

    func listenHotkey(for button: ClickedButtonSettings) {
        button.isListened = true
        button.isActive = false
    }

    func clearHotkey(for button: ClickedButtonSettings) {
        button.hotkey = nil
        button.isListened = false
        button.isActive = false
    }

    func hotkeyDidChange(_ hotkey: InputKey?, for button: ClickedButtonSettings) {
        Task { [weak self] in
            guard let self else { return }
            await clickerStorage.setHotkey(hotkey, for: button)
        }
    }

    func timeoutDidChange(_ timeout: Double, for button: ClickedButtonSettings) {
        Task { [weak self] in
            guard let self else { return }
            await clickerStorage.setTimeout(timeout, for: button)
        }
    }

    private func handleNewKey(_ key: InputKey) async {

        if case .keyboard(_, let code) = key, code == Constants.escapeButtonCode {
            buttonSettings.forEach { setting in
                setting.isListened = false
            }

            return
        }

        for setting in buttonSettings {

            guard !setting.isListened else {
                setting.hotkey = key
                setting.isListened = false
                return
            }

            if setting.hotkey == key {

                setting.isActive.toggle()

                Task { [weak self, weak setting] in
                    guard let self, let setting else { return }

                    while setting.isActive {
                        try await Task.sleep(for: .milliseconds(setting.timeoutMs))
                        await clickerService.click(button: setting.type)
                    }
                }
            }
        }
    }
}
