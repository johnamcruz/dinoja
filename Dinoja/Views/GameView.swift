//
//  GameView.swift
//  Dinoja
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HighScores.self) private var highScores
    // Stored in @State so the scene is created once instead of on every view update.
    @State private var scene = GameScene.makeScene()
    /// Briefly shows "Level N" in the middle of the screen after a level-up.
    @State private var levelUpBanner: Int?

    private var model: GameModel { scene.model }

    var body: some View {
        ZStack {
            // Pausing the SpriteView freezes all actions and physics. SpriteKit also keeps
            // it paused if the app goes to the background and comes back.
            SpriteView(scene: scene, isPaused: model.phase != .playing)
                .ignoresSafeArea()

            if let levelUpBanner {
                Text("level \(levelUpBanner)")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundStyle(Palette.hudBlue)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }

            switch model.phase {
            case .playing:
                EmptyView()
            case .paused:
                PauseOverlay { model.resume() }
            case .gameOver:
                GameOverOverlay(score: model.score,
                                level: model.level,
                                canSave: highScores.qualifies(model.score),
                                onSave: { highScores.save(name: $0, score: model.score) },
                                onContinue: { dismiss() })
            }
        }
        .overlay(alignment: .top) {
            if model.phase != .gameOver {
                HUD(score: model.score,
                    level: model.level,
                    lives: model.lives,
                    showsPauseButton: model.phase == .playing) {
                    model.pause()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.phase)
        .animation(.spring(duration: 0.4), value: levelUpBanner)
        .onChange(of: model.level) { _, newLevel in
            levelUpBanner = newLevel
        }
        .task(id: levelUpBanner) {
            // Hide the banner a moment after it appears.
            guard levelUpBanner != nil else { return }
            try? await Task.sleep(for: .seconds(1.2))
            levelUpBanner = nil
        }
    }
}

#Preview {
    GameView()
        .environment(HighScores())
}
