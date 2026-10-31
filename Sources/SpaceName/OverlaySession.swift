import AppKit
import SpaceNameCore
import SpaceNameSystem

/// Pills for one Mission Control opening. Runs a timer only while Mission Control is up: the bars move — Spaces
/// are dragged between displays, thumbnails animate — and the session follows them until the bar is gone.
final class OverlaySession {
  private static let tick: TimeInterval = 1.0 / 30
  private static let resnapshot: TimeInterval = 0.25

  private let resolver: TitleResolver
  private var state: SessionState?
  private var timer: Timer?
  private var pills: [UInt64: PillWindow] = [:]
  private var displays: [DisplayInfo] = []
  private var windows: [CodeWindow] = []
  private var labels: [UInt64: [String]] = [:]
  private var worktrees: Set<String> = []
  private var bars: [SpacesBar] = []
  private var snapshotAt = Date.distantPast

  init(resolver: TitleResolver) {
    self.resolver = resolver
  }

  func begin() {
    if let state, state.phase != .ended { return }
    state = SessionState(openedAt: Date())
    worktrees = worktreeNames(folders: CodeFolders.open())
    resolver.refreshVisible()
    snapshot()
    resolver.resolveMissing(candidates: windows)
    resolver.onChange = { [weak self] in self?.relabel() }
    let timer = Timer(timeInterval: Self.tick, repeats: true) { [weak self] _ in self?.step() }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
    step()
  }

  private func step() {
    guard var state else { return }
    let now = Date()
    let read = DockMissionControl.read()
    switch read {
    case .open(let current):
      state.observe(.open, at: now)
      bars = current
    case .closed:
      state.observe(.closed, at: now)
    case .failed:
      state.observe(.failed, at: now)
    }
    self.state = state
    if state.phase == .ended { return end() }
    // A missed read keeps the last pills where they are.
    guard case .open = read else { return }
    if now.timeIntervalSince(snapshotAt) >= Self.resnapshot { snapshot() } else { render() }
  }

  private func snapshot() {
    displays = SkyLight.displays()
    windows = CodeWindows.runningApp().map { CodeWindows.list(pid: $0.processIdentifier) } ?? []
    snapshotAt = Date()
    relabel()
  }

  private func relabel() {
    labels = spaceLabels(displays: displays, windows: windows, titles: resolver.cache.titles)
      .mapValues { marked($0, worktrees: worktrees) }
    render()
  }

  private func render() {
    let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
    let screens = NSScreen.screens.compactMap { screen in
      screen.displayUUID.map { ScreenRef(uuid: $0, axFrame: screen.axFrame(primaryHeight: primaryHeight)) }
    }
    var shown = Set<UInt64>()
    for placement in placements(bars: bars, screens: screens, displays: displays, labels: labels) {
      let pill = pills[placement.spaceID] ?? PillWindow()
      pills[placement.spaceID] = pill
      pill.show(names: placement.names,
                frame: pillFrame(button: placement.button, lineCount: placement.names.count, primaryScreenHeight: primaryHeight))
      shown.insert(placement.spaceID)
    }
    for (spaceID, pill) in pills where !shown.contains(spaceID) { pill.orderOut(nil) }
  }

  /// Pills live for one opening. A pill kept across days of lid closes, Dock restarts and Spaces moving between
  /// displays ended up ordered front yet never shown on some Spaces, while a new window in its place was shown
  /// (measured on macOS 15.8).
  private func end() {
    timer?.invalidate()
    timer = nil
    resolver.onChange = nil
    bars = []
    for pill in pills.values { pill.close() }
    pills = [:]
  }
}

extension NSScreen {
  var displayUUID: String? {
    guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
          let uuid = CGDisplayCreateUUIDFromDisplayID(number)?.takeRetainedValue() else { return nil }
    return CFUUIDCreateString(nil, uuid) as String
  }

  /// The frame with a top-left origin at the primary display, as the Dock reports its bars.
  func axFrame(primaryHeight: CGFloat) -> CGRect {
    CGRect(x: frame.minX, y: primaryHeight - frame.maxY, width: frame.width, height: frame.height)
  }
}
