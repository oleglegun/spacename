import Foundation

/// A window belongs to a Space when SkyLight puts it there alone, or when the Space's tiles name it.
func belongs(_ window: AppWindow, to space: SpaceInfo) -> Bool {
  space.tileWindowIDs.contains(window.id) || window.spaceIDs == [space.id]
}

/// The VS Code names a Space's pill lists. A full-screen Space reads left to right, as Split View shows its
/// windows; a desktop reads alphabetically. Spaces with no titled VS Code window get no entry.
public func spaceLabels(displays: [DisplayInfo], windows: [AppWindow], titles: [UInt32: String]) -> [UInt64: [String]] {
  var labels: [UInt64: [String]] = [:]
  for space in displays.flatMap(\.spaces) {
    let members = windows.filter { titles[$0.id] != nil && belongs($0, to: space) }
    let names = space.isFullscreen
      ? members.sorted { $0.frame.minX < $1.frame.minX }.compactMap { titles[$0.id] }
      : members.compactMap { titles[$0.id] }.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    var seen = Set<String>()
    let distinct = names.filter { seen.insert($0).inserted }
    if !distinct.isEmpty { labels[space.id] = distinct }
  }
  return labels
}
