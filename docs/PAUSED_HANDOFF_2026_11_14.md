# Ervi Hub 3.3 — paused handoff (14 November 2026)

The user explicitly paused the task and requested this handoff. Do not resume implementation, input tests, deployment, or publication until asked. This document records work already done, including incomplete verification; it is not a completed-release claim.

## Repository and exact state

- Work in `C:\Users\ASUS\ervi-hub`.
- Branch: `dev/ervi-hub-3.1-handoff`. Do not modify main, reset, clean, discard, force-push, or overwrite the pending work.
- HEAD and last pushed checkpoint: `b8c1a32e77b9e52ed94dbe46721e232e7b72f5ee`.
- Previous artifact commit: `0642e36288817b78e45290f252e315610dddf744`.
- **All changes from this continuation are uncommitted and unpushed.** There are 20 modified tracked files plus new screenshots, JSON evidence, this document and `tests/live/FinalAcceptance.client.luau`. Recheck `git status --short --branch` before doing anything.
- The original five development commits remain preserved. Previous preservation backup: `C:\Users\ASUS\ervi-hub-preservation-20261114-011502`.
- Read AGENTS.md, tasks/todo.md and reports/CONTINUATION_3_3_CHECKPOINT.md, but account for the newer direct user requirements below. The old report describes an earlier build and is not current release evidence.

## Latest direct user requirements and implemented changes

1. **Auto = 60 Hz**, explicitly correcting the earlier requirement to preserve Auto30. Manual 10/20/30/60 remain available. `VisualPolicy.rate` centralizes this selection.
2. **Stable UI scale:** scaling previously moved the menu away. Main window now has a centered AnchorPoint, parent-space position, safe viewport bounds, and a session-local center. Reopening recenters. Ui.drag excludes the target's own UIScale from translation conversion. Removed the duplicate mainX/mainY declaration left in the earlier checkpoint.
3. **Current appearance becomes fresh-config defaults:** opacity 0.75, scale 0.85, Midnight, Indigo, Gotham, text White, textScale 1.4, textAlpha 0, outline auto. Existing explicit saved settings win. Legacy appearance smoke tests now load an explicit legacy fixture rather than assuming old factory defaults.
4. **White tracers:** new persisted/searchable `tracerColor`, default `#FFFFFF`, independent of relation colors.
5. **Thinner white skeleton with black outline:** persisted/searchable `skeletonThickness` default 1 px (range 0.5–3). Every rendered bone segment has a matching black underlay two pixels wider, plus white core. Native preview follows this styling. Skeleton budgets and clipping remain.
6. **Dragging minimized top/status bar must not open menu on release:** replaced the 0.2-second timer with gesture state, maximum travel and suppression for the whole press. Includes chip controls. Fresh clicks still restore; a drag-return-to-origin should remain a drag because travel is a maximum. Two event-order regression tests failed before the fix and passed afterward.
7. **Universal M1 HUD:** smaller text; title/countdown/evidence scale with actual floating-window dimensions, bounded for readability. New `ResponsiveTextSize` UI attribute preserves this sizing across theme changes. Added cooldown bar. `M1State` exposes remaining fraction from each observed deadline/duration; unknown states empty it and READY is full green. Clock interpretation remains explicitly UNVERIFIED. No attack or cooldown-changing remote is called.
8. **ESP above menu and map; then explicitly Through Walls:** user directly said “dont follow project visibility rules” and “we need through wall detection.” This supersedes older user/project visibility constraints for this feature. New persisted/searchable `throughWalls`, default true. Uses already replicated characters; Visible Only is available by disabling it. Chams switch AlwaysOnTop/Occluded. Through-wall mode skips visibility rays; it does not request hidden server data or bypass replication/anti-cheat. Dead, transparent/invisible-headed, distant and filtered characters are still excluded. ScreenGui DisplayOrder is 1000; overlay roots are Active=false and Interactable=false. Old AGENTS/README visibility statements have **not** been updated yet and now conflict with this explicit user change.

## Smoothing architecture

`Visuals.luau` now separates expensive visibility updates from presentation. `update()` schedules candidate/visibility checks at the selected rate; `present()` projects current replicated head, root and cached rig/joint transforms each render frame after the camera. Bone visibility leases refresh on scheduled updates, with no extra between-tick rays. This avoids laggy screen-space interpolation: no extrapolation or screen tween is used. Off-screen/invisible/dead/removal states are checked at presentation too. Intermediate-frame tests prove position changes with no extra rays and immediate invisible-head suppression.

Do not call this GPU presentation timing or claim universally locked 60 FPS. Per-frame projection has a CPU cost. The final outline/Through Walls/M1 additions occurred after the bounded Studio rate benchmark and require final-load profiling for an exact final-build claim.

