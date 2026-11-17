//
//  DinoPose.swift
//  Dinoja
//
//  Which dino art to show. In the "left" art the dino faces left and holds the
//  star in its left hand; the "right" art mirrors that (see the design sheet).
//

enum Facing: Equatable, Sendable {
    case left
    case right

    /// The direction of a sideways swipe, or `nil` for no movement.
    init?(swipe dx: Double) {
        guard dx != 0 else { return nil }
        self = dx > 0 ? .right : .left
    }

    /// +1 for right, -1 for left: which side of the dino the throwing hand is on.
    var sign: Double {
        self == .right ? 1 : -1
    }
}

enum DinoPose: Equatable, Sendable {
    case standing(Facing)
    case walking(Facing, frame: Int = 0)
    case hit(Facing)

    var facing: Facing {
        switch self {
        case .standing(let facing), .walking(let facing, _), .hit(let facing):
            facing
        }
    }

    var imageName: String {
        switch self {
        case .standing(.left): Images.dinoLeftStand
        case .standing(.right): Images.dinoRightStand
        case .walking(.left, let frame): frame.isMultiple(of: 2) ? Images.dinoLeftWalkA : Images.dinoLeftWalkB
        case .walking(.right, let frame): frame.isMultiple(of: 2) ? Images.dinoRightWalkA : Images.dinoRightWalkB
        case .hit(.left): Images.dinoLeftHit
        case .hit(.right): Images.dinoRightHit
        }
    }

    /// The two walking frames, played in a loop while the dino moves.
    static func walkCycle(_ facing: Facing) -> [DinoPose] {
        [.walking(facing, frame: 0), .walking(facing, frame: 1)]
    }
}
