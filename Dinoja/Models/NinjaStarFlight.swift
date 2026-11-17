//
//  NinjaStarFlight.swift
//  Dinoja
//

import Foundation

/// The path of a thrown ninja star: it leaves at an angle toward the side the dino faces
/// and bounces off the side walls until it leaves the top of the screen.
struct NinjaStarFlight {
    struct Walls {
        let left: CGFloat
        let right: CGFloat
        let top: CGFloat
    }

    enum State: Equatable {
        case flying
        case bounced
        case offScreen
    }

    private(set) var position: CGPoint
    private(set) var velocity: CGVector
    let radius: CGFloat

    /// - Parameter angleDegrees: Angle above horizontal, e.g. `GameRules.starAngleDegrees`.
    init(from position: CGPoint, facingRight: Bool, angleDegrees: CGFloat, speed: CGFloat, radius: CGFloat) {
        self.position = position
        self.radius = radius
        let radians = angleDegrees * .pi / 180
        let across = speed * cos(radians)
        velocity = CGVector(dx: facingRight ? across : -across, dy: speed * sin(radians))
    }

    /// Moves the star forward by `dt` seconds, reflecting it off the side walls.
    @discardableResult
    mutating func advance(by dt: TimeInterval, within walls: Walls) -> State {
        position.x += velocity.dx * dt
        position.y += velocity.dy * dt

        if position.y - radius > walls.top {
            return .offScreen
        }

        // Reflect off a wall, keeping the star's edge inside it.
        if position.x + radius > walls.right {
            position.x = walls.right - radius
            velocity.dx = -abs(velocity.dx)
            return .bounced
        }
        if position.x - radius < walls.left {
            position.x = walls.left + radius
            velocity.dx = abs(velocity.dx)
            return .bounced
        }
        return .flying
    }
}