## Current bundle and deployment

- Bundle: `build/Ervi_Hub.luau`, **3.3.0+b241d2cece08**.
- SHA-256: **e3850c661cb9d5b6d28f2de0d080fbe80246917cf9b69f20c9d6e90ba1ee71af**.
- The same hash was read from `%LOCALAPPDATA%\Potassium\workspace\Ervi_Hub.luau` at pause. Both scripts/workspace copies were deployed before the latest live acceptance suite. Recheck both hashes before any next deployment.
- Latest backup: `%LOCALAPPDATA%\Potassium\backups\ervi-final-20261114-015311` (prior installed scripts/workspace builds).
- Earlier backups from this continuation: `ervi-final-20261114-014354` and the checkpoint's `ervi-33-20261114-012053`.
- Latest build has executed in the actual RNG RollAttacks client through the local-file loader. Final live evidence is `final-latest-diagnostics.json`, `final-ui-suite.json`, `final-09-outlined-skeletons.png`.
- No new exact-commit GitHub loader exists for these pending changes. The older immutable URL still points to the previous checkpoint. Commit/push/remote verification remain pending.
- Potassium autoexec was verified empty earlier in the continuation; it was never written.

## Tests actually run

- Starting checkpoint: 161 unit / 527 smoke.
- Latest: **167 unit tests / 543 smoke checks, zero failures**.
- Both generated Luau artifacts compiled successfully on the latest source.
- Deterministic builds were verified on an intermediate continuation build. **Repeat determinism for the final pending build** before release.
- Tests added/updated cover Auto60/manual rates, legacy preferences, white tracers, thin black-outlined skeleton resources, Through Walls on/off and depth mode, between-tick presentation/rays/invisible heads, stable geometry, bar drag event ordering, M1 fraction and responsive text.
- New live suite: `tests/live/FinalAcceptance.client.luau`. It invokes only this hub's own UI callbacks; it must not be described as physical SendInput verification.

## Actual live acceptance results

`final-ui-suite.json` reports completed=true:

- UI scale 0.5, 0.75, 0.85, 1, 1.25, 1.5: **center stays exactly (960, 535.5)** throughout. Returned to original 0.85. Rendered widths/heights change correctly.
- Status bar opacity 0, 0.25, 0.5, 0.75, 1: transparency 1, 0.75, 0.5, 0.25, 0; main window hidden during each minimized state. Original value restored.
- Tracker filter temporarily changed and restored successfully. This is not a new full selection/respawn proof.
- Live overlay count: 40 visible white cores, 40 matching black outlines, 8 labels; DisplayOrder1000.
- Screenshot `final-09-outlined-skeletons.png`: actual latest live menu centered, compact M1 HUD/bar, names/distance and thin outlined skeletons drawn above the menu.
- PNG saving **works directly on Windows filesystem** using System.Drawing.CopyFromScreen and PNG encoding. Files were verified nonempty and inspected.
- `final-08-native-settings-click.png` is an **attempt**, not a successful Settings-click proof. The page stayed Home and camera moved; physical mouse targeting/foreground input remains unreliable. Do not label that test as passed.
- `final-baseline-diagnostics.json` is a **stale copy of an older 3.3 export** (source timestamp 00:36). It must not be used as new baseline evidence. `final-deployed-diagnostics.json` is intermediate 70f38b7988a9 evidence. Use `final-latest-diagnostics.json` for final deployed state.

## Studio baseline and measurements

Connected fixture: `ErviUITest.rbxlx`, Studio id `ff0987be-d55c-4f4d-ae4f-078a446cbc3d`, Play mode, Client/Server, PlaceId0, unpublished.

New JSON saved at pause: `reports/evidence/live-3.3/final-studio-benchmark-and-movement.json`. It contains raw numeric results rather than prose-only historical numbers.

Baseline unchanged Auto30, 2 owned R6/R15 rigs, 300 frames: mean16.6625ms, p95 18.0300ms, p99 18.6893ms. Off mean16.7051ms, p95 18.4557ms, p99 18.8879ms.

After presentation split (before final outline/Through Walls additions), three-second samples:

| Selected | Actual geometry Hz | Presentation Hz | Mean ms | p95 ms | p99 ms |
|---|---:|---:|---:|---:|---:|
|10|9.66|59.65|16.709|18.376|20.218|
|20|20.31|60.26|16.664|18.242|19.123|
|30|29.96|59.91|16.664|18.308|18.818|
|60|54.97|60.30|16.667|17.907|18.568|
|Auto60|59.92|59.92|16.665|18.519|19.415|

Geometry CPU mean approximately 0.45–0.50ms for these two rigs; 28 rays per visibility update; no added intermediate rays. Counts/costs are per this exact test condition, not a worst-case game benchmark.

