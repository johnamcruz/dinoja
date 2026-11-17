//
//  Palette.swift
//  Dinoja
//
//  Colors sampled from the game art so SwiftUI screens match it.
//

import SwiftUI

enum Palette {
    /// The sky in `background.png`.
    static let sky = Color(red: 0x81 / 255, green: 0x7F / 255, blue: 0xA9 / 255)
    /// The ground strip in `background.png`.
    static let ground = Color(red: 0x6F / 255, green: 0x6F / 255, blue: 0x95 / 255)
    /// The light blue of the heart icons, used for HUD text.
    static let hudBlue = Color(red: 0xAD / 255, green: 0xCD / 255, blue: 0xEC / 255)
}
