//
//  GameScene.swift
//  Dinoja
//
//  Created by John M Cruz on 10/1/23.
//

import SpriteKit

/// Node names used to find objects in `GameScene.sks`.
private enum NodeName {
    static let background = "background"
    static let dino = "dinoja"
    static let lives = "score"   // The lives sprite in GameScene.sks is named "score".
}

/// Renders the gameplay: the dino, falling items, ninja stars and collisions.
/// Game rules live in `GameModel`, `FallingItem`, `ContactEvent` and `Playfield`;
/// this class turns them into sprites and forwards what happens back to `model`.
class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    private(set) var model = GameModel()

    // MARK: Tuning

    private let dinoScale: CGFloat = 0.6
    private let groundY: CGFloat = -515           // top of the ground strip in the background art
    private let itemSize = CGSize(width: 90, height: 90)
    private let starSpeed: CGFloat = 1100         // points per second
    private let fireInterval: TimeInterval = 0.5
    private let invincibilityDuration: TimeInterval = 1.5

    // MARK: Nodes and state

    private(set) var dino = SKSpriteNode()
    private var facingRight = true

    private var isPlaying: Bool {
        model.phase == .playing
    }

    /// The on-screen area, accounting for `.aspectFill` cropping.
    var playfield: Playfield {
        Playfield(sceneSize: size, viewSize: view?.bounds.size ?? .zero)
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

        // SwiftUI draws the hearts, so drop the lives sprite from the .sks layout.
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
                guard let self else { return }
                spawn(.random(wasabiChance: model.wasabiChance))
                scheduleNextSpawn()
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
        body.allowsRotation = false
        dino.physicsBody = configured(body, as: .dino)
    }

    /// Applies the bit masks for `collider`. Nothing in the game bounces off anything else,
    /// so collisions are off and only contacts are reported.
    private func configured(_ body: SKPhysicsBody, as collider: Collider) -> SKPhysicsBody {
        body.affectedByGravity = false
        body.categoryBitMask = collider.bitMask
        body.contactTestBitMask = collider.contactTestBitMask
        body.collisionBitMask = 0
        return body
    }

    // MARK: Spawning

    /// Drops `item` from the top of the screen at `x`, or at a random x if `nil`.
    @discardableResult
    func spawn(_ item: FallingItem, atX x: CGFloat? = nil) -> SKSpriteNode {
        let field = playfield
        let node = SKSpriteNode(imageNamed: item.imageName)
        node.name = item.imageName
        node.size = itemSize
        node.position = CGPoint(x: x ?? .random(in: field.spawnXRange(objectWidth: itemSize.width)),
                                y: field.spawnY(objectHeight: itemSize.height))
        node.zPosition = 10

        let collider: Collider = item == .wasabi ? .wasabi : .sushi
        node.physicsBody = configured(SKPhysicsBody(circleOfRadius: itemSize.width * 0.4), as: collider)

        addChild(node)
        node.run(.sequence([
            .moveTo(y: field.despawnY(objectHeight: itemSize.height), duration: model.fallDuration),
            .removeFromParent()
        ]))
        return node
    }

    @discardableResult
    func throwStar() -> SKSpriteNode {
        let star = SKSpriteNode(imageNamed: Images.ninjaStar)
        star.position = CGPoint(x: dino.position.x, y: dino.position.y + dino.size.height / 3)
        star.zPosition = 15
        star.physicsBody = configured(SKPhysicsBody(circleOfRadius: star.size.width * 0.4), as: .star)

        addChild(star)

        let distance = playfield.spawnY(objectHeight: star.size.height) - star.position.y
        star.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 0.4)))
        star.run(.sequence([
            .moveBy(x: 0, y: distance, duration: TimeInterval(distance / starSpeed)),
            .removeFromParent()
        ]))
        return star
    }

    // MARK: Dino movement

    func moveDino(toX targetX: CGFloat) {
        let x = playfield.clampedX(targetX, objectWidth: dino.size.width)
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
        guard let a = contact.bodyA.node, let b = contact.bodyB.node else { return }
        handleContact(between: a, and: b)
    }

    /// Applies the game effect of two nodes touching. Separate from `didBegin(_:)`
    /// so tests can drive it without a physics simulation.
    func handleContact(between a: SKNode, and b: SKNode) {
        guard isPlaying,
              // A node can be part of several contacts in the same frame; skip ones already removed.
              a.parent != nil, b.parent != nil,
              let colliderA = a.physicsBody.flatMap({ Collider(bitMask: $0.categoryBitMask) }),
              let colliderB = b.physicsBody.flatMap({ Collider(bitMask: $0.categoryBitMask) }),
              let event = ContactEvent(colliderA, colliderB) else { return }

        // The item is whichever node isn't the dino or the star.
        let item = colliderA == .sushi || colliderA == .wasabi ? a : b
        let star = colliderA == .star ? a : b

        switch event {
        case .caughtSushi:
            catchSushi(item)
        case .hitByWasabi:
            dinoHit(by: item)
        case .shotWasabi:
            destroyWasabi(item, star: star)
        }
    }

    private func catchSushi(_ sushi: SKNode) {
        if case .sushi(let kind) = sushi.name.flatMap(FallingItem.init(imageName:)) {
            model.collect(kind)
        }
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
        // While invincible, wasabi passes straight through.
        guard !model.isInvincible else { return }

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

        guard model.isInvincible else { return }

        // Blink until invincibility ends.
        let blinkCount = Int(invincibilityDuration / 0.2)
        let blink = SKAction.sequence([.fadeAlpha(to: 0.3, duration: 0.1), .fadeAlpha(to: 1, duration: 0.1)])
        dino.run(.sequence([
            .repeat(blink, count: blinkCount),
            .onMain { [weak self] in self?.model.endInvincibility() }
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
