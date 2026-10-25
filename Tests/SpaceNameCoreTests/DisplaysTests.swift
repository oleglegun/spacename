import XCTest
@testable import SpaceNameCore

final class DisplaysTests: XCTestCase {
  private let raw: [[String: Any]] = [
    ["Display Identifier": "00000000-0000-0000-0000-00000000000A",
     "Spaces": [
       ["ManagedSpaceID": 6788, "type": 4,
        "TileLayoutManager": ["TileSpaces": [["TileWindowID": 302764], ["TileWindowID": 261925]]]],
       ["ManagedSpaceID": 6877, "type": 0],
     ]],
    ["Display Identifier": "00000000-0000-0000-0000-00000000000B",
     "Spaces": [["ManagedSpaceID": 5981, "type": 4]]],
  ]

  func testParsesSpacesInBarOrderPerDisplay() {
    let displays = parseDisplays(raw)

    XCTAssertEqual(displays.map(\.uuid), ["00000000-0000-0000-0000-00000000000A", "00000000-0000-0000-0000-00000000000B"])
    XCTAssertEqual(displays[0].spaces, [
      SpaceInfo(id: 6788, isFullscreen: true, tileWindowIDs: [302764, 261925]),
      SpaceInfo(id: 6877, isFullscreen: false, tileWindowIDs: []),
    ])
    XCTAssertEqual(displays[1].spaces, [SpaceInfo(id: 5981, isFullscreen: true, tileWindowIDs: [])])
  }

  func testSkipsMalformedEntries() {
    let malformed: [[String: Any]] = [
      ["Spaces": [["ManagedSpaceID": 1, "type": 0]]],
      ["Display Identifier": "A", "Spaces": [["type": 0], ["ManagedSpaceID": 2, "type": 0]]],
    ]

    XCTAssertEqual(parseDisplays(malformed), [DisplayInfo(uuid: "A", spaces: [SpaceInfo(id: 2, isFullscreen: false, tileWindowIDs: [])])])
  }

  func testCandidateFilterDropsHelperStrips() {
    XCTAssertTrue(isCandidateMainWindow(CGRect(x: 0, y: 0, width: 2560, height: 1440)))
    XCTAssertTrue(isCandidateMainWindow(CGRect(x: 0, y: 0, width: 1191, height: 1440)))
    XCTAssertFalse(isCandidateMainWindow(CGRect(x: 0, y: 0, width: 2560, height: 44)))
    XCTAssertFalse(isCandidateMainWindow(CGRect(x: 0, y: 0, width: 13, height: 1440)))
    XCTAssertFalse(isCandidateMainWindow(CGRect(x: 0, y: 0, width: 1728, height: 37)))
  }

  func testKnownTitleRejectsBlankAndPlaceholder() {
    XCTAssertEqual(knownTitle(" web "), "web")
    XCTAssertNil(knownTitle(nil))
    XCTAssertNil(knownTitle(""))
    XCTAssertNil(knownTitle("  "))
    XCTAssertNil(knownTitle("Visual Studio Code"))
  }
}
