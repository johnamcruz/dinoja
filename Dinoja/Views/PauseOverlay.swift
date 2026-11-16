//
//  PauseOverlay.swift
//  Dinoja
//

import SwiftUI

/// Hides the game behind the background art and shows only the Continue button.
struct PauseOverlay: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            BackgroundImage()

            Button(action: onContinue) {
                Image(Images.continueButton)
            }
            .accessibilityLabel("Continue")
        }
    }
}

#Preview {
    PauseOverlay {}
}
