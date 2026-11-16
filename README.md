# Dinoja

A SpriteKit arcade game for iOS where a ninja dino catches falling sushi and throws ninja stars at falling wasabi.

## How to Play

- **Move:** Drag your finger left and right. The dino stays directly under your finger.
- **Catch sushi:** Sushi falls from the top. Catch it to score.
- **Avoid wasabi:** Wasabi costs you a heart if it hits you. The dino throws ninja stars upward on its own, and they knock wasabi out of the sky.
- **Lives:** You start with 3 hearts. After a hit, the dino blinks and can't be hit again for a moment.
- **Pause:** Tap the pause icon at the top left. Tap Continue to resume.
- **Game over:** When all hearts are gone, your final score is shown. Tap Continue to return to the start screen.

### Scoring

| Action | Points |
| --- | --- |
| Catch sushi | 10 |
| Catch a sushi combo | 30 |
| Shoot down wasabi | 5 |

The game gets harder as your score goes up. Items fall faster, spawn more often, and more of them are wasabi. At 1,000 points it reaches full difficulty.

## Requirements

- Xcode with the iOS SDK
- iOS 16.4 or later

## Getting Started

1. Clone the repository and open `Dinoja.xcodeproj` in Xcode.
2. Pick an iPhone simulator or a connected device.
3. Build and run (⌘R).

## Project Structure

| Path | Description |
| --- | --- |
| `Dinoja/DinojaApp.swift` | App entry point. |
| `Dinoja/Views/LandingView.swift` | SwiftUI start screen with the title and Start Game button. |
| `Dinoja/Views/GameView.swift` | Hosts the game scene in a SwiftUI `SpriteView`. |
| `Dinoja/Scenes/GameScene.swift` | All gameplay: movement, spawning, collisions, scoring, pause and game over. |
| `Dinoja/Scenes/GameScene.sks` | Scene layout for the background, dino and lives indicator. |
| `Dinoja/Constants/Images.swift` | Names of the image assets. |
| `Dinoja/Assets.xcassets` | Game art. |

## Tuning

The difficulty settings are grouped near the top of `GameScene.swift`:

- Share of items that are wasabi
- Fall speed
- Time between spawns
- Score at which the game reaches full difficulty
- Fire rate
- Length of the invincibility after a hit
