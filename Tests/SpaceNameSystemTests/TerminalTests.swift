import XCTest
@testable import SpaceNameSystem

final class TerminalTests: XCTestCase {
  /// Runs against the Terminal on this machine, whichever windows it has at the moment: a window it cannot describe
  /// has to cost that window, not the whole read. Needs the permission to control Terminal.
  func testTheScriptSurvivesEveryWindowTerminalHasOpen() throws {
    try XCTSkipIf(Terminal.runningApp() == nil, "Terminal is not running")

    XCTAssertNotNil(Terminal.runScript())
  }
}
