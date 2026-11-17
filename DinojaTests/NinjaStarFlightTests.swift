//
//  NinjaStarFlightTests.swift
//  DinojaTests
//

import CoreGraphics
import Testing
@testable import Dinoja

/// Rule 3: stars fly at 45° and bounce off the walls.
struct NinjaStarFlightTests {
    private let walls = NinjaStarFlight.Walls(left: -200, right: 200, top: 500)

    @Test func throwingRightGoesUpAndRightAtFortyFiveDegrees() {
        let flight = NinjaStarFlight(from: .zero, facingRight: true, angleDegrees: 45, speed: 1000, radius: 10)
        #expect(flight.velocity.dx > 0)
        #expect(flight.velocity.dy > 0)
        #expect(abs(flight.velocity.dx - flight.velocity.dy) < 0.0001)
        #expect(abs(hypot(flight.velocity.dx, flight.velocity.dy) - 1000) < 0.0001)
    }

    @Test func throwingLeftGoesUpAndLeft() {
        let flight = NinjaStarFlight(from: .zero, facingRight: false, angleDegrees: 45, speed: 1000, radius: 10)
        #expect(flight.velocity.dx < 0)
        #expect(flight.velocity.dy > 0)
        #expect(abs(-flight.velocity.dx - flight.velocity.dy) < 0.0001)
    }

    @Test func steeperAnglesGoMoreUpThanAcross() {
        let flight = NinjaStarFlight(from: .zero, facingRight: true, angleDegrees: 60, speed: 1000, radius: 10)
        #expect(flight.velocity.dy > flight.velocity.dx)
        #expect(abs(hypot(flight.velocity.dx, flight.velocity.dy) - 1000) < 0.0001)
    }

    @Test func advancingMovesAlongTheVelocity() {
        var flight = NinjaStarFlight(from: .zero, facingRight: true, angleDegrees: 45, speed: 100 * 2.squareRoot(), radius: 10)
        let state = flight.advance(by: 0.5, within: walls)
        #expect(state == .flying)
        #expect(abs(flight.position.x - 50) < 0.0001)
        #expect(abs(flight.position.y - 50) < 0.0001)
    }

    @Test func bouncesOffTheRightWall() {
        var flight = NinjaStarFlight(from: CGPoint(x: 185, y: 0), facingRight: true, angleDegrees: 45, speed: 100 * 2.squareRoot(), radius: 10)
        let state = flight.advance(by: 0.1, within: walls)
        #expect(state == .bounced)
        #expect(flight.velocity.dx < 0)
        // The star's edge never goes past the wall.
        #expect(flight.position.x + 10 <= 200)
    }

    @Test func bouncesOffTheLeftWall() {
        var flight = NinjaStarFlight(from: CGPoint(x: -185, y: 0), facingRight: false, angleDegrees: 45, speed: 100 * 2.squareRoot(), radius: 10)
        let state = flight.advance(by: 0.1, within: walls)
        #expect(state == .bounced)
        #expect(flight.velocity.dx > 0)
        #expect(flight.position.x - 10 >= -200)
    }

    @Test func bouncingKeepsTheUpwardSpeed() {
        var flight = NinjaStarFlight(from: CGPoint(x: 185, y: 0), facingRight: true, angleDegrees: 45, speed: 100 * 2.squareRoot(), radius: 10)
        let upward = flight.velocity.dy
        flight.advance(by: 0.1, within: walls)
        #expect(flight.velocity.dy == upward)
    }

    @Test func leavingTheTopEndsTheFlight() {
        var flight = NinjaStarFlight(from: CGPoint(x: 0, y: 495), facingRight: true, angleDegrees: 45, speed: 1000, radius: 10)
        let state = flight.advance(by: 0.1, within: walls)
        #expect(state == .offScreen)
    }

    @Test func zigZagsBetweenTheWallsUntilItLeaves() {
        var flight = NinjaStarFlight(from: CGPoint(x: 0, y: -400), facingRight: true, angleDegrees: 45, speed: 900, radius: 10)
        var bounces = 0
        var steps = 0
        while steps < 10_000 {
            steps += 1
            let state = flight.advance(by: 1.0 / 60, within: walls)
            if state == .bounced { bounces += 1 }
            if state == .offScreen { break }
            #expect(flight.position.x >= -190 && flight.position.x <= 190)
        }
        #expect(bounces >= 2)
        #expect(steps < 10_000, "The star should eventually leave the top")
    }
}
