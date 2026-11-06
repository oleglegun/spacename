import AppKit
import SpaceNameCore

/// Terminal's tabs through AppleScript, the one source that names them all: Accessibility builds a window's
/// elements only once something asks for them, and has none for a tab hidden behind another.
public enum Terminal {
  public static let bundleID = "com.apple.Terminal"

  private static let queue = DispatchQueue(label: "SpaceName.terminal", qos: .userInitiated)
  /// A Terminal that stops answering must not keep the pills waiting.
  private static let deadline: TimeInterval = 3
  /// Checks it is running first: a bare `tell` would launch it. Terminal's window list can hold something that is no
  /// window — class `item`, no id, no bounds, absent from its Window menu — and one error would fail the whole read,
  /// leaving every pill on the last good one. So each window is on its own, except for a timeout (-1712): that is
  /// Terminal not answering, not a window to skip.
  private static let script = """
    if application id "\(bundleID)" is running then
      tell application id "\(bundleID)"
        with timeout of 2 seconds
          set AppleScript's text item delimiters to ","
          set out to ""
          repeat with w in windows
            try
              set head to ((id of w) as text) & (character id 31) & ((bounds of w) as text) & (character id 31)
              set wname to name of w
              repeat with t in tabs of w
                set out to out & head & (custom title of t) & (character id 31) & wname & (character id 30)
              end repeat
            on error message number code
              if code is -1712 then error message number code
            end try
          end repeat
          return out
        end timeout
      end tell
    end if
    """

  public static func runningApp() -> NSRunningApplication? {
    NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
  }

  /// Asks macOS once whether SpaceName may read Terminal. The question waits for the person's answer, and an answer
  /// already given comes back at once. Nothing is asked while Terminal is not running.
  public static func askPermission() {
    queue.async { _ = permission(ask: true) }
  }

  /// Every tab, delivered on the main thread: empty when Terminal is not running or SpaceName may not read it, nil
  /// when Terminal did not answer. Only a permission already given is used — a question would come up over
  /// Mission Control.
  public static func readTabs(completion: @escaping ([TerminalTab]?) -> Void) {
    queue.async {
      let tabs: [TerminalTab]? = runningApp() != nil && permission(ask: false) == noErr ? runScript() : []
      DispatchQueue.main.async { completion(tabs) }
    }
  }

  private static func permission(ask: Bool) -> OSStatus {
    let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
    return AEDeterminePermissionToAutomateTarget(target.aeDesc, AEEventClass(kCoreEventClass), AEEventID(kAEGetData), ask)
  }

  static func runScript() -> [TerminalTab]? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { return nil }
    let stop = DispatchWorkItem { if process.isRunning { process.terminate() } }
    DispatchQueue.global().asyncAfter(deadline: .now() + deadline, execute: stop)
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    stop.cancel()
    guard process.terminationStatus == 0 else { return nil }
    return parseTerminalTabs(String(decoding: data, as: UTF8.self))
  }
}
