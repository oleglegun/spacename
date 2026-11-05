import Foundation

public enum MissionControlRead {
  case open
  case closed
  /// WindowManager did not answer; says nothing about Mission Control.
  case failed
}

/// One Mission Control opening, from WindowServer's event to the bar going away. The event can land before the
/// bar exists, and a single read can miss mid-animation, so neither ends a session on its own: the bar must be
/// gone for `closeDebounce`. An event with no bar after it — Mission Control closing, App Exposé, a quick peek —
/// ends after `waitLimit`.
public struct SessionState {
  public enum Phase: Equatable { case waiting, live, ended }

  public static let waitLimit: TimeInterval = 1.5
  public static let closeDebounce: TimeInterval = 0.2

  public private(set) var phase: Phase = .waiting
  private let openedAt: Date
  private var closedSince: Date?

  public init(openedAt: Date) {
    self.openedAt = openedAt
  }

  public mutating func observe(_ read: MissionControlRead, at now: Date) {
    switch phase {
    case .ended:
      return
    case .waiting:
      if read == .open {
        phase = .live
      } else if now.timeIntervalSince(openedAt) >= Self.waitLimit {
        phase = .ended
      }
    case .live:
      switch read {
      case .open:
        closedSince = nil
      case .failed:
        break
      case .closed:
        let since = closedSince ?? now
        closedSince = since
        if now.timeIntervalSince(since) >= Self.closeDebounce { phase = .ended }
      }
    }
  }
}
