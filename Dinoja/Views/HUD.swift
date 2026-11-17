//
//  HUD.swift
//  Dinoja
//

import SwiftUI

/// The slim bar along the top of the game, as in the design:
/// pause icon, "score N", hearts, and "level N" on the right, all in the hearts' light blue.
struct HUD: View {
    let score: Int
    let level: Int
    let lives: Int
    let showsPauseButton: Bool
    let onPause: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            if showsPauseButton {
                Button(action: onPause) {
                    Image(Images.pauseButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        // A bigger tap target than the small icon.
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pause")
            } else {
                // Keep the space so the score and hearts don't shift while paused.
                Color.clear.frame(width: 44, height: 44)
            }

            Text("score \(score)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(score)))
                .animation(.snappy, value: score)
                .accessibilityLabel("Score \(score)")

            Image(Images.life(lives))
                .resizable()
                .scaledToFit()
                .frame(height: 16)
                .accessibilityLabel(lives == 1 ? "1 life left" : "\(lives) lives left")

            Spacer()

            Text("level \(level)")
                .accessibilityLabel("Level \(level)")
        }
        .font(.system(size: 17, weight: .regular))
        .foregroundStyle(Palette.hudBlue)
        .padding(.leading, 6)
        .padding(.trailing, 20)
    }
}

#Preview {
    ZStack(alignment: .top) {
        BackgroundImage()
        HUD(score: 210, level: 1, lives: 2, showsPauseButton: true) {}
    }
}
