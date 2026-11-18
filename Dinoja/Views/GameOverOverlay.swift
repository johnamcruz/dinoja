//
//  GameOverOverlay.swift
//  Dinoja
//

import SwiftUI

/// Covers the game with the background art, hiding the dino and falling items,
/// and shows the final score with a Continue button that returns to the start screen.
struct GameOverOverlay: View {
    let score: Int
    let level: Int
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            BackgroundImage()

            VStack(spacing: 32) {
                // The title art is wider than smaller phones, so scale it down to fit.
                Image(Images.gameOverText)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 441)
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Game Over")
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 4) {
                    Text("score \(score)")
                        .font(.system(size: 34, weight: .regular))
                    Text("level \(level)")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundStyle(Palette.hudBlue)

                Button(action: onContinue) {
                    Image(Images.continueButton)
                }
                .accessibilityLabel("Continue")
            }
        }
    }
}

#Preview {
    GameOverOverlay(score: 34, level: 2) {}
}
