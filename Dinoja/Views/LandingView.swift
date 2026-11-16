//
//  LandingView.swift
//  Dinoja
//
//  Created by John M Cruz on 10/1/23.
//

import SwiftUI

struct LandingView: View {
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            BackgroundImage()

            VStack {
                Spacer()
                Image(Images.gameTitle)
                    .accessibilityLabel("Dinoja")
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    isPlaying = true
                } label: {
                    Image(Images.startGame)
                }
                .accessibilityLabel("Start Game")
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            GameView()
        }
    }
}

#Preview {
    LandingView()
}
