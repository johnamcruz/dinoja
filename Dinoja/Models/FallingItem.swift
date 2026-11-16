//
//  FallingItem.swift
//  Dinoja
//

enum SushiKind: CaseIterable {
    case ahi
    case avocado
    case salmon
    case combo

    /// Points for catching this sushi.
    var points: Int {
        self == .combo ? 30 : 10
    }

    /// Relative spawn weight. Each regular kind is twice as likely as the combo.
    fileprivate var weight: Int {
        self == .combo ? 1 : 2
    }
}

/// Something that falls from the top of the screen.
enum FallingItem: Equatable {
    case sushi(SushiKind)
    case wasabi

    var imageName: String {
        switch self {
        case .wasabi: Images.wasabi
        case .sushi(.ahi): Images.sushiAhi
        case .sushi(.avocado): Images.sushiAvocado
        case .sushi(.salmon): Images.sushiSalmon
        case .sushi(.combo): Images.sushiCombo
        }
    }

    /// Looks up an item from the image name the scene stores on its node.
    init?(imageName: String) {
        let all: [FallingItem] = [.wasabi] + SushiKind.allCases.map { .sushi($0) }
        guard let match = all.first(where: { $0.imageName == imageName }) else { return nil }
        self = match
    }

    /// Picks the next item to spawn. Wasabi appears with probability `wasabiChance`;
    /// otherwise a sushi kind is chosen by weight.
    static func random(wasabiChance: Double, using rng: inout some RandomNumberGenerator) -> FallingItem {
        if Double.random(in: 0..<1, using: &rng) < wasabiChance {
            return .wasabi
        }
        let totalWeight = SushiKind.allCases.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<totalWeight, using: &rng)
        for kind in SushiKind.allCases {
            if roll < kind.weight {
                return .sushi(kind)
            }
            roll -= kind.weight
        }
        return .sushi(.ahi)
    }

    static func random(wasabiChance: Double) -> FallingItem {
        var rng = SystemRandomNumberGenerator()
        return random(wasabiChance: wasabiChance, using: &rng)
    }
}
