/// Where a walk over an app's AXUIElementIDs can stop. Ids are handed out in order, so past the newest element
/// every id is dead. Gaps between live ids stay far below a dead run of 10,000: under 1,000 in a VS Code up for
/// eight days, whose ids had reached 19,000 (measured on macOS 15.8).
public struct IDScanEnd {
  private let deadRun: UInt64
  private var lastLive: UInt64 = 0

  public init(deadRun: UInt64 = 10_000) {
    self.deadRun = deadRun
  }

  /// True once `deadRun` ids in a row past the last live one were dead.
  public mutating func reached(after id: UInt64, live: Bool) -> Bool {
    if live {
      lastLive = id
      return false
    }
    return id - lastLive >= deadRun
  }
}
