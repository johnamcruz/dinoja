//
//  DinojaApp.swift
//  Dinoja
//

import SwiftUI

@main
struct DinojaApp: App {
    @State private var highScores = HighScores()

    var body: some Scene {
        WindowGroup {
            LandingView()
                .environment(highScores)
        }
    }
}
