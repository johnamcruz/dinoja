//
//  GameModel.swift
//  Dinoja
//

import Foundation
import Observation

/// The game's state. The rules it applies come from `rules`; this class only
/// tracks score, lives, level and phase as play happens. `GameScene` reports
/// events, and SwiftUI reads the state to draw the HUD and overlays.
@MainActor
@Observable
final class GameModel {
    enum Phase {
        case playing
        case paused
        case gameOver
    }

    let rules: GameRules

    // MARK: State

    private(set) var score = 0
    private(set) var lives: Int
    private(set) var phase = Phase.playing
    private(set) var starsInFlight = 0

    /// True right after a wasabi hit, so back-to-back hits can't drain every life.
    /// The scene ends it with `endInvincibility()` once the dino stops blinking.
    private(set) var isInvincible = false

    init(rules: GameRules = .standard) {
        self.rules = rules
        lives = rules.maxLives
    }

    var isStarInFlight: Bool {
        starsInFlight > 0
    }

    var level: Int {
        rules.level(forScore: score)
    }

    /// Seconds an item takes to fall from the top of the screen to the bottom at the current level.
    var fallDuration: TimeInterval {
        rules.fallDuration(atLevel: level)
    }

    // MARK: Ninja stars

    /// Starts a throw unless the star limit is reached or the game isn't running.
    /// Returns whether the throw happened.
    @discardableResult
    func throwStar() -> Bool {
        guard phase == .playing, starsInFlight < rules.maxStarsInFlight else { return false }
        starsInFlight += 1
        return true
    }

    /// Call when a star hits a target or leaves the screen.
    func starFinished() {
        starsInFlight = max(starsInFlight - 1, 0)
    }

    /// Applies the effect of a ninja star hitting `item`.
    func shoot(_ item: FallingItem) {
        guard phase == .playing, rules.canBeShot(item) else { return }
        score += rules.points(forShooting: item)
        changeLives(by: rules.lifeChange(forShooting: item))
    }

    // MARK: Wasabi

    /// Wasabi landed on the dino. Ignored while invincible.
    func takeHit() {
        guard phase == .playing, !isInvincible else { return }
        changeLives(by: rules.wasabiHitLifeChange)
        if phase == .playing {
            isInvincible = true
        }
    }

    func endInvincibility() {
        isInvincible = false
    }

    private func changeLives(by change: Int) {
        lives = min(max(lives + change, 0), rules.maxLives)
        if lives == 0 {
            phase = .gameOver
        }
    }

    // MARK: Pause

    func pause() {
        if phase == .playing {
            phase = .paused
        }
    }

    func resume() {
        if phase == .paused {
            phase = .playing
        }
    }
}
