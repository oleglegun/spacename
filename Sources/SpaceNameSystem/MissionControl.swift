import AppKit
import SpaceNameCore

/// Mission Control as WindowManager exposes it through Accessibility while it is open (the Dock held it before
/// macOS 27): one mc.display per display → mc.spaces → mc.spaces.list → one button per Space, in bar order.
public enum MissionControl {
  public enum Read {
    case open([SpacesBar])
    case closed
    /// WindowManager did not answer — busy or restarting. Says nothing about whether Mission Control is open.
    case failed
  }

  private static var hostPID: pid_t = 0
  private static var host: AXUIElement?

  private static func hostElement() -> AXUIElement? {
    guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.WindowManager").first else { return nil }
    if app.processIdentifier != hostPID {
      hostPID = app.processIdentifier
      host = appElement(pid: hostPID, timeout: 0.25)
    }
    return host
  }

  private static func identifier(_ element: AXUIElement) -> String? {
    axString(element, kAXIdentifierAttribute)
  }

  public static func read() -> Read {
    guard let host = hostElement() else { return .failed }
    var value: AnyObject?
    guard AXUIElementCopyAttributeValue(host, kAXChildrenAttribute as CFString, &value) == .success,
          let children = value as? [AXUIElement] else { return .failed }
    let displays = children.filter { identifier($0) == "mc.display" }
    guard !displays.isEmpty else { return .closed }

    var bars: [SpacesBar] = []
    for display in displays {
      let list = axChildren(display)
        .filter { identifier($0) == "mc.spaces" }
        .flatMap(axChildren)
        .first { identifier($0) == "mc.spaces.list" }
      let buttons = (list.map(axChildren) ?? []).map { axFrame($0).map { spaceButtonFrame(reported: $0) } }
      guard let bar = assembleBar(displayFrame: axFrame(display), buttons: buttons) else {
        return .failed
      }
      bars.append(bar)
    }
    return .open(bars)
  }
}
