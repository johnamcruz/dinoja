//
//  HUD.swift
//  Dinoja
//

import SwiftUI

/// Score, pause button and hearts along the top of the screen.
struct HUD: View {
    let score: Int
    let lives: Int
    let showsPauseButton: Bool
    let onPause: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if showsPauseButton {
                Button(action: onPause) {
                    Image(Images.pauseButton)
                        .padding(6)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Pause")
            }

            Text(score, format: .number)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(score)))
                .animation(.snappy, value: score)
                .accessibilityLabel("Score \(score)")

            Spacer()

            Image(Images.life(lives))
                .accessibilityLabel(lives == 1 ? "1 life left" : "\(lives) lives left")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

#Preview {
    ZStack(alignment: .top) {
        BackgroundImage()
        HUD(score: 120, lives: 2, showsPauseButton: true) {}
    }
}
