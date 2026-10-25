import XCTest
@testable import SpaceNameCore

final class SessionStateTests: XCTestCase {
  private let t0 = Date(timeIntervalSince1970: 1_000)

  private func live() -> SessionState {
    var state = SessionState(openedAt: t0)
    state.observe(.open, at: t0)
    return state
  }

  func testWaitingBecomesLiveOnFirstOpen() {
    var state = SessionState(openedAt: t0)
    XCTAssertEqual(state.phase, .waiting)

    state.observe(.open, at: t0 + 0.1)

    XCTAssertEqual(state.phase, .live)
  }

  func testWaitingEndsWithoutBarAfter1_5s() {
    var state = SessionState(openedAt: t0)

    state.observe(.closed, at: t0 + 1.0)
    XCTAssertEqual(state.phase, .waiting)
    state.observe(.failed, at: t0 + 1.6)

    XCTAssertEqual(state.phase, .ended)
  }

  func testLiveSurvivesShortClosedBlip() {
    var state = live()

    state.observe(.closed, at: t0 + 1.0)
    state.observe(.open, at: t0 + 1.1)
    state.observe(.closed, at: t0 + 1.2)
    state.observe(.closed, at: t0 + 1.35)

    XCTAssertEqual(state.phase, .live)
  }

  func testLiveEndsAfter200msClosed() {
    var state = live()

    state.observe(.closed, at: t0 + 1.0)
    state.observe(.closed, at: t0 + 1.2)

    XCTAssertEqual(state.phase, .ended)
  }

  func testFailedReadsNeverEndALiveSession() {
    var state = live()

    for step in 1...50 { state.observe(.failed, at: t0 + Double(step) * 0.1) }

    XCTAssertEqual(state.phase, .live)
  }

  func testFailedDoesNotResetClosedStreak() {
    var state = live()

    state.observe(.closed, at: t0 + 1.0)
    state.observe(.failed, at: t0 + 1.1)
    state.observe(.closed, at: t0 + 1.25)

    XCTAssertEqual(state.phase, .ended)
  }
}
