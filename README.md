# EpicDungeon

EpicDungeon is the Xcode project for the **Emberkeep** prototype.

A small, original first-person dungeon prototype for **macOS and iPadOS**, built with Swift and a custom Metal renderer. No Unity, Godot, SceneKit, downloaded assets, or copied game code.

## Run

Open `EpicDungeon.xcodeproj`, choose the **Emberkeep** scheme, then choose **My Mac** or an **iPad Simulator** and Run. Requires Xcode with macOS/iOS SDKs; deployment targets are macOS 14 and iPadOS 17.

For a physical iPad, select your own signing team in Xcode and connect/trust the device. Device signing and installation have not been configured by the agent. No Apple account or credentials are embedded in the project.

```sh
swift test
xcodebuild -project EpicDungeon.xcodeproj -scheme Emberkeep \
  -destination 'platform=macOS' -derivedDataPath .build/native \
  CODE_SIGNING_ALLOWED=NO build
open .build/native/Build/Products/Debug/Emberkeep.app
```

For an unsigned simulator build, replace the destination with `generic/platform=iOS Simulator`. An unsigned physical-device build checks compilation only; it cannot be installed as-is.

## Play

Defeat four stone wardens to open the ember gate at the north end of the dungeon. Use the gate to ascend. Caches restore vitality and grant gold; enemies grow stronger on later floors. Gold is a run score, not yet a shop currency.

| Action | Mac | iPad |
| --- | --- | --- |
| Move | WASD; up/down arrows | Left thumbstick |
| Look | Drag the scene; left/right arrows | Drag the right side |
| Attack | Space (hold) or click / Strike | Strike button |
| Guard | Hold F or right mouse button | Hold Guard |
| Open cache / ascend | E or Use button | Use button |
| Pause | Escape or pause button | Pause button |
| Restart after death | R or Try Again | Try Again |

Guard reduces damage only from enemies in front. Attacks require range, facing, and clear line of sight. Losing app focus pauses the run. This prototype does not persist progress between launches.

## Regression checks

`swift test` runs the pure simulation suite. On a Mac, `python3 scripts/test_native.py` compiles the actual app logic and native regression tests into an isolated temporary Swift package. Use `--scratch-directory /absolute/new/path` to choose a new output directory outside this repository; `--help` documents the command. The runner prints and retains that directory for inspection and later cleanup. It downloads no dependencies and does not modify Xcode signing settings.

Native tests inject resource-allocation failure, exercise selected-touch cancellation state and compare translated gate meshes. They do not simulate physical GPU exhaustion or a real UIKit system interruption on a device. Cancelling look releases only that touch; pause and loss of focus still reset every input.

## Engine layout

- `Engine/`: deterministic maze generation, collision, simulation and combat; no rendering dependencies.
- `App/Mesh.swift`: original triangle geometry for stone walls, floor tiles, wardens, braziers, caches and gate.
- `App/Renderer.swift`: depth-tested Metal pipeline, perspective camera, static dungeon buffer and transient actor geometry.
- `App/Shaders.metal`: original vertex/fragment shaders, simple torch lighting and distance fog.
- `App/MetalSurface.swift`: AppKit/UIKit Metal views and platform input adapters.
- `App/GameScreen.swift`: SwiftUI HUD, minimap, menus and touch controls.
- `Tests/EmberCoreTests/`: headless XCTest coverage, built separately with SwiftPM from the same engine files.

All simulation and view input execute on the native view's main-thread loop. Frame delta is capped at 50 ms after stalls. Static geometry is cached by floor with an atomic resource/count/key replacement; failed replacements preserve the last valid entry, and recovery clears the renderer error. Gate geometry derives from the same exit cell as interaction and the minimap; transient buffers are created per submitted frame, rather than overwritten while the GPU may still read them. This simple allocation strategy favors clarity, not production-scale performance.

Shaders are bundled as text and compiled once at startup with Metal's runtime compiler. This avoids requiring Xcode's optional standalone Metal Toolchain; compilation failures appear in the UI. A production version should precompile shaders and profile performance on actual iPads.

## Scope and limitations

This is an engine foundation and a playable vertical slice, not a finished RPG. Geometry is deliberately low-poly. There are no textures, audio, skeletal animation, persistence, inventory/equipment system, controller support, cloud synchronization, or multiplayer. Enemies chase only with line of sight; no pathfinding around corners is implemented. The minimap is fully revealed. Touch accessibility and full keyboard navigation need further work.

Research evidence and internal work notes are not distributed in this repository. Only original implementation code and procedural geometry are included. The project does not read or alter any other game's files or saves.

See `docs/verification.md` for observed checks and outstanding device validation.
