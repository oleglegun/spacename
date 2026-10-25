/// Reads what SLSCopyManagedDisplaySpaces returns. Type 4 is a full-screen Space; its tiles name the
/// windows it holds — two for Split View.
public func parseDisplays(_ raw: [[String: Any]]) -> [DisplayInfo] {
  raw.compactMap { display in
    guard let uuid = display["Display Identifier"] as? String else { return nil }
    let spaces = (display["Spaces"] as? [[String: Any]] ?? []).compactMap(parseSpace)
    return DisplayInfo(uuid: uuid, spaces: spaces)
  }
}

private func parseSpace(_ space: [String: Any]) -> SpaceInfo? {
  guard let id = space["ManagedSpaceID"] as? Int else { return nil }
  let tiles = (space["TileLayoutManager"] as? [String: Any])?["TileSpaces"] as? [[String: Any]] ?? []
  return SpaceInfo(id: UInt64(id),
                   isFullscreen: space["type"] as? Int == 4,
                   tileWindowIDs: tiles.compactMap { ($0["TileWindowID"] as? Int).map(UInt32.init) })
}
