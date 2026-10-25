import XCTest
@testable import SpaceNameCore

final class FollowedProcessTests: XCTestCase {
  func testEmptyLookupKeepsALiveProcess() {
    XCTAssertEqual(followedProcess(current: 90619, found: nil, currentExited: false), 90619)
  }

  func testEmptyLookupLetsAnExitedProcessGo() {
    XCTAssertNil(followedProcess(current: 90619, found: nil, currentExited: true))
  }

  func testNewProcessReplacesTheOldOne() {
    XCTAssertEqual(followedProcess(current: 90619, found: 91000, currentExited: true), 91000)
  }

  func testFirstLookupStartsFollowing() {
    XCTAssertEqual(followedProcess(current: nil, found: 90619, currentExited: true), 90619)
  }
}
