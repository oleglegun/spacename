import AppKit
import SpaceNameCore

/// Mission Control as the Dock exposes it through Accessibility while it is open:
/// mc → mc.display → mc.spaces → mc.spaces.list → one button per Space, in bar order.
public enum DockMissionControl {
  public enum Read {
    case open([SpacesBar])
    case closed
    /// The Dock did not answer — busy or restarting. Says nothing about whether Mission Control is open.
    case failed
  }

  private static var dockPID: pid_t = 0
  private static var dock: AXUIElement?

  private static func dockElement() -> AXUIElement? {
    guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else { return nil }
    if app.processIdentifier != dockPID {
      dockPID = app.processIdentifier
      dock = appElement(pid: dockPID, timeout: 0.25)
    }
    return dock
  }

  private static func identifier(_ element: AXUIElement) -> String? {
    axString(element, kAXIdentifierAttribute)
  }

  public static func read() -> Read {
    guard let dock = dockElement() else { return .failed }
    var value: AnyObject?
    guard AXUIElementCopyAttributeValue(dock, kAXChildrenAttribute as CFString, &value) == .success,
          let children = value as? [AXUIElement] else { return .failed }
    guard let mc = children.first(where: { identifier($0) == "mc" }) else { return .closed }

    var bars: [SpacesBar] = []
    for display in axChildren(mc) where identifier(display) == "mc.display" {
      let list = axChildren(display)
        .filter { identifier($0) == "mc.spaces" }
        .flatMap(axChildren)
        .first { identifier($0) == "mc.spaces.list" }
      let buttons = (list.map(axChildren) ?? []).map { button in
        (frame: axFrame(button),
         labelFrame: axChildren(button).first { axString($0, kAXRoleAttribute) == kAXStaticTextRole }.flatMap(axFrame))
      }
      guard let bar = assembleBar(displayFrame: axFrame(display), buttons: buttons) else { return .failed }
      bars.append(bar)
    }
    return .open(bars)
  }
}