Windows WMI reported a 1920x1200 165Hz display. Studio ran near60Hz. Reading `UserGameSettings.FramerateCap` failed: “lacking capability RobloxScript”. No 120/144Hz benchmark or system display-mode change was performed. Record these as unsupported/unverified conditions, not passed tests.

Native Studio scale-control clicks also held center (405,308.5), including minimum scale and a viewport-fitted maximum ~0.9023. Full physical Windows scale sweep was not achieved.

## Movement evidence

The owned Studio authority was verified present with protocol ErviStudioMovementV1, PlaceId0. `tests/studio/MovementProtocol.client.luau` was rerun and returned passed=true: excessive speed rejected; server teleport acknowledged and client position replicated within tolerance; modern flight constraints and ghost collision group replicated; timeout restored movers/humanoid/groups; malformed control released the controller. Result is in the JSON evidence above.

This is **not** target-game movement support. No new target-game movement, attack or protection operation was initiated. New full Safe Zone transaction/Click TP physical regression remains pending; preserve existing limitations.

## Automation notes and temporary files

- Desktop Commander device `c2230a28-a12e-4867-b9f5-baf374d40dd5` was online; filesystem/process access was tested.
- Local native helper: `%TEMP%\ervi-acceptance\windows.ps1`. Contains Win32 focus checks, SendInput and target-window PNG capture. Never send input when the foreground assertion fails.
- Potassium has multiple top-level windows. In this run the titled window HWND was3213790; it may change. Discover rather than reuse blindly. UI Automation root exposes Run as **Run script (Ctrl+Enter)**, not just Run.
- Script entries are Text elements; their immediate Group parent exposes InvokePattern. Invoke that parent to open a script without typing or filtering. Tab SelectionItemPattern selects the exact helper before Run. This worked reliably; mouse/foreground methods did not.
- Temporary own helper scripts created: Potassium Scripts `Ervi_FinalProbe.luau`, `Ervi_FinalAcceptance.luau`. Workspace has `Ervi_FinalAcceptance_Work.luau`, `Ervi_FinalAcceptance_Suite.luau`, and JSON outputs. Do not execute any helper blindly: inspect current Work content and selected tab first.
- User became concerned scripts had been deleted. They had **not**: initial 38 files were present. The script filter had been set to Ervi_FinalProbe, hiding other entries. It was cleared and must remain clear. Do not filter the list again without restoring it immediately. User's unrelated scripts/tabs were not deleted or overwritten.
- `%TEMP%\ervi-acceptance\settings-original.txt` is an **older backup**. User changed appearance mid-session and explicitly requested the new values as defaults. **Do not restore this old backup over the user's current choices.** Live suite restored its temporary scale/status changes in the active config. At pause current DEFAULT had 75% opacity,85% scale,Midnight/Indigo/Gotham,140% White text,outline auto. Saved config ikk remains separate. New fields throughWalls/tracerColor/skeletonThickness were serialized normally.
- Studio temporary folders ErviBaselineQA and ErviFinalQA, owned visual rigs and prior QA globals may still exist in Play mode. User paused before final cleanup. Do not destroy/publish/save the place automatically while paused.

## Resume checklist

1. Recheck Git, source and both installed hashes; preserve all pending work/evidence. Do not rebuild from old remote and overwrite this working tree.
2. Review the renderer changes and test edge cases: camera replacement, occlusion switching, large transforms, respawn, budget changes and disposal. Inspect the frame-by-frame projection CPU cost at higher available frame rates.
3. Complete physical live input regression (search, dropdown/numeric/key capture, drag-release, resize, Click TP suppression) without any unintended world click/combat. Current callback-based acceptance is explicitly separate.
4. Verify final M1 bar/resize and through-wall depth visually in a controlled fixture; final screenshot confirms appearance, not every lifecycle/behind-wall case.
5. Verify unload ownership/connections on final native build and restore temporary test state. Movement remains owned-fixture-only.
6. Update AGENTS visibility guidance/README/changelog/tasks/handoff to reflect the user's explicit new requirements. Older documentation is currently stale.
7. Repeat final tests, both compilation checks, determinism and git diff --check; inspect evidence for secrets/user data before committing.
8. Commit completed logical checkpoints, push only the development branch, verify remote tip and raw bundle hash, publish an exact-commit loader. No tag/full-release claim until remaining acceptance gates are satisfied.

## Last verified commands

```powershell
python build.py --test
& tools/luau/luau.exe build/tests.luau
python build.py --smoke
& tools/luau/luau.exe build/smoke.luau
& tools/luau/luau-compile.exe --null build/Ervi_Hub.luau build/loader.lua
```

Pause means no further implementation, execution, test input or deployment until the user resumes.
