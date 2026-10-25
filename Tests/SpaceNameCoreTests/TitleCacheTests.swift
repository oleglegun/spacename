import XCTest
@testable import SpaceNameCore

final class TitleCacheTests: XCTestCase {
  func testPruneDropsClosedWindows() {
    var cache = TitleCache()
    cache.set("backend", for: 1)
    cache.set("admin", for: 2)

    cache.prune(keeping: [2])

    XCTAssertEqual(cache.titles, [2: "admin"])
  }

  func testSetReplacesTitle() {
    var cache = TitleCache()
    cache.set("backend", for: 1)

    cache.set("web", for: 1)

    XCTAssertEqual(cache.titles, [1: "web"])
  }

  func testPlaceholderTitleIsNotCachedAndStaysMissing() {
    var cache = TitleCache()
    cache.set("Visual Studio Code", for: 7)
    cache.set("admin", for: 8)
    cache.set("", for: 8)

    XCTAssertNil(cache.titles[7])
    XCTAssertNil(cache.titles[8])
    XCTAssertEqual(cache.missing([7, 8]), [7, 8])
  }

  func testMissingListsUncachedCandidates() {
    var cache = TitleCache()
    cache.set("backend", for: 1)

    XCTAssertEqual(cache.missing([1, 2, 3]), [2, 3])
  }

  func testDueSkipsRecentlyAttempted() {
    var throttle = BruteForceThrottle()
    let t0 = Date(timeIntervalSince1970: 1_000)

    XCTAssertEqual(throttle.due([1, 2], now: t0), [1, 2])
    XCTAssertEqual(throttle.due([1, 2, 3], now: t0 + 10), [3])
    XCTAssertEqual(throttle.due([1], now: t0 + 301), [1])
  }
}
