import SwiftUI
import Combine

struct ClickerSettingsView<ViewModel: ClickerViewModelProtocol>: View {

    @ObservedObject var viewModel: ViewModel
    @FocusState var isTimeoutFocused: Bool

    var body: some View {
        TabView {
            if viewModel.buttonSettings.isEmpty {
                ProgressView()
            } else {
                ForEach($viewModel.buttonSettings) { $buttonSetting in
                    let hotkeyName: String = {
                        switch buttonSetting.hotkey {
                        case .keyboard(let title, _):
                            "\(title)"
                        case .mouse(let button):
                            "Кнопка \(button)"
                        default: "Не задана"
                        }
                    }()

                    VStack {
                        HStack {
                            Text("Горячая клавиша")

                            HotkeyRecorderView(
                                isFocused: buttonSetting.isListened,
                                name: hotkeyName,
                                isCancelAvailable: buttonSetting.hotkey != nil,
                                cancel: { viewModel.clearHotkey(for: buttonSetting) },
                                onTap: {
                                    isTimeoutFocused = false
                                    viewModel.listenHotkey(for: buttonSetting)
                                }
                            )
                        }
                        .padding()

                        TimeoutView(timeout: $buttonSetting.timeoutMs, isTimeoutFocused: _isTimeoutFocused)
                    }
                    .padding()
                    .tabItem {
                        switch buttonSetting.type {
                        case .leftMouse:
                            Text("Левая кнопка мыши")
                        case .rightMouse:
                            Text("Правая кнопка мыши")
                        }
                    }
                    .onChange(of: buttonSetting.hotkey) {
                        viewModel.hotkeyDidChange($1, for: buttonSetting)
                    }
                    .onChange(of: buttonSetting.timeoutMs) {
                        viewModel.timeoutDidChange($1, for: buttonSetting)
                    }
                }
            }
        }
    }
}
