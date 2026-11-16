//
//  GameModel.swift
//  Dinoja
//

import Foundation
import Observation

/// The game's state and rules. `GameScene` reports what happens in play, and
/// SwiftUI reads this model to draw the score, hearts and overlays.
@MainActor
@Observable
final class GameModel {
    enum Phase {
        case playing
        case paused
        case gameOver
    }

    // MARK: Rules

    static let startingLives = 3
    static let wasabiPoints = 5

    /// Score at which the difficulty stops ramping up.
    static let maxDifficultyScore = 1000

    // MARK: State

    private(set) var score = 0
    private(set) var lives = GameModel.startingLives
    private(set) var phase = Phase.playing

    /// True right after a hit, so back-to-back hits can't drain every life.
    /// The scene ends it with `endInvincibility()` once the dino stops blinking.
    private(set) var isInvincible = false

    // MARK: Difficulty

    /// 0 at the start of the game, rising to 1 at `maxDifficultyScore`.
    var difficulty: Double {
        min(Double(score) / Double(Self.maxDifficultyScore), 1)
    }

    /// Chance that a newly spawned item is wasabi instead of sushi.
    var wasabiChance: Double { ramp(easy: 0.15, hard: 0.35) }

    /// Seconds an item takes to fall from the top of the screen to the bottom.
    var fallDuration: TimeInterval { ramp(easy: 4.5, hard: 2.0) }

    /// Average seconds between spawns.
    var spawnInterval: TimeInterval { ramp(easy: 1.1, hard: 0.6) }

    private func ramp(easy: Double, hard: Double) -> Double {
        easy + (hard - easy) * difficulty
    }

    // MARK: Events

    func collect(_ kind: SushiKind) {
        guard phase == .playing else { return }
        score += kind.points
    }

    func destroyWasabi() {
        guard phase == .playing else { return }
        score += Self.wasabiPoints
    }

    /// Removes a life and starts invincibility, ending the game when no lives are left.
    /// Ignored while already invincible.
    func takeHit() {
        guard phase == .playing, !isInvincible else { return }
        lives = max(lives - 1, 0)
        if lives == 0 {
            phase = .gameOver
        } else {
            isInvincible = true
        }
    }

    func endInvincibility() {
        isInvincible = false
    }

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
