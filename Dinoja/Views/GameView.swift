//
//  GameView.swift
//  Dinoja
//
//  Created by John M Cruz on 4/30/23.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    // Stored in @State so the scene is created once instead of on every view update.
    @State private var scene = GameScene.makeScene()

    private var model: GameModel { scene.model }

    var body: some View {
        ZStack {
            // Pausing the SpriteView freezes all actions and physics. SpriteKit also keeps
            // it paused if the app goes to the background and comes back.
            SpriteView(scene: scene, isPaused: model.phase != .playing)
                .ignoresSafeArea()

            switch model.phase {
            case .playing:
                EmptyView()
            case .paused:
                PauseOverlay { model.resume() }
            case .gameOver:
                GameOverOverlay(score: model.score) { dismiss() }
            }
        }
        .overlay(alignment: .top) {
            if model.phase != .gameOver {
                HUD(score: model.score,
                    lives: model.lives,
                    showsPauseButton: model.phase == .playing) {
                    model.pause()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.phase)
    }
}

#Preview {
    GameView()
}
