import SwiftUI
import SwiftData

@main
struct ClickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let viewModel = ClickerViewModel(clickerService: ClickerService(), clickerStorage: ClickerStorage())

    var body: some Scene {
        WindowGroup {
            ClickerSettingsView(viewModel: viewModel)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    // Убивать приложение, если нажали крестик (по дефолту оно остаётся в Dock)
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
