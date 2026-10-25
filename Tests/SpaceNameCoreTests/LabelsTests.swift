import XCTest
@testable import SpaceNameCore

final class LabelsTests: XCTestCase {
  private let splitView = SpaceInfo(id: 6788, isFullscreen: true, tileWindowIDs: [302764, 261925])
  private let desktop = SpaceInfo(id: 6877, isFullscreen: false, tileWindowIDs: [])
  private var displays: [DisplayInfo] { [DisplayInfo(uuid: "A", spaces: [splitView, desktop])] }

  private func window(_ id: UInt32, on spaces: [UInt64], minX: CGFloat = 0) -> CodeWindow {
    CodeWindow(id: id, spaceIDs: spaces, frame: CGRect(x: minX, y: 0, width: 1200, height: 1440))
  }

  func testSplitViewListsLeftToRight() {
    let windows = [window(302764, on: [6788], minX: 1369), window(261925, on: [6788], minX: 0)]
    let titles: [UInt32: String] = [302764: "api", 261925: "web"]

    XCTAssertEqual(spaceLabels(displays: displays, windows: windows, titles: titles)[6788], ["web", "api"])
  }

  func testTileWindowsCountEvenWhenSpaceIDsDiffer() {
    let labels = spaceLabels(displays: displays, windows: [window(302764, on: [99])], titles: [302764: "docs"])

    XCTAssertEqual(labels[6788], ["docs"])
  }

  func testDesktopListsAlphabetically() {
    let windows = [window(1, on: [6877]), window(2, on: [6877])]

    XCTAssertEqual(spaceLabels(displays: displays, windows: windows, titles: [1: "backend", 2: "admin"])[6877], ["admin", "backend"])
  }

  func testWindowsWithoutTitleAreOmitted() {
    let windows = [window(1, on: [6877]), window(2, on: [6877])]

    XCTAssertEqual(spaceLabels(displays: displays, windows: windows, titles: [2: "admin"])[6877], ["admin"])
    XCTAssertNil(spaceLabels(displays: displays, windows: [window(1, on: [6877])], titles: [:])[6877])
  }

  func testDuplicateNamesCollapse() {
    let windows = [window(1, on: [6877]), window(2, on: [6877])]

    XCTAssertEqual(spaceLabels(displays: displays, windows: windows, titles: [1: "backend", 2: "backend"])[6877], ["backend"])
  }

  func testWindowOnSeveralSpacesIsIgnored() {
    let labels = spaceLabels(displays: displays, windows: [window(1, on: [6877, 6788])], titles: [1: "admin"])

    XCTAssertTrue(labels.isEmpty)
  }

  func testSpaceWithoutCodeWindowsIsAbsent() {
    let labels = spaceLabels(displays: displays, windows: [window(1, on: [6877])], titles: [1: "admin"])

    XCTAssertEqual(Array(labels.keys), [6877])
  }
}
