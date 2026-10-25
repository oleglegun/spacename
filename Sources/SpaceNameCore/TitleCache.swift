import Foundation

/// Window titles by window id. Only project names are kept: a placeholder or blank title removes the entry, so
/// the window is looked up again rather than counting as resolved.
public struct TitleCache {
  public private(set) var titles: [UInt32: String] = [:]

  public init() {}

  public mutating func set(_ raw: String?, for wid: UInt32) {
    titles[wid] = knownTitle(raw)
  }

  public mutating func prune(keeping live: Set<UInt32>) {
    titles = titles.filter { live.contains($0.key) }
  }

  public func missing(_ candidates: [UInt32]) -> [UInt32] {
    candidates.filter { titles[$0] == nil }
  }
}

/// Keeps the brute-force search from re-walking the same windows on every Mission Control open: a window the
/// search could not resolve waits `retryAfter` before it is searched for again.
public struct BruteForceThrottle {
  private let retryAfter: TimeInterval
  private var attempted: [UInt32: Date] = [:]

  public init(retryAfter: TimeInterval = 300) {
    self.retryAfter = retryAfter
  }

  public mutating func due(_ wids: [UInt32], now: Date) -> [UInt32] {
    let due = wids.filter { wid in attempted[wid].map { now.timeIntervalSince($0) >= retryAfter } ?? true }
    for wid in due { attempted[wid] = now }
    return due
  }
}
