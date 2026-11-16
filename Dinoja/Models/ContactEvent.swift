//
//  ContactEvent.swift
//  Dinoja
//

/// The kinds of physics bodies in the game.
enum Collider: CaseIterable {
    case dino
    case sushi
    case wasabi
    case star

    /// The physics category bit for this collider.
    var bitMask: UInt32 {
        switch self {
        case .dino: 1 << 0
        case .sushi: 1 << 1
        case .wasabi: 1 << 2
        case .star: 1 << 3
        }
    }

    /// The categories this collider should report contacts with.
    var contactTestBitMask: UInt32 {
        switch self {
        case .dino: Collider.sushi.bitMask | Collider.wasabi.bitMask
        case .sushi, .wasabi: Collider.dino.bitMask
        case .star: Collider.wasabi.bitMask
        }
    }

    init?(bitMask: UInt32) {
        guard let match = Collider.allCases.first(where: { $0.bitMask == bitMask }) else { return nil }
        self = match
    }
}

/// What a contact between two colliders means for the game.
enum ContactEvent: Equatable {
    case caughtSushi
    case hitByWasabi
    case shotWasabi

    /// Returns `nil` for pairs that don't affect the game. The order of `a` and `b` doesn't matter.
    init?(_ a: Collider, _ b: Collider) {
        switch Set([a, b]) {
        case [.dino, .sushi]: self = .caughtSushi
        case [.dino, .wasabi]: self = .hitByWasabi
        case [.star, .wasabi]: self = .shotWasabi
        default: return nil
        }
    }
}
