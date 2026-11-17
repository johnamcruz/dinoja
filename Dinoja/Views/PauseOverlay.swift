//
//  PauseOverlay.swift
//  Dinoja
//

import SwiftUI

/// Hides the game behind the background art and shows the Pause title and Continue button.
struct PauseOverlay: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            BackgroundImage()

            VStack(spacing: 40) {
                Image(Images.pauseText)
                    .accessibilityLabel("Pause")
                    .accessibilityAddTraits(.isHeader)

                Button(action: onContinue) {
                    Image(Images.continueButton)
                }
                .accessibilityLabel("Continue")
            }
        }
    }
}

#Preview {
    PauseOverlay {}
}
