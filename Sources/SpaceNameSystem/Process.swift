import Darwin

/// Asks the kernel rather than NSWorkspace: NSWorkspace's app list drops the Dock for a moment every few seconds
/// while it keeps running (measured on macOS 15.8). EPERM means the process exists but may not be signalled.
public func processExited(_ pid: pid_t) -> Bool {
  kill(pid, 0) != 0 && errno == ESRCH
}
