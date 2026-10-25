import AppKit
import ApplicationServices

/// Starts watching once Accessibility is granted. Until then a two-second check waits for the grant and stops
/// for good once it comes, so a fresh install starts working without a restart.
final class Startup {
  private let resolver = TitleResolver()
  private lazy var session = OverlaySession(resolver: resolver)
  private lazy var watcher = DockWatcher { [weak self] in self?.session.begin() }
  private var trustCheck: Timer?

  func run() {
    // Set on the system-wide element, the timeout covers every element this process reads — the Dock's bar
    // and VS Code's windows alike. Unset, a busy app holds the main thread for about six seconds per call.
    AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.25)
    let prompt = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    if AXIsProcessTrustedWithOptions(prompt) { return startWatching() }
    let timer = Timer(timeInterval: 2, repeats: true) { [weak self] timer in
      guard AXIsProcessTrusted() else { return }
      timer.invalidate()
      self?.trustCheck = nil
      self?.startWatching()
    }
    RunLoop.main.add(timer, forMode: .common)
    trustCheck = timer
  }

  private func startWatching() {
    resolver.start()
    watcher.start()
  }
}
