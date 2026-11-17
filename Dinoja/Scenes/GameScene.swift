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

/// Renders the gameplay: the dino, falling items, the ninja star and collisions.
/// Every rule comes from `GameRules` (via `model.rules`); this class turns them into
/// sprites and reports what happens to `model`.
class GameScene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    private(set) var model = GameModel()

    // MARK: Tuning

    private let dinoScale: CGFloat = 0.6
    private let groundY: CGFloat = -515           // top of the ground strip in the background art
    private let itemSize = CGSize(width: 90, height: 90)

    // MARK: Nodes and state

    private(set) var dino = SKSpriteNode()
    /// The dino art currently showing. Every texture change goes through `show(_:)`.
    private(set) var pose = DinoPose.standing(.right)
    private var starNode: SKSpriteNode?
    private(set) var starFlight: NinjaStarFlight?

    // Touch tracking for telling swipes from taps.
    private var touchStartX: CGFloat = 0
    private var lastTouchX: CGFloat = 0
    private var isSwiping = false
    private var lastUpdateTime: TimeInterval?

    var isFacingRight: Bool {
        pose.facing == .right
    }

    /// The image name of the dino's current texture (the first frame while walking).
    private(set) var dinoImageName = DinoPose.standing(.right).imageName

    private var isShowingHit: Bool {
        if case .hit = pose { return true }
        return false
    }

    private var rules: GameRules {
        model.rules
    }

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

        let spawn = SKAction.sequence([
            .wait(forDuration: rules.spawnInterval, withRange: rules.spawnInterval * 0.4),
            .onMain { [weak self] in
                guard let self else { return }
                spawn(rules.randomItem())
            }
        ])
        run(.repeatForever(spawn))
    }

    override func update(_ currentTime: TimeInterval) {
        // Cap the step so the star doesn't jump after a pause or a dropped frame.
        let dt = min(currentTime - (lastUpdateTime ?? currentTime), 1.0 / 30)
        lastUpdateTime = currentTime
        advanceStar(by: dt)
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
            dino = SKSpriteNode(imageNamed: DinoPose.standing(.right).imageName)
            dino.name = NodeName.dino
            addChild(dino)
        }

        show(.standing(.right))
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

    /// Applies the bit masks for `collider`. Nothing in the game bounces off anything else
    /// through physics, so collisions are off and only contacts are reported.
    private func configured(_ body: SKPhysicsBody, as collider: Collider) -> SKPhysicsBody {
        body.affectedByGravity = false
        body.categoryBitMask = collider.bitMask
        body.contactTestBitMask = collider.contactTestBitMask
        body.collisionBitMask = 0
        return body
    }

    // MARK: Spawning

    /// Drops `item` from the top of the screen at `x`, or at a random x if `nil`.
    /// Items fall faster at higher levels.
    @discardableResult
    func spawn(_ item: FallingItem, atX x: CGFloat? = nil) -> SKSpriteNode {
        let field = playfield
        let node = SKSpriteNode(imageNamed: item.imageName)
        node.name = item.imageName
        node.size = itemSize
        node.position = CGPoint(x: x ?? .random(in: field.spawnXRange(objectWidth: itemSize.width)),
                                y: field.spawnY(objectHeight: itemSize.height))
        node.zPosition = 10
        node.physicsBody = configured(SKPhysicsBody(circleOfRadius: itemSize.width * 0.4),
                                      as: Collider(for: item, rules: rules))

        addChild(node)
        node.run(.sequence([
            .moveTo(y: field.despawnY(objectHeight: itemSize.height), duration: model.fallDuration),
            .removeFromParent()
        ]))
        return node
    }

    // MARK: Ninja star

    /// Throws a star from the dino's hand toward the side it faces.
    /// Returns `nil` if a star is already in flight or the game isn't running.
    @discardableResult
    func throwStar() -> SKSpriteNode? {
        guard model.throwStar() else { return nil }

        // The hand is toward the front of the art, a little above the middle.
        let direction = CGFloat(pose.facing.sign)
        let start = CGPoint(x: dino.position.x + direction * dino.size.width * 0.35,
                            y: dino.position.y + dino.size.height * 0.1)

        let star = SKSpriteNode(imageNamed: Images.ninjaStar)
        star.name = Images.ninjaStar
        star.position = start
        star.zPosition = 15
        let radius = star.size.width * 0.4
        star.physicsBody = configured(SKPhysicsBody(circleOfRadius: radius), as: .star)
        star.run(.repeatForever(.rotate(byAngle: -direction * .pi * 2, duration: 0.4)))
        addChild(star)

        starNode = star
        starFlight = NinjaStarFlight(from: start, facingRight: pose.facing == .right,
                                     angleDegrees: rules.starAngleDegrees,
                                     speed: rules.starSpeed, radius: radius)
        return star
    }

    /// Moves the star along its angled path, bouncing off the side walls.
    func advanceStar(by dt: TimeInterval) {
        guard isPlaying, var flight = starFlight, let star = starNode else { return }

        let visible = playfield.visibleSize
        let walls = NinjaStarFlight.Walls(left: -visible.width / 2,
                                          right: visible.width / 2,
                                          top: visible.height / 2)
        let state = flight.advance(by: dt, within: walls)
        starFlight = flight
        star.position = flight.position

        if state == .offScreen {
            finishStar()
        }
    }

    private func finishStar() {
        starNode?.removeFromParent()
        starNode = nil
        starFlight = nil
        model.starFinished()
    }

    // MARK: Dino movement

    /// Moves the dino sideways by `dx`, turning it to face the direction of travel.
    func moveDino(byX dx: CGFloat) {
        guard let facing = Facing(swipe: Double(dx)) else { return }

        dino.position.x = playfield.clampedX(dino.position.x + dx, objectWidth: dino.size.width)

        // While the hit pose is showing, keep it, but turn so it ends facing the new way.
        if isShowingHit {
            if facing != pose.facing {
                show(.hit(facing))
            }
            return
        }

        // Only restart the walk cycle when the direction changes, so it doesn't
        // reset to the first frame on every touch event.
        if pose != .walking(facing) || dino.action(forKey: "walk") == nil {
            show(.walking(facing))
            let frames = DinoPose.walkCycle(facing).map { SKTexture(imageNamed: $0.imageName) }
            dino.run(.repeatForever(.animate(with: frames, timePerFrame: 0.1)), withKey: "walk")
        }

        // Go back to standing once the swipe stops. Each move replaces this timer.
        dino.run(.sequence([
            .wait(forDuration: 0.15),
            .onMain { [weak self] in self?.stopWalking() }
        ]), withKey: "stop")
    }

    func stopWalking() {
        dino.removeAction(forKey: "walk")
        dino.removeAction(forKey: "stop")
        guard !isShowingHit else { return }
        show(.standing(pose.facing))
    }

    /// Ends the hit pose, standing in whichever direction the dino faces now.
    func finishHitPose() {
        guard isShowingHit else { return }
        show(.standing(pose.facing))
    }

    private func show(_ newPose: DinoPose) {
        pose = newPose
        dinoImageName = newPose.imageName
        dino.texture = SKTexture(imageNamed: newPose.imageName)
    }

    // MARK: Touches

    // A touch that moves sideways past `rules.swipeThreshold` is a swipe and moves the dino.
    // A touch that lifts without moving that far is a tap and throws a star.

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let x = touches.first?.location(in: self).x else { return }
        touchStartX = x
        lastTouchX = x
        isSwiping = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlaying, let x = touches.first?.location(in: self).x else { return }
        if !isSwiping, abs(x - touchStartX) > rules.swipeThreshold {
            isSwiping = true
            // Count the distance moved before the swipe was recognized, so the dino keeps up with the finger.
            lastTouchX = touchStartX
        }
        if isSwiping {
            moveDino(byX: x - lastTouchX)
        }
        lastTouchX = x
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPlaying, !isSwiping {
            throwStar()
        }
        isSwiping = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isSwiping = false
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

        switch event {
        case .hitByWasabi:
            dinoHit(by: colliderA == .wasabi ? a : b)
        case .shotTarget:
            let (target, star) = colliderA == .target ? (a, b) : (b, a)
            shoot(target, with: star)
        }
    }

    private func shoot(_ target: SKNode, with star: SKNode) {
        guard let item = target.name.flatMap(FallingItem.init(imageName:)) else { return }
        model.shoot(item)

        showBlast(item.shotBlastImageName, at: target.position)
        target.removeFromParent()

        // The star stops at the first thing it hits, freeing the dino to throw again.
        if star === starNode {
            finishStar()
        } else {
            star.removeFromParent()
        }
    }

    private func dinoHit(by wasabi: SKNode) {
        // While invincible, wasabi passes straight through.
        guard !model.isInvincible else { return }

        showBlast(Images.blastRed, at: wasabi.position)
        wasabi.removeFromParent()
        model.takeHit()

        // Show the hit pose briefly, then stand facing whichever way the dino faces by then.
        dino.removeAction(forKey: "walk")
        dino.removeAction(forKey: "stop")
        show(.hit(pose.facing))
        dino.run(.sequence([
            .wait(forDuration: 0.4),
            .onMain { [weak self] in self?.finishHitPose() }
        ]), withKey: "hitPose")

        guard model.isInvincible else { return }

        // Blink until invincibility ends.
        let blinkCount = Int(rules.invincibilityDuration / 0.2)
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
