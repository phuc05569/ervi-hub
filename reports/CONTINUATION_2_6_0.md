# Ervi Hub 2.6.0 — 2026-11-13

Started from clean commit `1374017d728374ce884e2a493f92d8d84e93e5c0`, previously pushed to main. Created `backups/pre-2.6.0.tar.gz` before editing. Reproduced all 68 unit tests, 210 smoke checks and bundle compilation before changes.

## Implemented

- Deleted obsolete `src/Cyborg.luau` and removed its require, UI controls, dashboard status and bundled code. Legacy global/GUI cleanup is retained so rerunning over an older script still removes old overlays. The immutable original baseline remains available.
- The only M1 HUD now uses `FloatingWindow` and pure `WindowGeometry`. No Close button; Combat owns enabling/disabling. Persistent enabled state, normalized position and pixel dimensions follow the active config. Dragging and corner resizing clamp to the viewport. Camera/viewport changes reflow layout. Scrolling content, a reserved title/grip area and truncated title prevent oversized fonts or long style names from overlapping the controls. Theme and opacity follow the hub.
- Added the requested permanent floating-window contract to root AGENTS.md. Future floating interfaces must provide resizing, menu control, persistence, bounds and cleanup or document a technical exception.
- Opacity supports the full 0–100% background range, with the existing text-readability behavior preserved.
- `SafeZoneState` validates and serializes a PlaceId plus all 12 CFrame components; it rejects nonfinite/out-of-range values and invalid rotation matrices. `SafeZone` captures the live character CFrame only when its menu button is pressed, displays coordinates/distance, supports replacement and clearing, and persists through the existing config file. It never writes character CFrame, anchors a character or changes physics.
- F6 opens Safe Zone and refreshes its reference/distance. The Settings key capture rejects conflicts with the GUI key, both keys ignore typing, and loaded conflicting bindings are repaired. This key performs no movement.
- `TargetState` and `Targets` implement the manual-combat alternative. Selection requires a living local character and a same-place safe reference. At most once per 0.25 seconds while enabled, the adapter reads replicated player health. A target strictly below the configured 1–100% threshold qualifies. Invalid/zero maximum health, dead characters, departed players and unhealthy state are handled. Existing eligible targets remain stable; otherwise the lowest HP percentage wins, with UserId as tie-breaker. There is no target-processing coroutine, player-position overlay, movement request or attack request.
- Combat includes the threshold slider/numeric input, selected name, HP, state and Auto M1 request preference. OFF means manual attacks/skills; ON clearly says unsupported and sends no attacks. Disable/local death/missing saved reference clears selection; observation recovers after a valid respawn.
- `AutoRoll` includes WaitingRespawn in its running states and persistent resumeAfterDeath control. No extra worker starts. Death does not consume the live-readiness timeout. Normal character/arena/cooldown gates still apply after respawn. Equipment is rechecked before each request after waiting, protecting newly qualifying/rare styles. Pending requests still evaluate normally; qualifying responses stay terminal, and uncertainty/errors pause without retries even when recovery is enabled.
- Extended Settings validation, serialization and profile syncing for HUD geometry, safe reference/key, threshold, request preference and recovery setting. Nonfinite numeric settings are rejected. Existing features remain covered by their tests.

## Unsupported mechanics and evidence limits

The only established game request in this checkout is the existing roll request. No authoritative permitted movement/floating/return or automatic-M1 API is available. The implementation therefore retains manual approach, combat and return instead of inventing remotes or changing physics. Saved coordinates do not confer a server safe zone. An owner-supported game API and live evidence would be prerequisites to enabling those mechanics.

The universal HUD retains the candidate `AttackReadyAt` interpretation and its visible UNVERIFIED label. It does not claim newly validated all-style timing. The separate Cyborg effect estimate is removed, as requested.

Desktop Commander/device/PowerShell tools remain absent from tool discovery. Only the Linux workspace is accessible. No Windows paths, Roblox processes, installed Potassium script or graphical applications were inspected or controlled. No live Roblox validation was performed, and Potassium's script/workspace copies were not updated. No files were added to its autoexec directory.

## Validation

- 99 unit tests passed; 245 smoke checks passed. Obsolete standalone Cyborg assertions were replaced with assertions for one menu-controlled HUD; remaining regression coverage is active.
- Unit coverage includes geometry bounds/round trips, safe reference orientation/place validation, target eligibility/lifecycle, settings round trips and key conflict repair, and Auto Roll death/recovery/in-flight/terminal-result guarantees.
- Integrated smoke coverage drives real emitted UI handlers for HUD dragging/resizing, viewport shrink/restore, saved coordinates/orientation, reference replacement/clearing, key conflicts/rebind/typing, player health/death/leave/respawn, unsupported Auto M1 messaging, and actual character replacement during Auto Roll recovery.
- Both release bundle and generated loader compile with checksum-verified Luau 0.746. Pure new modules pass luau-analyze. The mocked API dump is the pinned input established during onboarding; these checks cannot prove rendering or live game behavior.
- Repeat build determinism, backup recovery and baseline preservation are checked before release. The loader template remains unconfigured; the owner's existing direct bundle URL can load the new committed artifact.

See README and CHANGELOG for the final build ID and checksum. GitHub publication is performed only to the existing owner-authorized repository, preserving visibility; verify the exact remote commit and immutable raw artifact after pushing. Branch raw URLs may temporarily cache an older build. Windows deployment and game-side validation remain outstanding.
