import XCTest
@testable import SpaceNameCore

final class BarAssemblyTests: XCTestCase {
  private let display = CGRect(x: -2560, y: 0, width: 2560, height: 1440)
  private let button = CGRect(x: -1376, y: 77.5, width: 190, height: 129)

  func testBarWithAllFramesAssembles() {
    let bar = assembleBar(displayFrame: display, buttons: [button])

    XCTAssertEqual(bar, SpacesBar(displayFrame: display, buttons: [SpaceButton(frame: button)]))
  }

  func testMissingButtonFrameFailsTheBar() {
    XCTAssertNil(assembleBar(displayFrame: display, buttons: [button, nil]))
  }

  func testReportedButtonPositionIsItsCenter() {
    let reported = CGRect(x: 1568, y: 77.5, width: 190, height: 129)

    XCTAssertEqual(spaceButtonFrame(reported: reported), CGRect(x: 1473, y: 13, width: 190, height: 129))
  }

  func testMissingDisplayFrameFailsTheBar() {
    XCTAssertNil(assembleBar(displayFrame: nil, buttons: [button]))
  }
}
