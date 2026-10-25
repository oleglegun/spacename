import AppKit
import SpaceNameCore

public enum CodeWindows {
  public static let bundleID = "com.microsoft.VSCode"

  public static func runningApp() -> NSRunningApplication? {
    NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
  }

  /// Every project window VS Code has, on any Space. Titles are not here: the window list hides them without
  /// Screen Recording.
  public static func list(pid: pid_t) -> [CodeWindow] {
    guard let info = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else { return [] }
    return info.compactMap { window in
      guard (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == pid,
            (window[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
            let number = window[kCGWindowNumber as String] as? NSNumber,
            let bounds = window[kCGWindowBounds as String] as? NSDictionary,
            let frame = CGRect(dictionaryRepresentation: bounds),
            isCandidateMainWindow(frame) else { return nil }
      let wid = number.uint32Value
      return CodeWindow(id: wid, spaceIDs: SkyLight.spaceIDs(ofWindow: wid), frame: frame)
    }
  }
}

/// Titles Accessibility gives without a search: windows on the current Space, plus the app's focused and main
/// windows, which AppKit does not hide behind the Space filter.
public func visibleTitles(pid: pid_t) -> [UInt32: String] {
  let app = appElement(pid: pid, timeout: 0.25)
  var windows = axValue(app, kAXWindowsAttribute) as? [AXUIElement] ?? []
  windows += [kAXFocusedWindowAttribute, kAXMainWindowAttribute].compactMap { axElement(app, $0) }
  var titles: [UInt32: String] = [:]
  for window in windows where axString(window, kAXRoleAttribute) == kAXWindowRole {
    if let wid = axWindowID(window), let title = knownTitle(axString(window, kAXTitleAttribute)) {
      titles[wid] = title
    }
  }
  return titles
}
