import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@main
struct RimeWubiAssistantApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var model = AppViewModel()

  var body: some Scene {
    WindowGroup("Wubi Code Assistant") {
      ContentView(model: model)
        .frame(minWidth: 600, minHeight: 540)
    }
    .defaultSize(width: 720, height: 680)
    .windowResizability(.contentMinSize)
    .commands {
      CommandGroup(replacing: .newItem) {}
    }
  }
}
