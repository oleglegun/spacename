import AppKit
import SpaceNameCore
import SpaceNameSystem

/// Terminal's tabs as of the last read. The permission to read them is asked for when watching starts and when
/// Terminal launches, so the question never comes up over Mission Control.
final class TerminalReader: NSObject {
  private(set) var tabs: [TerminalTab] = []
  private var reading = false

  func start() {
    Terminal.askPermission()
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(launched(_:)),
                                                      name: NSWorkspace.didLaunchApplicationNotification, object: nil)
  }

  /// Reads the tabs again and calls `onChange` once they are in. The last read stands in meanwhile, and stays when
  /// Terminal does not answer.
  func refresh(onChange: @escaping () -> Void) {
    guard !reading else { return }
    reading = true
    Terminal.readTabs { [weak self] tabs in
      guard let self else { return }
      self.reading = false
      if let tabs { self.tabs = tabs }
      onChange()
    }
  }

  @objc private func launched(_ note: Notification) {
    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    if app?.bundleIdentifier == Terminal.bundleID { Terminal.askPermission() }
  }
}
