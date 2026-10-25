import ApplicationServices
import Foundation
import SpaceNameCore

/// Accessibility lists only the current Space's windows. The rest are reached the way AltTab and yabai reach
/// them: build an element for every AXUIElementID of the app from a remote token and keep the window roots.
/// Ids are large and sparse in a long-lived app, so the search is bounded by time, not by id. Off the main thread.
public enum BruteForce {
  public static func titles(pid: pid_t, wanted: Set<UInt32>, budget: TimeInterval)
    -> (found: [UInt32: String], elapsed: TimeInterval, lastElementID: UInt64) {
    let start = DispatchTime.now().uptimeNanoseconds
    func elapsed() -> TimeInterval { Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000 }

    var found: [UInt32: String] = [:]
    guard !wanted.isEmpty, let token = CFDataCreateMutable(kCFAllocatorDefault, 20) else { return (found, 0, 0) }
    // pid (4) + 0 (4) + "coco" (4) + element id (8), little-endian; only the id changes per candidate.
    CFDataSetLength(token, 20)
    let bytes = CFDataGetMutableBytePtr(token)!
    memset(bytes, 0, 20)
    var pidField = pid
    memcpy(bytes, &pidField, 4)
    var magic: Int32 = 0x636f636f
    memcpy(bytes + 8, &magic, 4)

    var id: UInt64 = 0
    while found.count < wanted.count && elapsed() < budget {
      var idField = id
      memcpy(bytes + 12, &idField, 8)
      if let element = axRemoteElement(token: token) {
        AXUIElementSetMessagingTimeout(element, 0.1)
        if let wid = axWindowID(element), wanted.contains(wid), found[wid] == nil,
           axString(element, kAXRoleAttribute) == kAXWindowRole,
           let title = knownTitle(axString(element, kAXTitleAttribute)) {
          found[wid] = title
        }
      }
      id += 1
    }
    return (found, elapsed(), id)
  }
}
