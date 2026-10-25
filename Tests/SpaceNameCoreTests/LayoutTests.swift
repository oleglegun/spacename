import XCTest
@testable import SpaceNameCore

final class LayoutTests: XCTestCase {
  func testPillHangsBelowButtonByLabelGap() {
    let button = SpaceButton(frame: CGRect(x: 100, y: 20, width: 170, height: 92), labelFrame: nil)

    let frame = pillFrame(button: button, lineCount: 2, primaryScreenHeight: 1440)

    XCTAssertEqual(frame, CGRect(x: 100, y: 1440 - (112 + PillStyle.labelGap) - 38, width: 170, height: 38))
  }

  func testPillHangsBelowLabelWhenKnown() {
    let button = SpaceButton(frame: CGRect(x: 100, y: 20, width: 170, height: 92),
                             labelFrame: CGRect(x: 100, y: 115, width: 170, height: 15))

    let frame = pillFrame(button: button, lineCount: 1, primaryScreenHeight: 1440)

    XCTAssertEqual(frame, CGRect(x: 100, y: 1440 - 132 - 23, width: 170, height: 23))
  }

  private let screen = ScreenRef(uuid: "A", axFrame: CGRect(x: -2560, y: -323, width: 2560, height: 1440))
  private let display = DisplayInfo(uuid: "A", spaces: [
    SpaceInfo(id: 10, isFullscreen: true, tileWindowIDs: []),
    SpaceInfo(id: 11, isFullscreen: false, tileWindowIDs: []),
  ])

  private func bar(buttons count: Int, displayFrame: CGRect? = nil) -> SpacesBar {
    SpacesBar(displayFrame: displayFrame ?? CGRect(x: -2560, y: -323, width: 2560, height: 1440),
              buttons: (0..<count).map { SpaceButton(frame: CGRect(x: -1936 + CGFloat($0) * 192, y: -295, width: 160, height: 90), labelFrame: nil) })
  }

  func testZipsButtonsWithSpacesOnMatchedScreen() {
    let result = placements(bars: [bar(buttons: 2)], screens: [screen], displays: [display], labels: [11: ["admin"]])

    XCTAssertEqual(result, [Placement(spaceID: 11, button: bar(buttons: 2).buttons[1], names: ["admin"])])
  }

  func testSkipsBarWhenButtonCountDiffersFromSpaceCount() {
    let result = placements(bars: [bar(buttons: 3)], screens: [screen], displays: [display], labels: [10: ["a"], 11: ["b"]])

    XCTAssertEqual(result, [])
  }

  func testSkipsBarWithoutMatchingScreen() {
    let elsewhere = bar(buttons: 2, displayFrame: CGRect(x: 0, y: 0, width: 1728, height: 1117))

    XCTAssertEqual(placements(bars: [elsewhere], screens: [screen], displays: [display], labels: [11: ["admin"]]), [])
  }
}
