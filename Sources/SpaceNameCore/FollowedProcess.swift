import Foundation

/// Which process to follow after the running-applications list changes. Looking an app up by bundle id comes
/// back empty for a moment every few seconds while it keeps running (measured on the Dock, macOS 15.8), so an
/// empty lookup lets go only of a process that has really exited.
public func followedProcess(current: pid_t?, found: pid_t?, currentExited: Bool) -> pid_t? {
  if let found { return found }
  return currentExited ? nil : current
}
