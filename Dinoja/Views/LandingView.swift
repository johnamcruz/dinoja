//
//  LandingView.swift
//  Dinoja
//
//  Created by John M Cruz on 10/1/23.
//

import SwiftUI

struct LandingView: View {
    @State var isPresented = false
    var body: some View {
        Image(Images.background)
            .resizable()
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                VStack {
                    Spacer()
                    Image(Images.gameTitle)
                    Spacer()
                    Button() {
                        isPresented = true
                    } label: {
                        Image(Images.startGame)
                    }
                    Spacer()
                }
            }
            .fullScreenCover(isPresented: $isPresented) {
                GameView()
            }
    }
}

#Preview {
    LandingView()
}
