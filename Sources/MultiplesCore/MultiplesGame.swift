import Foundation

public enum MultiplesValidationError: String, Codable, Error, Equatable {
    case emptyInput
    case notAnInteger
    case outsideAllowedRange
    case noActiveSession
}

public enum MultiplesPhase: String, Codable, Equatable {
    case configuring
    case playing
    case completed
}

public struct MultiplesSession: Codable, Equatable {
    public var phase: MultiplesPhase
    public var multiplier: Int?
    public var sum: Int
    public var additions: Int
    public var error: MultiplesValidationError?

    public init(
        phase: MultiplesPhase = .configuring,
        multiplier: Int? = nil,
        sum: Int = 0,
        additions: Int = 0,
        error: MultiplesValidationError? = nil
    ) {
        self.phase = phase
        self.multiplier = multiplier
        self.sum = sum
        self.additions = additions
        self.error = error
    }
}

public struct MultiplesGame {
    public static let allowedMultiplier = 1...1_000
    public static let requiredAdditions = 5
    public private(set) var session: MultiplesSession

    public init(session: MultiplesSession = MultiplesSession()) {
        self.session = Self.sanitized(session)
    }

    @discardableResult
    public mutating func start(input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fail(.emptyInput) }
        guard let value = Int(trimmed) else { return fail(.notAnInteger) }
        guard Self.allowedMultiplier.contains(value) else { return fail(.outsideAllowedRange) }
        session = MultiplesSession(phase: .playing, multiplier: value)
        return true
    }

    @discardableResult
    public mutating func add() -> Bool {
        guard session.phase == .playing, let multiplier = session.multiplier else {
            return fail(.noActiveSession)
        }
        session.sum += multiplier
        session.additions += 1
        session.error = nil
        if session.additions >= Self.requiredAdditions { session.phase = .completed }
        return true
    }

    public mutating func reset() { session = MultiplesSession() }

    public var target: Int? { session.multiplier.map { $0 * Self.requiredAdditions } }

    private mutating func fail(_ error: MultiplesValidationError) -> Bool {
        session.error = error
        return false
    }

    private static func sanitized(_ candidate: MultiplesSession) -> MultiplesSession {
        guard let multiplier = candidate.multiplier else {
            return candidate.phase == .configuring ? candidate : MultiplesSession()
        }
        guard allowedMultiplier.contains(multiplier),
              (0...requiredAdditions).contains(candidate.additions),
              candidate.sum == multiplier * candidate.additions else {
            return MultiplesSession()
        }
        let expectedPhase: MultiplesPhase = candidate.additions == requiredAdditions ? .completed : .playing
        guard candidate.phase == expectedPhase else { return MultiplesSession() }
        return candidate
    }
}

public struct MultiplesSessionStore {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "multiples.session.v1") {
        self.defaults = defaults
        self.key = key
    }

    public func save(_ session: MultiplesSession) throws {
        defaults.set(try JSONEncoder().encode(session), forKey: key)
    }

    public func restore() -> MultiplesSession? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(MultiplesSession.self, from: data)
    }

    public func clear() { defaults.removeObject(forKey: key) }
}
