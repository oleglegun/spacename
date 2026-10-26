import XCTest
@testable import SpaceNameCore

final class IDScanEndTests: XCTestCase {
  func testEndsAfterDeadRunPastLastLiveID() {
    var end = IDScanEnd(deadRun: 3)

    XCTAssertFalse(end.reached(after: 0, live: true))
    XCTAssertFalse(end.reached(after: 1, live: true))
    XCTAssertFalse(end.reached(after: 2, live: false))
    XCTAssertFalse(end.reached(after: 3, live: false))
    XCTAssertTrue(end.reached(after: 4, live: false))
  }

  func testGapShorterThanDeadRunDoesNotEnd() {
    var end = IDScanEnd(deadRun: 3)

    XCTAssertFalse(end.reached(after: 0, live: true))
    XCTAssertFalse(end.reached(after: 1, live: false))
    XCTAssertFalse(end.reached(after: 2, live: false))
    XCTAssertFalse(end.reached(after: 3, live: true))
    XCTAssertFalse(end.reached(after: 5, live: false))
    XCTAssertTrue(end.reached(after: 6, live: false))
  }

  func testAppWithNoLiveIDsEndsAfterDeadRun() {
    var end = IDScanEnd(deadRun: 3)

    XCTAssertFalse(end.reached(after: 0, live: false))
    XCTAssertFalse(end.reached(after: 2, live: false))
    XCTAssertTrue(end.reached(after: 3, live: false))
  }
}
