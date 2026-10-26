import XCTest
@testable import SpaceNameCore

final class WorktreesTests: XCTestCase {
  func testWorktreeFoldersNameTheirWindows() {
    let names = worktreeNames(folders: [
      (path: "/p/.claude/worktrees/web", isWorktree: true),
      (path: "/p/backend", isWorktree: false),
    ])

    XCTAssertEqual(names, ["web"])
  }

  func testNameSharedWithARepositoryIsNotMarked() {
    let names = worktreeNames(folders: [(path: "/a/web", isWorktree: true), (path: "/b/web", isWorktree: false)])

    XCTAssertEqual(names, [])
  }

  func testMarkedPrefixesWorktreeNamesOnly() {
    XCTAssertEqual(marked(["web", "api"], worktrees: ["web"]), ["⎇ web", "api"])
  }

  func testOpenFolderPathsReadsFolderWindows() {
    let json = """
      {"windowsState": {"openedWindows": [
        {"folder": "file:///Users/x/My%20Project", "backupPath": "/b/1"},
        {"workspaceIdentifier": {"id": "1", "configURIPath": "file:///Users/x/a.code-workspace"}},
        {"folder": "vscode-remote://ssh-remote%2Bbox/home/x/web"}
      ]}}
      """

    XCTAssertEqual(openFolderPaths(storageJSON: Data(json.utf8)), ["/Users/x/My Project"])
  }

  func testOpenFolderPathsOfUnreadableStateIsEmpty() {
    XCTAssertEqual(openFolderPaths(storageJSON: Data("not json".utf8)), [])
  }
}
