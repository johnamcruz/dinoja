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
        #expect(dinoBody.contactTestBitMask == Collider.dino.contactTestBitMask)
        #expect(dinoBody.collisionBitMask == 0)

        let wasabiBody = try #require(scene.spawn(.wasabi).physicsBody)
        #expect(wasabiBody.categoryBitMask == Collider.wasabi.bitMask)

        let starBody = try #require(scene.throwStar().physicsBody)
        #expect(starBody.categoryBitMask == Collider.star.bitMask)
        #expect(starBody.contactTestBitMask == Collider.wasabi.bitMask)
    }

    // MARK: Spawning and movement

    @Test func itemsSpawnJustAboveTheVisibleTop() {
        let item = scene.spawn(.sushi(.ahi))
        let field = scene.playfield
        #expect(item.position.y == field.spawnY(objectHeight: item.size.height))
        #expect(field.spawnXRange(objectWidth: item.size.width).contains(item.position.x))
    }

    @Test func dinoStaysOnScreenWhenDraggedPastTheEdge() {
        // SpriteKit stores positions as 32-bit floats, so compare with a small tolerance.
        scene.moveDino(toX: 10_000)
        let rightEdge = scene.playfield.clampedX(10_000, objectWidth: scene.dino.size.width)
        #expect(abs(scene.dino.position.x - rightEdge) < 0.001)

        scene.moveDino(toX: -10_000)
        #expect(abs(scene.dino.position.x + rightEdge) < 0.001)
    }

    @Test func dinoFollowsTheFingerInsideTheScreen() {
        scene.moveDino(toX: 80)
        #expect(scene.dino.position.x == 80)
    }

    // MARK: Contacts

    @Test func catchingSushiScoresAndRemovesItsHitBox() {
        let sushi = scene.spawn(.sushi(.combo), atX: 0)
        scene.handleContact(between: scene.dino, and: sushi)
        #expect(scene.model.score == SushiKind.combo.points)
        #expect(sushi.physicsBody == nil)
    }

    @Test func contactOrderDoesNotMatter() {
        let sushi = scene.spawn(.sushi(.salmon), atX: 0)
        scene.handleContact(between: sushi, and: scene.dino)
        #expect(scene.model.score == SushiKind.salmon.points)
    }

    @Test func wasabiHitCostsALifeAndRemovesTheWasabi() {
        let wasabi = scene.spawn(.wasabi, atX: 0)
        scene.handleContact(between: scene.dino, and: wasabi)
        #expect(scene.model.lives == GameModel.startingLives - 1)
        #expect(wasabi.parent == nil)
    }

    @Test func wasabiPassesThroughWhileInvincible() {
        scene.handleContact(between: scene.dino, and: scene.spawn(.wasabi, atX: 0))
        let second = scene.spawn(.wasabi, atX: 0)
        scene.handleContact(between: scene.dino, and: second)
        #expect(scene.model.lives == GameModel.startingLives - 1)
        #expect(second.parent === scene)
    }

    @Test func threeHitsEndTheGame() {
        for _ in 0..<GameModel.startingLives {
            scene.handleContact(between: scene.dino, and: scene.spawn(.wasabi, atX: 0))
            scene.model.endInvincibility()
        }
        #expect(scene.model.phase == .gameOver)
    }

    @Test func starShootsDownWasabi() {
        let star = scene.throwStar()
        let wasabi = scene.spawn(.wasabi, atX: 0)
        scene.handleContact(between: star, and: wasabi)
        #expect(scene.model.score == GameModel.wasabiPoints)
        #expect(star.parent == nil)
        #expect(wasabi.parent == nil)
    }

    @Test func starPassesThroughSushi() {
        let star = scene.throwStar()
        let sushi = scene.spawn(.sushi(.ahi), atX: 0)
        scene.handleContact(between: star, and: sushi)
        #expect(scene.model.score == 0)
        #expect(star.parent === scene)
        #expect(sushi.parent === scene)
    }

    @Test func contactsAreIgnoredWhilePaused() {
        scene.model.pause()
        let wasabi = scene.spawn(.wasabi, atX: 0)
        scene.handleContact(between: scene.dino, and: wasabi)
        #expect(scene.model.lives == GameModel.startingLives)
        #expect(wasabi.parent === scene)
    }

    @Test func alreadyRemovedNodesAreIgnored() {
        // Two contacts for the same node can arrive in one physics step.
        let sushi = scene.spawn(.sushi(.ahi), atX: 0)
        sushi.removeFromParent()
        scene.handleContact(between: scene.dino, and: sushi)
        #expect(scene.model.score == 0)
    }
}
