import XCTest
@testable import MultiplesCore

final class MultiplesGameTests: XCTestCase {
    func testEmptyInputIsRejected() {
        var game = MultiplesGame()
        XCTAssertFalse(game.start(input: "   "))
        XCTAssertEqual(game.session.error, .emptyInput)
    }

    func testNonIntegerInputIsRejected() {
        var game = MultiplesGame()
        XCTAssertFalse(game.start(input: "2.5"))
        XCTAssertEqual(game.session.error, .notAnInteger)
    }

    func testOutOfRangeValuesAreRejected() {
        var game = MultiplesGame()
        XCTAssertFalse(game.start(input: "0"))
        XCTAssertEqual(game.session.error, .outsideAllowedRange)
        XCTAssertFalse(game.start(input: "1001"))
    }

    func testWhitespaceWrappedIntegerStartsSession() {
        var game = MultiplesGame()
        XCTAssertTrue(game.start(input: " 7\n"))
        XCTAssertEqual(game.session, MultiplesSession(phase: .playing, multiplier: 7))
        XCTAssertEqual(game.target, 35)
    }

    func testEachAddAdvancesDeterministically() {
        var game = MultiplesGame(); XCTAssertTrue(game.start(input: "3"))
        XCTAssertTrue(game.add()); XCTAssertEqual(game.session.sum, 3)
        XCTAssertTrue(game.add()); XCTAssertEqual(game.session.sum, 6)
        XCTAssertEqual(game.session.additions, 2)
    }

    func testFifthAddCompletesJourney() {
        var game = MultiplesGame(); XCTAssertTrue(game.start(input: "4"))
        for _ in 0..<5 { XCTAssertTrue(game.add()) }
        XCTAssertEqual(game.session.phase, .completed)
        XCTAssertEqual(game.session.sum, 20)
    }

    func testAddingWithoutSessionFailsSafely() {
        var game = MultiplesGame()
        XCTAssertFalse(game.add())
        XCTAssertEqual(game.session.error, .noActiveSession)
    }

    func testResetReturnsEmptyConfiguration() {
        var game = MultiplesGame(); XCTAssertTrue(game.start(input: "9")); XCTAssertTrue(game.add())
        game.reset()
        XCTAssertEqual(game.session, MultiplesSession())
    }

    func testCodableStateRoundTrips() throws {
        var game = MultiplesGame(); XCTAssertTrue(game.start(input: "11")); XCTAssertTrue(game.add())
        let data = try JSONEncoder().encode(game.session)
        XCTAssertEqual(try JSONDecoder().decode(MultiplesSession.self, from: data), game.session)
    }

    func testMalformedRestoredArithmeticIsSanitized() {
        let bad = MultiplesSession(phase: .playing, multiplier: 3, sum: 99, additions: 1)
        XCTAssertEqual(MultiplesGame(session: bad).session, MultiplesSession())
    }

    func testMalformedRestoredPhaseIsSanitized() {
        let bad = MultiplesSession(phase: .completed, multiplier: 3, sum: 3, additions: 1)
        XCTAssertEqual(MultiplesGame(session: bad).session, MultiplesSession())
    }

    func testUserDefaultsStoreRestoresAndClears() throws {
        let suite = "MultiplesGameTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MultiplesSessionStore(defaults: defaults, key: "state")
        let state = MultiplesSession(phase: .playing, multiplier: 8, sum: 16, additions: 2)
        try store.save(state); XCTAssertEqual(store.restore(), state)
        store.clear(); XCTAssertNil(store.restore())
    }

    func testStoreRejectsMalformedJSON() throws {
        let suite = "MultiplesGameTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("bad".utf8), forKey: "state")
        XCTAssertNil(MultiplesSessionStore(defaults: defaults, key: "state").restore())
    }
}
