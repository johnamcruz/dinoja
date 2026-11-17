//
//  GameOverOverlay.swift
//  Dinoja
//

import SwiftUI

/// Covers the game with the background art, hiding the dino and falling items,
/// and shows the final score with Save (for a top-five score) and Continue.
struct GameOverOverlay: View {
    let score: Int
    let level: Int
    /// Whether the score makes the high-score list.
    let canSave: Bool
    let onSave: (String) -> Void
    let onContinue: () -> Void

    @State private var isNaming = false
    @State private var name = ""
    @State private var didSave = false

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
                    Text(didSave ? "saved to high scores" : "level \(level)")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundStyle(Palette.hudBlue)

                VStack(spacing: 16) {
                    if canSave && !didSave {
                        Button {
                            isNaming = true
                        } label: {
                            Image(Images.saveButton)
                        }
                        .accessibilityLabel("Save")
                    }

                    Button(action: onContinue) {
                        Image(Images.continueButton)
                    }
                    .accessibilityLabel("Continue")
                }
            }
        }
        .alert("New high score!", isPresented: $isNaming) {
            TextField("Name", text: $name)
                .textInputAutocapitalization(.never)
            Button("Save") {
                onSave(name)
                didSave = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for the high score list.")
        }
    }
}

#Preview {
    GameOverOverlay(score: 34, level: 2, canSave: true, onSave: { _ in }, onContinue: {})
}
