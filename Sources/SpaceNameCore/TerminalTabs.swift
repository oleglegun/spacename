import Foundation

/// A Terminal tab: the window Terminal draws it in, and its title as the tab bar shows it — status glyph and all.
public struct TerminalTab: Equatable {
  public let windowID: UInt32
  /// The window's frame as Terminal itself keeps it (top-left origin). The window list reports where Mission
  /// Control draws a window — a thumbnail-sized frame — so only this one can be compared across tabs.
  public let frame: CGRect
  public let title: String

  public init(windowID: UInt32, frame: CGRect, title: String) {
    self.windowID = windowID
    self.frame = frame
    self.title = title
  }
}

/// Reads what the tab script prints: per tab, its window's id, its window's bounds (left, top, right, bottom),
/// its custom title and its window's name, fields split by U+001F and tabs by U+001E. A tab nobody titled goes
/// by its window's name.
public func parseTerminalTabs(_ output: String) -> [TerminalTab] {
  output.split(separator: "\u{1E}").compactMap { record in
    let fields = record.split(separator: "\u{1F}", omittingEmptySubsequences: false)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    guard fields.count == 4, let wid = UInt32(fields[0]), let frame = parseBounds(fields[1]) else { return nil }
    let title = fields[2].isEmpty ? fields[3] : fields[2]
    return title.isEmpty ? nil : TerminalTab(windowID: wid, frame: frame, title: title)
  }
}

private func parseBounds(_ text: String) -> CGRect? {
  let edges = text.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
  guard edges.count == 4 else { return nil }
  return CGRect(x: edges[0], y: edges[1], width: edges[2] - edges[0], height: edges[3] - edges[1])
}

/// The Terminal tabs a Space's pill lists. Terminal draws every tab as a window of its own: the tab in front has a
/// Space, the ones behind it have none and share its frame (measured on macOS 27.2). A hidden tab goes where the
/// one front tab with its frame is; two of them — two full-screen Terminals with tabs on one display — leave it
/// out rather than guess. A Space reads window by window from left to right, each window's tabs in the order
/// they were opened. Titles are kept as they are, repeats included.
public func terminalLabels(displays: [DisplayInfo], tabs: [TerminalTab], windows: [AppWindow]) -> [UInt64: [String]] {
  let byID = Dictionary(windows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
  let fronts = tabs.compactMap { tab in
    byID[tab.windowID].flatMap { $0.spaceIDs.isEmpty ? nil : PlacedTab(index: 0, tab: tab, front: tab, window: $0) }
  }
  let placed = tabs.enumerated().compactMap { index, tab -> PlacedTab? in
    guard let window = byID[tab.windowID] else { return nil }
    if !window.spaceIDs.isEmpty { return PlacedTab(index: index, tab: tab, front: tab, window: window) }
    let matches = fronts.filter { $0.tab.frame == tab.frame }
    guard matches.count == 1 else { return nil }
    return PlacedTab(index: index, tab: tab, front: matches[0].tab, window: matches[0].window)
  }
  .sorted { ($0.front.frame.minX, $0.tab.windowID, $0.index) < ($1.front.frame.minX, $1.tab.windowID, $1.index) }

  var labels: [UInt64: [String]] = [:]
  for space in displays.flatMap(\.spaces) {
    let names = placed.filter { belongs($0.window, to: space) }.map(\.tab.title)
    if !names.isEmpty { labels[space.id] = names }
  }
  return labels
}

/// A tab and the front tab whose Space it takes: itself when it is in front.
private struct PlacedTab {
  let index: Int
  let tab: TerminalTab
  let front: TerminalTab
  let window: AppWindow
}

/// A pill lists VS Code's projects first, then Terminal's tabs.
public func combinedLabels(code: [UInt64: [String]], terminal: [UInt64: [String]]) -> [UInt64: [String]] {
  code.merging(terminal, uniquingKeysWith: +)
}
