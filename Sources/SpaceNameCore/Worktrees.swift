import Foundation

/// The folders VS Code has a window open on, from the state it keeps for itself (storage.json). A private file,
/// not an API: anything unexpected reads as no folders, and the labels simply go unmarked.
public func openFolderPaths(storageJSON data: Data) -> [String] {
  guard let doc = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let state = doc["windowsState"] as? [String: Any],
        let windows = state["openedWindows"] as? [[String: Any]] else { return [] }
  return windows.compactMap { window in
    guard let folder = window["folder"] as? String, let url = URL(string: folder), url.isFileURL else { return nil }
    return url.path
  }
}

/// Window titles are folder names, so a worktree is recognized by its folder's name. A name a repository also
/// carries is left unmarked: the title cannot say which of the two a window is.
public func worktreeNames(folders: [(path: String, isWorktree: Bool)]) -> Set<String> {
  let names = { (worktree: Bool) in
    Set(folders.filter { $0.isWorktree == worktree }.map { ($0.path as NSString).lastPathComponent })
  }
  return names(true).subtracting(names(false))
}

/// The same mark tasker puts on a task that has a worktree.
public func marked(_ names: [String], worktrees: Set<String>) -> [String] {
  names.map { worktrees.contains($0) ? "⎇ \($0)" : $0 }
}
