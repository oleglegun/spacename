import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private static let loginItemConfigured = "loginItemConfigured"

  private let startup = Startup()
  private var statusItem: NSStatusItem?
  private let loginItem = NSMenuItem(title: "Запускать при входе", action: #selector(toggleLoginItem), keyEquivalent: "")

  func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = NSImage(systemSymbolName: "text.below.rectangle", accessibilityDescription: "SpaceName")
      ?? NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "SpaceName")
    let menu = NSMenu()
    menu.delegate = self
    loginItem.target = self
    menu.addItem(loginItem)
    menu.addItem(.separator())
    menu.addItem(withTitle: "Выход", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    item.menu = menu
    statusItem = item

    registerLoginItemOnFirstLaunch()
    startup.run()
  }

  func menuWillOpen(_ menu: NSMenu) {
    loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
  }

  /// Only the first launch registers, so turning it off in the menu sticks. A failed attempt is retried next launch.
  private func registerLoginItemOnFirstLaunch() {
    guard !UserDefaults.standard.bool(forKey: Self.loginItemConfigured) else { return }
    do {
      try SMAppService.mainApp.register()
    } catch {
      NSLog("SpaceName: login item registration failed: %@ (status %ld)", error.localizedDescription, SMAppService.mainApp.status.rawValue)
    }
    if SMAppService.mainApp.status == .enabled {
      UserDefaults.standard.set(true, forKey: Self.loginItemConfigured)
    }
  }

  @objc private func toggleLoginItem() {
    do {
      if SMAppService.mainApp.status == .enabled {
        try SMAppService.mainApp.unregister()
      } else {
        try SMAppService.mainApp.register()
      }
    } catch {
      NSApp.activate()
      NSAlert(error: error).runModal()
    }
  }
}
