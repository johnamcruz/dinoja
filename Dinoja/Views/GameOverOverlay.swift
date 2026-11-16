//
//  GameOverOverlay.swift
//  Dinoja
//

import SwiftUI

/// Dims the frozen game and shows the final score with a Continue button.
struct GameOverOverlay: View {
    let score: Int
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Image(Images.gameOverText)
                    .accessibilityLabel("Game Over")
                    .accessibilityAddTraits(.isHeader)

                Text("Score: \(score)")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)

                Button(action: onContinue) {
                    Image(Images.continueButton)
                }
                .accessibilityLabel("Continue")
            }
        }
    }
}

#Preview {
    ZStack {
        BackgroundImage()
        GameOverOverlay(score: 340) {}
    }
}
