//
//  ContactEvent.swift
//  Dinoja
//

/// The kinds of physics bodies in the game.
enum Collider: CaseIterable {
    case dino
    case wasabi
    /// Anything a ninja star can hit: sushi and hearts.
    case target
    case star

    /// Items stars can hit are targets; the rest (wasabi) only collide with the dino.
    init(for item: FallingItem, rules: GameRules = .standard) {
        self = rules.canBeShot(item) ? .target : .wasabi
    }

    /// The physics category bit for this collider.
    var bitMask: UInt32 {
        switch self {
        case .dino: 1 << 0
        case .wasabi: 1 << 1
        case .target: 1 << 2
        case .star: 1 << 3
        }
    }

    /// The categories this collider should report contacts with.
    var contactTestBitMask: UInt32 {
        switch self {
        case .dino: Collider.wasabi.bitMask
        case .wasabi: Collider.dino.bitMask
        case .target: Collider.star.bitMask
        case .star: Collider.target.bitMask
        }
    }

    init?(bitMask: UInt32) {
        guard let match = Collider.allCases.first(where: { $0.bitMask == bitMask }) else { return nil }
        self = match
    }
}

/// What a contact between two colliders means for the game.
enum ContactEvent: Equatable {
    /// Wasabi landed on the dino.
    case hitByWasabi
    /// A ninja star hit sushi or a heart.
    case shotTarget

    /// Returns `nil` for pairs that don't affect the game. The order of `a` and `b` doesn't matter.
    init?(_ a: Collider, _ b: Collider) {
        switch Set([a, b]) {
        case [.dino, .wasabi]: self = .hitByWasabi
        case [.star, .target]: self = .shotTarget
        default: return nil
        }
    }
}
