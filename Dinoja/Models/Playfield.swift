//
//  Playfield.swift
//  Dinoja
//

import CoreGraphics

/// The on-screen part of a scene that uses `.aspectFill` with its anchor point at the center.
/// On devices whose aspect ratio differs from the scene's, aspect fill crops two edges,
/// so gameplay must use this area rather than the full scene size.
struct Playfield {
    let sceneSize: CGSize
    let viewSize: CGSize

    var visibleSize: CGSize {
        guard viewSize.width > 0, viewSize.height > 0 else { return sceneSize }
        let scale = max(viewSize.width / sceneSize.width, viewSize.height / sceneSize.height)
        return CGSize(width: viewSize.width / scale, height: viewSize.height / scale)
    }

    /// Clamps an x position so an object of the given width stays fully on screen.
    func clampedX(_ x: CGFloat, objectWidth: CGFloat) -> CGFloat {
        let limit = visibleSize.width / 2 - objectWidth / 2
        return min(max(x, -limit), limit)
    }

    /// The x positions where an object of the given width can spawn fully on screen.
    func spawnXRange(objectWidth: CGFloat) -> ClosedRange<CGFloat> {
        let limit = visibleSize.width / 2 - objectWidth / 2
        return -limit...limit
    }

    /// Just above the top edge, so a falling object enters from off screen.
    func spawnY(objectHeight: CGFloat) -> CGFloat {
        visibleSize.height / 2 + objectHeight
    }

    /// Just below the bottom edge, where a falling object is removed.
    func despawnY(objectHeight: CGFloat) -> CGFloat {
        -visibleSize.height / 2 - objectHeight
    }
}
