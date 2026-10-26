import AppKit
import SpaceNameCore
import SpaceNameSystem

/// Keeps the titles of VS Code's windows, by window id, without Screen Recording. Cheap sources first: windows on
/// the current Space, and VS Code's own notifications, which carry the window even when it sits on another Space.
/// Whatever they leave out is searched for in the background.
final class TitleResolver: NSObject {
  private(set) var cache = TitleCache()
  var onChange: (() -> Void)?

  private static let searchBudget: TimeInterval = 5
  private static let notifications = [
    kAXWindowCreatedNotification, kAXTitleChangedNotification,
    kAXFocusedWindowChangedNotification, kAXMainWindowChangedNotification,
  ]

  private var throttle = BruteForceThrottle()
  private let searchQueue = DispatchQueue(label: "SpaceName.title-search", qos: .utility)
  private var code: NSRunningApplication?
  private var observer: AXObserverHandle?
  private var retry: BoundedRetry?
  private var launches: NSKeyValueObservation?
  private var finishedLaunching: NSKeyValueObservation?

  func start() {
    launches = NSWorkspace.shared.observe(\.runningApplications, options: [.initial]) { [weak self] _, _ in
      DispatchQueue.main.async { self?.followRunningCode() }
    }
    let center = NSWorkspace.shared.notificationCenter
    center.addObserver(self, selector: #selector(spaceChanged), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
    center.addObserver(self, selector: #selector(appActivated(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
  }

  func refreshVisible() {
    guard let pid = code?.processIdentifier else { return }
    for (wid, title) in visibleTitles(pid: pid) { cache.set(title, for: wid) }
    onChange?()
  }

  func resolveMissing(candidates: [CodeWindow]) {
    guard let pid = code?.processIdentifier else { return }
    let ids = candidates.map(\.id)
    cache.prune(keeping: Set(ids))
    search(pid: pid, wanted: Set(throttle.due(cache.missing(ids), now: Date())))
  }

  private func followRunningCode() {
    let running = CodeWindows.runningApp()
    let pid = followedProcess(current: code?.processIdentifier, found: running?.processIdentifier,
                              currentExited: code.map { processExited($0.processIdentifier) } ?? true)
    guard pid != code?.processIdentifier else { return }
    observer = nil
    retry = nil
    finishedLaunching = nil
    cache = TitleCache()
    throttle = BruteForceThrottle()
    code = running
    onChange?()
    guard let running else { return }
    if running.isFinishedLaunching {
      attach()
    } else {
      finishedLaunching = running.observe(\.isFinishedLaunching, options: [.new]) { [weak self] app, _ in
        guard app.isFinishedLaunching else { return }
        DispatchQueue.main.async { self?.attach() }
      }
    }
  }

  private func attach() {
    guard !tryAttach() else { return }
    retry = BoundedRetry { [weak self] in self?.tryAttach() ?? true }
  }

  /// True when there is nothing left to attach.
  @discardableResult
  private func tryAttach() -> Bool {
    guard let pid = code?.processIdentifier else { return true }
    if observer != nil { return true }
    observer = AXObserverHandle(pid: pid, notifications: Self.notifications) { [weak self] element, _ in
      self?.noticed(element)
    }
    guard observer != nil else { return false }
    refreshVisible()
    search(pid: pid, wanted: Set(cache.missing(CodeWindows.list(pid: pid).map(\.id))))
    return true
  }

  /// A notification may name something inside a window — its title would be a tab's. Only the window's own
  /// title is a project name.
  private func noticed(_ element: AXUIElement) {
    guard let window = axWindowElement(of: element), let wid = axWindowID(window) else { return }
    cache.set(axString(window, kAXTitleAttribute), for: wid)
    onChange?()
  }

  private func search(pid: pid_t, wanted: Set<UInt32>) {
    guard !wanted.isEmpty else { return }
    searchQueue.async {
      let found = BruteForce.titles(pid: pid, wanted: wanted, budget: Self.searchBudget).found
      DispatchQueue.main.async { [weak self] in
        guard let self, self.code?.processIdentifier == pid, !found.isEmpty else { return }
        // A notification that landed during the search is newer than what the search read.
        for (wid, title) in found where self.cache.titles[wid] == nil { self.cache.set(title, for: wid) }
        self.onChange?()
      }
    }
  }

  @objc private func spaceChanged() {
    if observer == nil { tryAttach() }
    refreshVisible()
  }

  @objc private func appActivated(_ note: Notification) {
    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    if observer == nil, app?.bundleIdentifier == CodeWindows.bundleID { tryAttach() }
  }
}
