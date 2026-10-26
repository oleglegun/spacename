import Foundation
import SpaceNameCore

public enum CodeFolders {
  private static let state = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/Code/User/globalStorage/storage.json")

  public static func open() -> [(path: String, isWorktree: Bool)] {
    guard let data = try? Data(contentsOf: state) else { return [] }
    return openFolderPaths(storageJSON: data).map { (path: $0, isWorktree: isWorktree($0)) }
  }
}

/// A linked worktree's .git is a file pointing into the main repository's worktrees/. A submodule's .git is a
/// file too, but points into modules/; a repository's own .git is a directory.
func isWorktree(_ path: String) -> Bool {
  guard let pointer = try? String(contentsOfFile: path + "/.git", encoding: .utf8) else { return false }
  return pointer.hasPrefix("gitdir:") && pointer.contains("/worktrees/")
}
