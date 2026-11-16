//
//  GameScene.swift
//  Dinoja
//
//  Created by John M Cruz on 10/1/23.
//

import SpriteKit

/// Bit masks used to detect contacts between game objects.
private enum PhysicsCategory {
    static let dino: UInt32 = 1 << 0
    static let sushi: UInt32 = 1 << 1
    static let wasabi: UInt32 = 1 << 2
    static let star: UInt32 = 1 << 3
}

/// Node names used to find objects in `GameScene.sks`.
private enum NodeName {
    static let background = "background"
    static let dino = "dinoja"
    static let lives = "score"   // The lives sprite in GameScene.sks is named "score".
}

/// The gameplay: the dino, falling items, ninja stars and collisions.
/// The score, hearts and overlays are drawn in SwiftUI from `model`.
class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    private(set) var model = GameModel()

    // MARK: Tuning

    private let dinoScale: CGFloat = 0.6
    private let groundY: CGFloat = -515           // top of the ground strip in the background art
    private let fireInterval: TimeInterval = 0.5
    private let invincibilityDuration: TimeInterval = 1.5

    // MARK: Nodes and state

    private var dino = SKSpriteNode()
    private var facingRight = true
    private var isInvincible = false

    private var isPlaying: Bool {
        model.phase == .playing
    }

    /// Creates the scene from `GameScene.sks`, sized to match the background art.
    static func makeScene() -> GameScene {
        let scene = GameScene(fileNamed: Images.gameScene) ?? GameScene()
        scene.size = CGSize(width: 640, height: 1140)
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.scaleMode = .aspectFill
        return scene
    }

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setUpBackground()
        setUpDino()

        // SwiftUI draws the hearts now, so drop the lives sprite from the .sks layout.
        childNode(withName: NodeName.lives)?.removeFromParent()

        let fire = SKAction.sequence([
            .onMain { [weak self] in self?.throwStar() },
            .wait(forDuration: fireInterval)
        ])
        run(.repeatForever(fire))
        scheduleNextSpawn()
    }

    /// Spawns one item, then schedules the next. Each wait is recalculated so
    /// items come faster as the difficulty rises (a fixed repeatForever can't do that).
    private func scheduleNextSpawn() {
        let interval = model.spawnInterval
        run(.sequence([
            .wait(forDuration: interval, withRange: interval * 0.4),
            .onMain { [weak self] in
                self?.spawnFallingItem()
                self?.scheduleNextSpawn()
            }
        ]))
    }

    // MARK: Setup

    private func setUpBackground() {
        if let background = childNode(withName: NodeName.background) {
            background.zPosition = -1
        } else {
            let background = SKSpriteNode(imageNamed: Images.background)
            background.name = NodeName.background
            background.zPosition = -1
            addChild(background)
        }
    }

    private func setUpDino() {
        if let existing = childNode(withName: NodeName.dino) as? SKSpriteNode {
            dino = existing
        } else {
            dino = SKSpriteNode(imageNamed: Images.dinoRightStand)
            dino.name = NodeName.dino
            addChild(dino)
        }

        dino.texture = SKTexture(imageNamed: Images.dinoRightStand)
        // Set the size directly (rather than xScale/yScale) so the physics body uses scene units.
        dino.size = CGSize(width: 275 * dinoScale, height: 241 * dinoScale)
        dino.position = CGPoint(x: 0, y: groundY + dino.size.height / 2)
        dino.zPosition = 20

        // The art has transparent padding, so the hit box is smaller than the sprite.
        let body = SKPhysicsBody(rectangleOf: CGSize(width: dino.size.width * 0.6,
                                                     height: dino.size.height * 0.7))
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.dino
        body.contactTestBitMask = PhysicsCategory.sushi | PhysicsCategory.wasabi
        body.collisionBitMask = 0
        dino.physicsBody = body
    }

    // MARK: Screen geometry

    /// The part of the scene that is actually on screen. `.aspectFill` crops the
    /// 640x1140 scene on devices with a different aspect ratio.
    private var visibleSize: CGSize {
        guard let view, view.bounds.width > 0, view.bounds.height > 0 else { return size }
        let scale = max(view.bounds.width / size.width, view.bounds.height / size.height)
        return CGSize(width: view.bounds.width / scale, height: view.bounds.height / scale)
    }

    // MARK: Spawning

    private func spawnFallingItem() {
        let isWasabi = Double.random(in: 0..<1) < model.wasabiChance
        let imageName = isWasabi
            ? Images.wasabi
            : [Images.sushiAhi, Images.sushiAvocado, Images.sushiSalmon, Images.sushiAhi,
               Images.sushiAvocado, Images.sushiSalmon, Images.sushiCombo].randomElement() ?? Images.sushiAhi

        let item = SKSpriteNode(imageNamed: imageName)
        item.name = imageName
        item.size = CGSize(width: 90, height: 90)
        let halfWidth = visibleSize.width / 2 - item.size.width / 2
        let top = visibleSize.height / 2 + item.size.height
        item.position = CGPoint(x: .random(in: -halfWidth...halfWidth), y: top)
        item.zPosition = 10

        let body = SKPhysicsBody(circleOfRadius: item.size.width * 0.4)
        body.affectedByGravity = false
        body.categoryBitMask = isWasabi ? PhysicsCategory.wasabi : PhysicsCategory.sushi
        body.contactTestBitMask = PhysicsCategory.dino
        body.collisionBitMask = 0
        item.physicsBody = body

        addChild(item)

        item.run(.sequence([
            .moveTo(y: -visibleSize.height / 2 - item.size.height, duration: model.fallDuration),
            .removeFromParent()
        ]))
    }

    private func throwStar() {
        let star = SKSpriteNode(imageNamed: Images.ninjaStar)
        star.position = CGPoint(x: dino.position.x, y: dino.position.y + dino.size.height / 3)
        star.zPosition = 15

        let body = SKPhysicsBody(circleOfRadius: star.size.width * 0.4)
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.star
        body.contactTestBitMask = PhysicsCategory.wasabi
        body.collisionBitMask = 0
        star.physicsBody = body

        addChild(star)

        let distance = visibleSize.height / 2 + star.size.height - star.position.y
        star.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 0.4)))
        star.run(.sequence([
            .moveBy(x: 0, y: distance, duration: TimeInterval(distance / 1100)),
            .removeFromParent()
        ]))
    }

    // MARK: Dino movement

    private func moveDino(toX targetX: CGFloat) {
        let limit = visibleSize.width / 2 - dino.size.width / 2
        let x = min(max(targetX, -limit), limit)
        guard abs(x - dino.position.x) > 1 else { return }

        // Only restart the walk cycle when the direction changes, so it doesn't
        // reset to the first frame on every touch event.
        let newFacingRight = x > dino.position.x
        let directionChanged = newFacingRight != facingRight
        facingRight = newFacingRight

        // Snap straight to the finger so the dino stays directly under it.
        dino.position.x = x

        if directionChanged || dino.action(forKey: "walk") == nil {
            let walkTextures = facingRight
                ? [Images.dinoRightWalkA, Images.dinoRightWalkB]
                : [Images.dinoLeftWalkA, Images.dinoLeftWalkB]
            dino.run(.repeatForever(.animate(with: walkTextures.map { SKTexture(imageNamed: $0) },
                                             timePerFrame: 0.1)),
                     withKey: "walk")
        }

        // Go back to standing once the finger stops moving. Each move replaces this timer.
        dino.run(.sequence([
            .wait(forDuration: 0.15),
            .onMain { [weak self] in self?.stopWalking() }
        ]), withKey: "stop")
    }

    private func stopWalking() {
        dino.removeAction(forKey: "walk")
        dino.removeAction(forKey: "stop")
        dino.texture = SKTexture(imageNamed: facingRight ? Images.dinoRightStand : Images.dinoLeftStand)
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlaying, let location = touches.first?.location(in: self) else { return }
        moveDino(toX: location.x)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlaying, let location = touches.first?.location(in: self) else { return }
        moveDino(toX: location.x)
    }

    // MARK: Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        guard isPlaying else { return }

        // Order the bodies so `first` always has the lower category bit.
        let (first, second) = contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask
            ? (contact.bodyA, contact.bodyB)
            : (contact.bodyB, contact.bodyA)

        // A node can be part of several contacts in the same frame; skip ones already removed.
        guard let firstNode = first.node, let secondNode = second.node,
              firstNode.parent != nil, secondNode.parent != nil else { return }

        switch (first.categoryBitMask, second.categoryBitMask) {
        case (PhysicsCategory.dino, PhysicsCategory.sushi):
            catchSushi(secondNode)
        case (PhysicsCategory.dino, PhysicsCategory.wasabi):
            dinoHit(by: secondNode)
        case (PhysicsCategory.wasabi, PhysicsCategory.star):
            destroyWasabi(firstNode, star: secondNode)
        default:
            break
        }
    }

    private func catchSushi(_ sushi: SKNode) {
        model.catchSushi(isCombo: sushi.name == Images.sushiCombo)
        sushi.removeAllActions()
        sushi.physicsBody = nil
        sushi.run(.sequence([
            .group([.scale(to: 0.2, duration: 0.15), .fadeOut(withDuration: 0.15)]),
            .removeFromParent()
        ]))
    }

    private func destroyWasabi(_ wasabi: SKNode, star: SKNode) {
        model.destroyWasabi()
        showBlast(Images.blastPurple, at: wasabi.position)
        wasabi.removeFromParent()
        star.removeFromParent()
    }

    private func dinoHit(by wasabi: SKNode) {
        // Right after a hit, wasabi passes through so back-to-back hits can't drain every life.
        guard !isInvincible else { return }

        showBlast(Images.blastRed, at: wasabi.position)
        wasabi.removeFromParent()
        model.takeHit()

        // Show the hit pose briefly, then return to standing.
        dino.removeAction(forKey: "walk")
        dino.removeAction(forKey: "stop")
        let hit = SKTexture(imageNamed: facingRight ? Images.dinoRightHit : Images.dinoLeftHit)
        let stand = SKTexture(imageNamed: facingRight ? Images.dinoRightStand : Images.dinoLeftStand)
        dino.texture = hit
        dino.run(.sequence([.wait(forDuration: 0.4), .setTexture(stand)]))

        guard isPlaying else { return }

        // Blink while invincible.
        isInvincible = true
        let blinkCount = Int(invincibilityDuration / 0.2)
        let blink = SKAction.sequence([.fadeAlpha(to: 0.3, duration: 0.1), .fadeAlpha(to: 1, duration: 0.1)])
        dino.run(.sequence([
            .repeat(blink, count: blinkCount),
            .onMain { [weak self] in self?.isInvincible = false }
        ]))
    }

    private func showBlast(_ imageName: String, at position: CGPoint) {
        let blast = SKSpriteNode(imageNamed: imageName)
        blast.position = position
        blast.zPosition = 30
        blast.setScale(0.5)
        addChild(blast)
        blast.run(.sequence([
            .group([.scale(to: 1.2, duration: 0.25), .fadeOut(withDuration: 0.25)]),
            .removeFromParent()
        ]))
    }
}

private extension SKAction {
    /// Runs `block` on the main queue. Swift 6 checks at runtime that main-actor code
    /// runs on the main thread, and SpriteKit doesn't promise which thread plain
    /// `run(_:)` blocks use, so this guarantees it.
    static func onMain(_ block: @escaping @MainActor () -> Void) -> SKAction {
        .run({ MainActor.assumeIsolated(block) }, queue: .main)
    }
}
