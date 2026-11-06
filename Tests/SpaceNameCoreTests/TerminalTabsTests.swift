import XCTest
@testable import SpaceNameCore

final class TerminalTabsParsingTests: XCTestCase {
  private func record(_ fields: String...) -> String {
    fields.joined(separator: "\u{1F}") + "\u{1E}"
  }

  private let laptop = CGRect(x: 2560, y: 392, width: 1728, height: 1048)

  func testTabTakesItsCustomTitleGlyphIncluded() {
    let output = record("464", "2560,392,4288,1440", "✳ Релиз v2.0.0", "tasker — ✳ Релиз v2.0.0 — 155×41") + "\n"

    XCTAssertEqual(parseTerminalTabs(output), [TerminalTab(windowID: 464, frame: laptop, title: "✳ Релиз v2.0.0")])
  }

  func testUntitledTabShowsItsWindowName() {
    let output = record("7", "2560,392,4288,1440", " ", "zsh — 80×24")

    XCTAssertEqual(parseTerminalTabs(output), [TerminalTab(windowID: 7, frame: laptop, title: "zsh — 80×24")])
  }

  func testMalformedRecordsAreSkipped() {
    let bounds = "2560,392,4288,1440"
    let output = record("x", bounds, "a", "b") + record("5", bounds, "only") + record("6", bounds, "", "")
      + record("9", "1,2,3", "a", "b") + record("8", bounds, "t", "dev — t")

    XCTAssertEqual(parseTerminalTabs(output), [TerminalTab(windowID: 8, frame: laptop, title: "t")])
  }
}

final class TerminalLabelsTests: XCTestCase {
  private let fullscreen = SpaceInfo(id: 30, isFullscreen: true, tileWindowIDs: [])
  private let desktop = SpaceInfo(id: 31, isFullscreen: false, tileWindowIDs: [])
  private var displays: [DisplayInfo] { [DisplayInfo(uuid: "A", spaces: [fullscreen, desktop])] }
  private let laptop = CGRect(x: 2560, y: 392, width: 1728, height: 1048)

  private func window(_ id: UInt32, on spaces: [UInt64], frame: CGRect? = nil) -> AppWindow {
    AppWindow(id: id, spaceIDs: spaces, frame: frame ?? laptop)
  }

  private func tab(_ id: UInt32, _ title: String, frame: CGRect? = nil) -> TerminalTab {
    TerminalTab(windowID: id, frame: frame ?? laptop, title: title)
  }

  func testHiddenTabsFollowTheFrontTabWhileMissionControlRedrawsIt() {
    let thumbnail = CGRect(x: 3496, y: 375, width: 188, height: 114)
    let windows = [window(6057, on: [30], frame: thumbnail), window(464, on: []), window(454, on: [])]
    let tabs = [tab(464, "◑ Релиз"), tab(6057, "✳ fix-spacename-review-notes"), tab(454, "✳ tasker")]

    XCTAssertEqual(terminalLabels(displays: displays, tabs: tabs, windows: windows)[30],
                   ["✳ tasker", "◑ Релиз", "✳ fix-spacename-review-notes"])
  }

  func testFrontTabIsOnItsSpace() {
    let labels = terminalLabels(displays: displays, tabs: [tab(464, "✳ tasker")], windows: [window(464, on: [30])])

    XCTAssertEqual(labels, [30: ["✳ tasker"]])
  }

  func testHiddenTabsJoinTheFrontTabWithTheirFrameInOpeningOrder() {
    let windows = [window(464, on: [30]), window(454, on: []), window(10244, on: [])]
    let tabs = [tab(10244, "t"), tab(464, "◑ Релиз"), tab(454, "✳ tasker")]

    XCTAssertEqual(terminalLabels(displays: displays, tabs: tabs, windows: windows), [30: ["✳ tasker", "◑ Релиз", "t"]])
  }

  func testHiddenTabIsLeftOutWhenTwoFrontTabsShareItsFrame() {
    let windows = [window(1, on: [30]), window(2, on: [31]), window(3, on: [])]
    let tabs = [tab(1, "a"), tab(2, "b"), tab(3, "c")]

    XCTAssertEqual(terminalLabels(displays: displays, tabs: tabs, windows: windows), [30: ["a"], 31: ["b"]])
  }

  func testHiddenTabWithoutAFrontTabIsLeftOut() {
    let windows = [window(1, on: [30]), window(2, on: [])]
    let tabs = [tab(1, "a"), tab(2, "b", frame: CGRect(x: 0, y: 25, width: 800, height: 600))]

    XCTAssertEqual(terminalLabels(displays: displays, tabs: tabs, windows: windows), [30: ["a"]])
  }

  func testOnlyTabsCountAsFrontTabs() {
    let windows = [window(1, on: [31]), window(2, on: [])]

    XCTAssertTrue(terminalLabels(displays: displays, tabs: [tab(2, "b")], windows: windows).isEmpty)
  }

  func testTabWhoseWindowIsGoneIsLeftOut() {
    XCTAssertEqual(terminalLabels(displays: displays, tabs: [tab(1, "a"), tab(9, "z")], windows: [window(1, on: [30])]), [30: ["a"]])
  }

  func testSameTitlesAreAllShown() {
    let windows = [window(1, on: [30]), window(2, on: [])]

    XCTAssertEqual(terminalLabels(displays: displays, tabs: [tab(1, "t"), tab(2, "t")], windows: windows)[30], ["t", "t"])
  }

  func testSplitViewTileCarriesItsHiddenTabs() {
    let split = SpaceInfo(id: 40, isFullscreen: true, tileWindowIDs: [5, 77])
    let windows = [window(5, on: [99]), window(6, on: [])]
    let labels = terminalLabels(displays: [DisplayInfo(uuid: "A", spaces: [split])], tabs: [tab(5, "a"), tab(6, "b")], windows: windows)

    XCTAssertEqual(labels, [40: ["a", "b"]])
  }

  func testWindowsSharingASpaceReadLeftToRight() {
    let left = CGRect(x: 2560, y: 392, width: 860, height: 1048)
    let right = CGRect(x: 3428, y: 392, width: 860, height: 1048)
    let windows = [window(3, on: [30]), window(9, on: [30]), window(4, on: [])]
    let tabs = [tab(3, "right", frame: right), tab(4, "right hidden", frame: right), tab(9, "left", frame: left)]

    XCTAssertEqual(terminalLabels(displays: displays, tabs: tabs, windows: windows)[30], ["left", "right", "right hidden"])
  }
}

final class CombinedLabelsTests: XCTestCase {
  func testVSCodeNamesComeBeforeTerminalTabs() {
    let combined = combinedLabels(code: [1: ["spacename"], 2: ["api"]], terminal: [1: ["✳ spacename"], 3: ["t"]])

    XCTAssertEqual(combined, [1: ["spacename", "✳ spacename"], 2: ["api"], 3: ["t"]])
  }
}
