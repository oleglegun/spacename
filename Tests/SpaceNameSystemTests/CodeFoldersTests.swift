import XCTest
@testable import SpaceNameSystem

final class CodeFoldersTests: XCTestCase {
  private func folder(dotGit: String?, isDirectory: Bool = false) throws -> String {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
    let git = dir.appendingPathComponent(".git")
    if isDirectory {
      try FileManager.default.createDirectory(at: git, withIntermediateDirectories: true)
    } else if let dotGit {
      try dotGit.write(to: git, atomically: true, encoding: .utf8)
    }
    return dir.path
  }

  func testLinkedWorktreeIsAWorktree() throws {
    XCTAssertTrue(isWorktree(try folder(dotGit: "gitdir: /p/.git/worktrees/web\n")))
  }

  func testRepositoryIsNotAWorktree() throws {
    XCTAssertFalse(isWorktree(try folder(dotGit: nil, isDirectory: true)))
  }

  func testSubmoduleIsNotAWorktree() throws {
    XCTAssertFalse(isWorktree(try folder(dotGit: "gitdir: ../.git/modules/vendor\n")))
  }

  func testFolderOutsideGitIsNotAWorktree() throws {
    XCTAssertFalse(isWorktree(try folder(dotGit: nil)))
  }
}
