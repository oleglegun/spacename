import XCTest
@testable import SpaceNameSystem

final class ProcessTests: XCTestCase {
  func testRunningProcessHasNotExited() {
    XCTAssertFalse(processExited(getpid()))
  }

  func testLaunchdIsAliveEvenWithoutPermissionToSignalIt() {
    XCTAssertFalse(processExited(1))
  }

  func testMissingProcessHasExited() {
    XCTAssertTrue(processExited(99_999_999))
  }
}
