//
//  FallingItem.swift
//  Dinoja
//
//  What can fall and which image draws it. Points, spawn odds and
//  what happens when each item is shot are in GameRules.
//

enum SushiKind: CaseIterable, Sendable {
    case ahi
    case avocado
    case salmon
    case combo
}

/// Something that falls from the top of the screen.
enum FallingItem: Hashable, CaseIterable, Sendable {
    case sushi(SushiKind)
    case wasabi
    case redHeart
    case blackHeart

    static let allCases: [FallingItem] =
        SushiKind.allCases.map { .sushi($0) } + [.wasabi, .redHeart, .blackHeart]

    var imageName: String {
        switch self {
        case .sushi(.ahi): Images.sushiAhi
        case .sushi(.avocado): Images.sushiAvocado
        case .sushi(.salmon): Images.sushiSalmon
        case .sushi(.combo): Images.sushiCombo
        case .wasabi: Images.wasabi
        case .redHeart: Images.heartRed
        case .blackHeart: Images.heartBlack
        }
    }

    /// The splat shown when a star hits this item: red for the red heart, purple otherwise,
    /// as in the design sheet's item legend.
    var shotBlastImageName: String {
        self == .redHeart ? Images.blastRed : Images.blastPurple
    }

    /// Looks up an item from the image name the scene stores on its node.
    init?(imageName: String) {
        guard let match = FallingItem.allCases.first(where: { $0.imageName == imageName }) else { return nil }
        self = match
    }
}
