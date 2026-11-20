# Verification status

## Observed so far

- RED: test compilation failed against the intentionally empty engine module because the requested APIs did not exist.
- GREEN: 7 XCTest tests passed on macOS after implementation.
- Native macOS Debug build: succeeded.
- iOS Simulator Debug build: succeeded.
- macOS runtime: original Metal shaders compiled and rendered; title screen and game HUD visible; observed an enemy defeated, gold changing from 0 to 10, wardens from 4 to 3, health reduced to 76, and Escape opening the pause panel.
- Initial native build failed because the optional Metal Toolchain was missing. Bundling MSL as text and using Metal runtime compilation resolved this without installing software.
- Xcode emitted a non-blocking AppIntents metadata warning because this app does not use AppIntents.

- Unsigned iOS device Debug compilation: succeeded (not installed on a physical device).
- iPad Pro 13-inch simulator (iOS 26.5): app installed and launched; captured simulator framebuffer confirms Metal shader compilation and the rendered title screen. This does not validate gestures or physical-device performance.

- Independent verifier: the original 7 tests and 3 extra invariant probes passed in a fresh temporary copy. The three probes were retained in `InteractionTests.swift`; parent reran all 10 XCTest tests successfully.
- Independent macOS, iOS Simulator, and unsigned iOS device builds: all succeeded. Generated bundles target Mac 14.0/iPadOS 17.0, iPad family 2, contain byte-identical shader source, and contain no reference-game/REA resources.
- Local Mac deliverable: `.build/Emberkeep.app`. Build/test logs and the observed iPad framebuffer are under `.build/verification/` (ignored generated artifacts).

## Pending

- iPad Simulator touch interaction remains unverified: CoreSimulator runs, but the Simulator.app graphical frontend is absent from this Xcode installation.


- Physical iPad interruption/multitouch edge cases and measured sustained performance/battery behavior; basic gameplay was reported successful by the user (see below).
- Repository delivery strategy and work-unit commits (none created or published).

The agent has not independently run tests or collected performance measurements on a physical iPad. The user-reported device session below is separate evidence. No App Store publication or remote operations have occurred.

## Native review outcome

The user granted candidate-specific review. Resilience, readability and reliability captures completed and the candidate was approved without blockers or a correction transition. The exact acknowledgement returned `gentle-ai.review-acknowledged/v1`, action `acknowledged`, authority `burned`. This lifecycle is terminal; it does not authorize commits, publishing, or a new review of unchanged content.

Seven non-blocking advisories were returned (the melee-test gap was reported by two lenses):

- Clear the renderer error banner after successful transient allocation recovery.
- Keep cached geometry buffer and floor identity coherent across an allocation failure and a restart.
- Label the initial research report's pending architecture section as historical.
- Derive visible gate geometry from the dungeon exit rather than parallel hard-coded coordinates.
- Strengthen attack tests: a surviving target for cooldown, and an unobstructed out-of-range target for range.
- Validate independent iPad touches: cancelling look should not clear an unrelated held joystick/guard (inferential finding).

These were non-blocking follow-up findings at the review checkpoint; the later user-authorized correction batch is recorded below. Full provider result is retained in ignored `.rea/review-closure.json`. No gameplay or renderer source changed during the review. Physical iPad interruption and performance measurements remain pending.

## User-reported physical iPad session

The user reported successful launch, working attacks, very fluid movement and excellent enemy combat. Device model, OS/build identity, frame rate and battery measurements were not supplied. This validates the reported basic play session, not rare cancellation or allocation-failure scenarios.

## Authorized advisory corrections

The user explicitly requested the warning fixes after the prior review had closed. This is new follow-up work; the old review was not reopened.

- Renderer cache now commits a valid floor/resource/vertex-count entry together. Failed replacements do not erase usable earlier-floor geometry, and retry or restart recovery clears the cache error and UI banner.
- iPad touch end/cancel handles only the selected look-touch identity, preserving independently held movement and guard; global pause/focus reset remains unchanged.
- Gate frame, bars and crystal derive from the dungeon exit center; the initial report clearly labels its superseded architecture paragraph as historical.
- Explicit melee tests assert a live target is protected during cooldown and an unobstructed distant target is out of reach. Two scratch-only mutation checks confirmed the old test passed with each guard removed while the new corresponding test fails.
- Native regression suite: initial RED was missing testable state/geometry APIs (compilation failure); after implementation 4 native tests passed. Simulation suite: 12 tests passed. These native tests use injected allocations and synthetic touch identities, not physical failure injection.
- Existing Xcode signing/project contents were checked byte-for-byte unchanged from the start of this batch.

Independent verification completed without blockers: 12 core tests, 4 native tests, and unsigned Debug builds for Mac, iOS Simulator and generic iOS device all passed. Parent reran the core suite (12 passed). Only the expected AppIntents metadata warning remains.

Differential scene comparison against the pre-edit baseline covered 85,032 vertices across closed-gate, open-gate and next-floor scenes; maximum float delta was exactly zero. User Xcode settings remain byte-for-byte unchanged. The corrected Mac build is `.build/Emberkeep-fixed.app`; the previous build was preserved. Logs are in `.build/verification/advisory-fixes/`.

The corrected binary has not been installed or tested on the user's physical iPad by the agent. Real OS touch cancellation, GPU exhaustion and long-run performance are not claimed verified. A new native candidate review requires fresh consent; the earlier approval is historical.
