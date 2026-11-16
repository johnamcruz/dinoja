# Dinoja

A SpriteKit arcade game for iOS where a ninja dino catches falling sushi and throws ninja stars at falling wasabi.

<p align="center">
  <img src="docs/screenshots/start.png" alt="Dinoja start screen with the title and Start Game button" width="280">
  &nbsp;&nbsp;
  <img src="docs/screenshots/gameplay.png" alt="Gameplay: the dino throws ninja stars while sushi falls, with the score and hearts at the top" width="280">
</p>

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

- Xcode 26 or later
- iOS 26 or later

## Getting Started

1. Clone the repository and open `Dinoja.xcodeproj` in Xcode.
2. Pick an iPhone simulator or a connected device.
3. Build and run (⌘R).

## Architecture

The game rules are plain Swift with no SpriteKit or SwiftUI, so they can be unit tested on their own.

- **Models** hold the rules: score, lives, pausing, difficulty, which items spawn, what each collision means, and the visible play area.
- **`GameScene`** (SpriteKit) draws the dino, falling items and ninja stars. It reports catches and hits to `GameModel`.
- **SwiftUI views** read `GameModel` to draw the score, hearts, pause button, pause screen and game over screen on top of the scene.

## Project Structure

| Path | Description |
| --- | --- |
| `Dinoja/DinojaApp.swift` | App entry point. |
| `Dinoja/Models/GameModel.swift` | Score, lives, playing/paused/game over state, invincibility after a hit, and the difficulty ramp. |
| `Dinoja/Models/FallingItem.swift` | The sushi kinds and wasabi: image names, points and spawn odds. |
| `Dinoja/Models/ContactEvent.swift` | Physics categories and what each collision means (catch, hit, shot). |
| `Dinoja/Models/Playfield.swift` | The on-screen area after aspect-fill cropping, and keeping objects on screen. |
| `Dinoja/Scenes/GameScene.swift` | SpriteKit gameplay: movement, spawning, ninja stars and collisions. |
| `Dinoja/Scenes/GameScene.sks` | Scene layout for the background and the dino. |
| `Dinoja/Views/LandingView.swift` | Start screen with the title and Start Game button. |
| `Dinoja/Views/GameView.swift` | Hosts the scene in a `SpriteView` and switches between the HUD and overlays. |
| `Dinoja/Views/HUD.swift` | Score, Liquid Glass pause button and hearts. |
| `Dinoja/Views/PauseOverlay.swift` | Pause screen: background art and the Continue button. |
| `Dinoja/Views/GameOverOverlay.swift` | Game over screen with the final score. |
| `Dinoja/Views/BackgroundImage.swift` | The background art, cropped to match the scene. |
| `Dinoja/Constants/Images.swift` | Names of the image assets. |
| `DinojaTests/` | Unit and integration tests (Swift Testing). |
| `DinojaUITests/` | UI tests (XCUITest). |

## Testing

Run all tests in Xcode with ⌘U.

| Suite | Kind | Covers |
| --- | --- | --- |
| `GameModelTests` | Unit | Scoring, lives, invincibility, pause, game over and the difficulty ramp. |
| `FallingItemTests` | Unit | Image names and spawn odds, using a seeded random generator so results are repeatable. |
| `PlayfieldTests` | Unit | Visible area on tall and wide screens, clamping and spawn bounds. |
| `ContactEventTests` | Unit | Collision rules and physics bit masks. |
| `GameSceneIntegrationTests` | Integration | Loads the real scene from `GameScene.sks` with the game loop paused, then checks catching, hits, shooting, movement and pausing against `GameModel`. |
| `DinojaUITests` | UI | Start screen, HUD, pause and Continue, and launch time. |

To run only the unit and integration tests from the command line (replace the simulator name with one you have installed):

```sh
xcodebuild test -project Dinoja.xcodeproj -scheme Dinoja \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:DinojaTests
```

## Tuning

Difficulty settings are in `GameModel.swift`. Each one ramps from an easy value to a hard value as the score goes from 0 to 1,000:

- Share of items that are wasabi (15% to 35%)
- Time for an item to fall (4.5s to 2.0s)
- Time between spawns (about 1.1s to 0.6s)

The dino's size, the fire rate and the length of the invincibility blink are near the top of `GameScene.swift`.
