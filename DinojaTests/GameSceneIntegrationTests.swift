//
//  GameSceneIntegrationTests.swift
//  DinojaTests
//
//  Exercises GameScene and GameModel together: the scene is loaded from
//  GameScene.sks and presented in a paused SKView, so timers don't spawn
//  anything on their own and each test controls exactly what happens.
//

import SpriteKit
import Testing
@testable import Dinoja

@MainActor
struct GameSceneIntegrationTests {
    private let scene: GameScene
    private let view: SKView

    init() {
        view = SKView(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        view.isPaused = true
        scene = GameScene.makeScene()
        view.presentScene(scene)
    }

    // MARK: Setup

    @Test func loadsTheLayoutFromTheSceneFile() {
        #expect(scene.dino.parent === scene)
        #expect(scene.childNode(withName: "background") != nil)
        // The lives sprite from the .sks is replaced by the SwiftUI hearts.
        #expect(scene.childNode(withName: "score") == nil)
    }

    @Test func dinoStandsOnTheGround() {
        let feet = scene.dino.position.y - scene.dino.size.height / 2
        #expect(abs(feet - -515) < 0.001)
    }

    @Test func physicsBodiesUseTheColliderMasks() throws {
        let dinoBody = try #require(scene.dino.physicsBody)
        #expect(dinoBody.categoryBitMask == Collider.dino.bitMask)
        #expect(dinoBody.contactTestBitMask == Collider.wasabi.bitMask)
        #expect(dinoBody.collisionBitMask == 0)

        #expect(scene.spawn(.wasabi).physicsBody?.categoryBitMask == Collider.wasabi.bitMask)
        #expect(scene.spawn(.redHeart).physicsBody?.categoryBitMask == Collider.target.bitMask)

        let star = try #require(scene.throwStar())
        #expect(star.physicsBody?.categoryBitMask == Collider.star.bitMask)
        #expect(star.physicsBody?.contactTestBitMask == Collider.target.bitMask)
    }

    // MARK: Rule 1: swipe to move

    @Test func swipingMovesTheDinoByTheSwipeDistance() {
        let start = scene.dino.position.x
        scene.moveDino(byX: 60)
        #expect(abs(scene.dino.position.x - (start + 60)) < 0.001)
    }

    @Test func swipingFlipsTheDinoToFaceTheSwipeDirection() {
        scene.moveDino(byX: -40)
        #expect(!scene.isFacingRight)
        scene.moveDino(byX: 40)
        #expect(scene.isFacingRight)
    }

    @Test func dinoStaysOnScreenWhenSwipedPastTheEdge() {
        // SpriteKit stores positions as 32-bit floats, so compare with a small tolerance.
        scene.moveDino(byX: 10_000)
        let rightEdge = scene.playfield.clampedX(10_000, objectWidth: scene.dino.size.width)
        #expect(abs(scene.dino.position.x - rightEdge) < 0.001)

        scene.moveDino(byX: -20_000)
        #expect(abs(scene.dino.position.x + rightEdge) < 0.001)
    }

    // MARK: Dino art when turning and when hit

    @Test func startsStandingFacingRight() {
        #expect(scene.pose == .standing(.right))
        #expect(scene.dinoImageName == Images.dinoRightStand)
    }

    @Test func swipingLeftWalksLeftThenStandsFacingLeft() {
        scene.moveDino(byX: -40)
        #expect(scene.pose == .walking(.left))
        scene.stopWalking()
        #expect(scene.pose == .standing(.left))
        #expect(scene.dinoImageName == Images.dinoLeftStand)
    }

    @Test func swipingRightAfterLeftTurnsBackRight() {
        scene.moveDino(byX: -40)
        scene.moveDino(byX: 40)
        #expect(scene.pose == .walking(.right))
        scene.stopWalking()
        #expect(scene.dinoImageName == Images.dinoRightStand)
    }

    @Test func wasabiHitShowsTheHitArtForTheFacingDirection() {
        scene.moveDino(byX: -40)
        scene.handleContact(between: scene.dino, and: scene.spawn(.wasabi, atX: 0))
        #expect(scene.pose == .hit(.left))
        #expect(scene.dinoImageName == Images.dinoLeftHit)
    }

    @Test func swipingDuringAHitKeepsTheHitPoseButTurns() {
        scene.handleContact(between: scene.dino, and: scene.spawn(.wasabi, atX: 0))
        scene.moveDino(byX: -40)
        #expect(scene.pose == .hit(.left))
        #expect(scene.dinoImageName == Images.dinoLeftHit)
    }

    @Test func afterAHitTheDinoStandsFacingItsCurrentDirection() {
        // Regression: the dino used to return to the direction it faced when it was hit.
        scene.handleContact(between: scene.dino, and: scene.spawn(.wasabi, atX: 0))
        scene.moveDino(byX: -40)
        scene.finishHitPose()
        #expect(scene.pose == .standing(.left))
        #expect(scene.dinoImageName == Images.dinoLeftStand)
    }

    // MARK: Rules 2–4: tap to throw, 45°, one at a time

    @Test func tappingThrowsAStarTowardTheWayTheDinoFaces() throws {
        let star = try #require(scene.throwStar())
        #expect(scene.model.isStarInFlight)
        #expect(star.position.x > scene.dino.position.x, "Facing right, the star leaves from the right hand")

        scene.starFlight.map { #expect($0.velocity.dx > 0 && $0.velocity.dy > 0) }
    }

    @Test func facingLeftThrowsUpAndLeft() throws {
        scene.moveDino(byX: -40)
        let star = try #require(scene.throwStar())
        #expect(star.position.x < scene.dino.position.x)
        let flight = try #require(scene.starFlight)
        #expect(flight.velocity.dx < 0)
    }

    @Test func onlyOneStarAtATime() {
        #expect(scene.throwStar() != nil)
        #expect(scene.throwStar() == nil)
        #expect(scene.children.filter { $0.name == Images.ninjaStar }.count == 1)
    }

    @Test func starFliesOffTheTopAndCanThenBeThrownAgain() {
        scene.throwStar()
        for _ in 0..<600 {
            scene.advanceStar(by: 1.0 / 60)
        }
        #expect(!scene.model.isStarInFlight)
        #expect(scene.children.allSatisfy { $0.name != Images.ninjaStar })
        #expect(scene.throwStar() != nil)
    }

    @Test func starStaysBetweenTheWalls() throws {
        let star = try #require(scene.throwStar())
        let limit = scene.playfield.visibleSize.width / 2
        for _ in 0..<120 where star.parent != nil {
            scene.advanceStar(by: 1.0 / 60)
            #expect(abs(star.position.x) <= limit)
        }
    }

    // MARK: Rules 6, 7, 11, 12: shooting targets

    @Test func shootingSushiScoresAndFreesTheStar() throws {
        let star = try #require(scene.throwStar())
        let sushi = scene.spawn(.sushi(.combo), atX: 0)
        scene.handleContact(between: star, and: sushi)
        #expect(scene.model.score == 2)
        #expect(star.parent == nil)
        #expect(sushi.parent == nil)
        #expect(!scene.model.isStarInFlight)
    }

    @Test func shootingARedHeartRestoresALife() throws {
        scene.handleContact(between: scene.dino, and: scene.spawn(.wasabi, atX: 0))
        let star = try #require(scene.throwStar())
        scene.handleContact(between: star, and: scene.spawn(.redHeart, atX: 0))
        #expect(scene.model.lives == 3)
    }

    @Test func shootingABlackHeartCostsALife() throws {
        let star = try #require(scene.throwStar())
        scene.handleContact(between: star, and: scene.spawn(.blackHeart, atX: 0))
        #expect(scene.model.lives == 2)
    }

    // MARK: Rules 5 and 10: wasabi

    @Test func starsPassThroughWasabi() throws {
        let star = try #require(scene.throwStar())
        let wasabi = scene.spawn(.wasabi, atX: 0)
        scene.handleContact(between: star, and: wasabi)
        #expect(star.parent === scene)
        #expect(wasabi.parent === scene)
        #expect(scene.model.isStarInFlight)
    }

    @Test func wasabiHitCostsALife() {
        let wasabi = scene.spawn(.wasabi, atX: 0)
        scene.handleContact(between: scene.dino, and: wasabi)
        #expect(scene.model.lives == 2)
        #expect(wasabi.parent == nil)
    }

    @Test func wasabiPassesThroughWhileInvincible() {
        scene.handleContact(between: scene.dino, and: scene.spawn(.wasabi, atX: 0))
        let second = scene.spawn(.wasabi, atX: 0)
        scene.handleContact(between: scene.dino, and: second)
        #expect(scene.model.lives == 2)
        #expect(second.parent === scene)
    }

    @Test func sushiTouchingTheDinoDoesNothing() {
        let sushi = scene.spawn(.sushi(.ahi), atX: 0)
        scene.handleContact(between: scene.dino, and: sushi)
        #expect(scene.model.score == 0)
        #expect(sushi.parent === scene)
    }

    @Test func threeHitsEndTheGame() {
        for _ in 0..<3 {
            scene.handleContact(between: scene.dino, and: scene.spawn(.wasabi, atX: 0))
            scene.model.endInvincibility()
        }
        #expect(scene.model.phase == .gameOver)
    }

    // MARK: Pause

    @Test func nothingHappensWhilePaused() {
        scene.model.pause()
        #expect(scene.throwStar() == nil)
        let wasabi = scene.spawn(.wasabi, atX: 0)
        scene.handleContact(between: scene.dino, and: wasabi)
        #expect(scene.model.lives == 3)
    }

    @Test func alreadyRemovedNodesAreIgnored() throws {
        // Two contacts for the same node can arrive in one physics step.
        let star = try #require(scene.throwStar())
        let sushi = scene.spawn(.sushi(.ahi), atX: 0)
        sushi.removeFromParent()
        scene.handleContact(between: star, and: sushi)
        #expect(scene.model.score == 0)
    }
}
