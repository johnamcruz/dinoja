//
//  BackgroundImage.swift
//  Dinoja
//

import SwiftUI

/// The background art, filled and centered the same way the scene's `.aspectFill` crops it.
struct BackgroundImage: View {
    var body: some View {
        Color.clear
            .background {
                Image(Images.background)
                    .resizable()
                    .scaledToFill()
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

#Preview {
    BackgroundImage()
}
