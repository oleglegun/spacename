import AppKit
import SpaceNameCore
import SpaceNameSystem

/// Calls `onOpen` when Mission Control opens — the Dock says so through Accessibility, so nothing polls while it
/// is closed. The Dock is an LSUIElement app: launch notifications skip it, so a restarted Dock is noticed through
/// the running-applications list instead.
final class DockWatcher: NSObject {
  private let onOpen: () -> Void
  private var dockPID: pid_t = 0
  private var observer: AXObserverHandle?
  private var retry: BoundedRetry?
  private var launches: NSKeyValueObservation?

  init(onOpen: @escaping () -> Void) {
    self.onOpen = onOpen
  }

  func start() {
    launches = NSWorkspace.shared.observe(\.runningApplications, options: [.initial]) { [weak self] _, _ in
      DispatchQueue.main.async { self?.followDock() }
    }
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(spaceChanged), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
  }

  private func followDock() {
    let found = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.processIdentifier
    let current = dockPID == 0 ? nil : dockPID
    let exited = current.map(processExited) ?? true
    let pid = followedProcess(current: current, found: found, currentExited: exited) ?? 0
    guard pid != dockPID else { return }
    dockPID = pid
    observer = nil
    retry = nil
    guard pid != 0, !tryAttach() else { return }
    retry = BoundedRetry { [weak self] in self?.tryAttach() ?? true }
  }

  /// True when there is nothing left to attach.
  @discardableResult
  private func tryAttach() -> Bool {
    guard dockPID != 0 else { return true }
    if observer != nil { return true }
    observer = AXObserverHandle(pid: dockPID, notifications: ["AXExposeShowAllWindows", "AXExposeShowFrontWindows"]) {
      [weak self] _, _ in self?.onOpen()
    }
    return observer != nil
  }

  @objc private func spaceChanged() {
    if observer == nil { tryAttach() }
  }
}
