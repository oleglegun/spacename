import XCTest
@testable import SpaceNameCore

final class BarAssemblyTests: XCTestCase {
  private let display = CGRect(x: -2560, y: -323, width: 2560, height: 1440)
  private let thumbnail = CGRect(x: -1936, y: -295, width: 160, height: 90)

  func testBarWithAllFramesAssembles() {
    let bar = assembleBar(displayFrame: display, buttons: [(frame: thumbnail, labelFrame: nil)])

    XCTAssertEqual(bar, SpacesBar(displayFrame: display, buttons: [SpaceButton(frame: thumbnail, labelFrame: nil)]))
  }

  func testMissingButtonFrameFailsTheBar() {
    XCTAssertNil(assembleBar(displayFrame: display, buttons: [(frame: thumbnail, labelFrame: nil), (frame: nil, labelFrame: nil)]))
  }

  func testMissingDisplayFrameFailsTheBar() {
    XCTAssertNil(assembleBar(displayFrame: nil, buttons: [(frame: thumbnail, labelFrame: nil)]))
  }
}
