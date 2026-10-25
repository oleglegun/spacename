import ApplicationServices
import Foundation
import SpaceNameSystem

/// One AXObserver on an app's element, delivering on the main run loop. All or nothing: right after an app
/// launches its accessibility is not up yet and adding a notification fails — the caller retries.
final class AXObserverHandle {
  private final class Handler {
    let call: (AXUIElement, String) -> Void
    init(_ call: @escaping (AXUIElement, String) -> Void) { self.call = call }
  }

  private let observer: AXObserver
  private let element: AXUIElement
  private let notifications: [String]
  private let handler: Handler

  init?(pid: pid_t, notifications: [String], handler: @escaping (AXUIElement, String) -> Void) {
    var created: AXObserver?
    let callback: AXObserverCallback = { _, element, name, refcon in
      guard let refcon else { return }
      Unmanaged<Handler>.fromOpaque(refcon).takeUnretainedValue().call(element, name as String)
    }
    guard AXObserverCreate(pid, callback, &created) == .success, let created else { return nil }
    let element = appElement(pid: pid, timeout: 0.25)
    let handler = Handler(handler)
    let refcon = Unmanaged.passUnretained(handler).toOpaque()
    for name in notifications {
      let result = AXObserverAddNotification(created, element, name as CFString, refcon)
      guard result == .success || result == .notificationAlreadyRegistered else {
        NSLog("SpaceName: observing %@ on pid %d failed: %d", name, pid, result.rawValue)
        for added in notifications { AXObserverRemoveNotification(created, element, added as CFString) }
        return nil
      }
    }
    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(created), .commonModes)
    self.observer = created
    self.element = element
    self.notifications = notifications
    self.handler = handler
  }

  deinit {
    for name in notifications { AXObserverRemoveNotification(observer, element, name as CFString) }
    CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
  }
}

/// Retries attaching to an app that just launched, every half second, ten times at most — so a broken app never
/// becomes a background timer. `attempt` returns true once there is nothing left to do.
final class BoundedRetry {
  private var timer: Timer?

  init(attempts: Int = 10, interval: TimeInterval = 0.5, attempt: @escaping () -> Bool) {
    var left = attempts
    let timer = Timer(timeInterval: interval, repeats: true) { timer in
      left -= 1
      if attempt() || left <= 0 { timer.invalidate() }
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  deinit {
    timer?.invalidate()
  }
}
