# Ervi Hub 3.2 development continuation — 2026-11-13

The existing checkout was continued on `dev/ervi-hub-3.1-handoff`; stable main was preserved. Baseline commit `31dafe61b1a8b48839e937bd576de9c1c8060071` and bundle `40b200576e75bb56f176c6df6fc25cecf611351bd9faabeff446f6cd209c1bc5` were reproduced before edits: 144 unit / 476 smoke, both compilations and deterministic output.

Final build: **3.2.0+4e59db554fde**. Bundle SHA-256: **6eb609a7dc0ef0bb8998ff6bbfd7a459bae49c760fdece5908699a79511a2443**. Exact published artifact commit, immutable loader, push verification and remote download hash are recorded in [release verification](../docs/RELEASE_VERIFICATION_3_2_0.md). This report distinguishes automated mocks, native Studio, actual client VM/virtual input and physical desktop testing.

## Phase A — native GUI

Implemented adaptive alpha-covered logo scanlines and an explicit width-led aspect constraint. The original 130:138 polygons are retained. Studio reproduced actual small-logo distortion from Roblox's integer offset dimensions; main native dimensions now measured 21.43636×22.75552 at the fitted scale, while the real client measured 24×25.47692 and status 18×19.10769. Combined main/status descendants dropped from 700 to 230. Logo fixtures show 18/24/48/96 widths at 75/100/125% scale.

An actual Studio dropdown showed an unsupported disclosure glyph. Native strokes now replace it and rotate with expansion. The final screenshot shows all four Update Rate options within the layout. Native drag input resized the main window from 786×518.05 to 772×478 inside an 810×675 viewport; responsive content reflowed and remained scrollable. Native minimize/pill restore and 0/100 opacity appearances were exercised; real-client property reads also covered 0/50/100 fills and outlines. Search navigation, active chip appearance, sidebar, notification controls and settings were inspected through the existing UI/test coverage. Timing smoothness is a visual assessment, not a frame-pacing benchmark.

Changed files: `src/Logo.luau`, `src/LogoGeometry.luau`, `src/Ui.luau`, `tests/LogoGeometry.spec.luau`, shared mock API support. Commits: `b6610b633d84bcd907df18d7c13c5e1efdf5b5f2`, `0dd8bcc43aa92abd57a506e14e52f4776e026836`. Images: [baseline](evidence/continuation/baseline-main.png), [logo scales](evidence/continuation/logo-final-scales.png), [final disclosure](evidence/continuation/dropdown-final.png), [native resize](evidence/continuation/resized-native.png).

Limits: not every theme/font/viewport/mobile combination, floating-panel variant or animation interruption was manually exercised. Physical live-client appearance/input was unavailable; a PrintWindow capture returned a blank game render area. Do not describe Studio screenshots as live target-game screenshots.

## Phase B — visible-player renderer

Inspected lifecycle, discovery, filtering, projection/rays, scheduling/budgets and cleanup. Duplicate per-update player scans and destruction/recreation at every occlusion transition were concrete sources of work. PlayerAdded/Removing now maintain a cache; friend checks run once per requested player; reusable candidates, ray parameters and bone projection caches reduce churn. Temporarily hidden bounded records are detached/disabled and reused; departure/disable/unload release drawing resources. Existing team/distance/target/skeleton/cadence controls, clear-line visibility and Occluded highlights are preserved. The smoke fixture models PlayerAdded/Removing rather than hiding stale-cache errors.

Native Studio fixtures rendered actual models, white outlined labels, boxes/health/skeleton budget and occlusion changes. The actual target client reported visible targets (including 7/24 in one snapshot, 1/24 in another) among 16 players. Counts change with camera/visibility. Live label appearance was not captured; the live probe counted zero visible name labels in its sampled state, so this is not a passed live text-style check.

Changed files: `src/Visuals.luau`, `tests/smoke/driver.luau`, shared mock event support. Commit `cb710c3fcef1f4bb313dc3484af6f34866725137`.

### Measurements

Native sandbox: 12 synthetic player records backed by actual anchored models/Humanoids, fixed camera, alternating occluder, 30 Hz updates. The benchmark adds an optional source seam and instruments `os.clock` around update without shipping that instrumentation. Detailed JSON is [retained](evidence/continuation/studio-benchmark.json).

| Initial 4-second window | Baseline | Updated |
|---|---:|---:|
| Player discovery calls | 265 | 1 |
| Update samples | 113 | 113 |
| Mean update CPU ms | 0.7723 | 0.6080 |
| p95 update CPU ms | 1.8615 | 2.6054 |
| Maximum update CPU ms | 10.0131 | 4.4528 |
| Mean Heartbeat interval ms | 5.1607 | 5.2128 |
| p95 Heartbeat interval ms | 10.8561 | 10.9731 |

A same-scene balanced sequence used 0.5-second warmups and 3-second windows: disabled / updated / baseline / updated / disabled. Mean Heartbeat intervals were respectively **5.0209 / 4.9851 / 5.1769 / 5.2606 / 5.0824 ms**; p95 **10.0283 / 9.9742 / 10.0222 / 10.9520 / 9.9859 ms**. Baseline discovery calls were 189; each updated run used one. The initial and balanced sequences are separate measurements, with different skeleton-budget setup; do not combine their CPU distributions.

Actual-client short disabled/enabled windows measured mean Heartbeat **4.6998 / 4.4819 ms**, p95 **6.0202 / 6.0079 ms**. These were not controlled render benchmarks and their target count was not held constant. Heartbeat cadence is not GPU/presented-frame FPS. Mean update CPU and scans improved in these samples, while p95/frame results were mixed; **no general FPS or variance improvement is established**. Longer representative profiling remains useful.

## Phase C — held targeting preview

Implemented `ClickTP` with pure target validation in `ClickTarget`. Five FeatureSchema controls persist/search through existing components: enable (false), hold binding (NONE), size 1–20/default 4, opacity 0–100%/default 65%, palette/validated hex color. Shared Motion drives one reusable noncolliding/nonquery cylinder. The held-key path respects capture/typing/processed input, validates finite/range/normal/humanoid targets, suppresses GUI input and hides on key release, focus loss or character changes. Disable/unload destroys ownership. Clearing a held binding releases it; re-enable rebuilds local-character ray exclusion.

Native tests exposed two coordinate defects. ScreenPointToRay added the top-bar inset again, shifting the marker: mouse (500,628) projected near (500,684). ViewportPointToRay corrected it; GUI hit tests separately subtract GuiService inset. This follows the official [Camera contract](https://create.roblox.com/docs/reference/engine/classes/Camera#ViewportPointToRay) and [GUI hit-test contract](https://create.roblox.com/docs/reference/engine/classes/BasePlayerGui#GetGuiObjectsAtPosition), checked alongside engine observations. New smoke checks failed before each correction, then passed; lifecycle regressions also failed before their fixes.

Native Studio F8 capture, held marker, left-click selection, GUI suppression, release and main/pill restore were exercised. Selection reported the destination while the character remained exactly (0,3.5227282,0). The raised marker center projected within 1.148 pixels of the raw cursor (0.04-stud surface offset avoids z-fighting). Real target-client virtual F8 capture showed a marker with 0.142-pixel alignment, then release, key clearing and disable cleanup. Evidence is in [native target checks](evidence/continuation/studio-click-target.json), [native target image](evidence/continuation/click-target-aligned.png), and the live JSON reports.

No permitted arbitrary server teleport mechanism was established. Selection is a real targeting preview; no character movement, game remote or simulated success was added. A live virtual GUI-hover test initially returned false because its Teleports item was clipped below the sidebar (item Y371–403, visible range Y75–346). A corrected visible-control query hit Nav_roll with the marker absent, but no marker was present immediately beforehand; a complete live show-to-hide transition remains unproven. Native Studio's complete transition passed. Retained reports include both attempts. Physical desktop input/rendering remains unverified.

Changed files: `src/ClickTP.luau`, `src/ClickTarget.luau`, `src/FeatureSchema.luau`, `src/Expansion.luau`, `src/App.luau`, `src/Locale.luau`, `build.py`, `tests/ClickTarget.spec.luau`, `tests/run.luau`, smoke driver/API support. Commit `351dd67776908f2956562accfa6f3cbd487233c0`.

## Phase D — authority investigation

Inspected SafeZone, PositionHold and character/physics correction watchers. In the authorized local Studio place, a client PositionHold moved its character to (12,3.5227282,0), anchored. A distinct server DataModel still observed (0,3.5229716,0), unanchored, despite reporting the player as network owner. The client explicitly returned to A while held, then restored unanchored physics. The target-game place guard was retained; this exercised the helper rather than pretending SafeZone was supported in place 0. [Authority evidence](evidence/continuation/studio-authority.json).

Read-only target-client instance metadata found teleport FX/sounds, a map teleporter script and SafeZoneShield ForceFields. No remote was invented/called, script decompiled, validation bypassed or protection created. Names do not establish a permitted arbitrary teleport/protection API. Actual target-game server position, correction ownership and damage authority could not be inspected; no two-client server comparison was available there.

Safe Zone's ON status now explicitly says local hold and unverified server position/protection. Its existing A→B→A behavior and correction/death/no-retry rules remain unchanged. Changed file `src/SafeZone.luau`; commit `108d803ebe333dca779ddd145159e81087b63ca3`.

## Phase E — common verification, deployment and release record

The following release facts apply to all phases above; test counts are the final combined integration suite, not separate isolated test runs for each source commit.

1. Implementation/fixes and changed files are listed per phase above. Current README, changelog, handoff, start prompt, feature inventory, evidence and generated artifacts are updated together.
2. Baseline and final tests ran in the existing Windows checkout. **148 unit tests passed, zero failures.**
3. **494 smoke checks passed, zero failures.** Existing tests were retained; new checks include record reuse, preview semantics, coordinates and lifecycle.
4. Both generated release and loader **compile successfully** with pinned Luau 0.746.
5. Repeated release, line-map and loader builds are **byte-identical**. [Validation manifest and command logs](evidence/continuation/validation.json) give exact commands/exits/hashes.
6. A deliberately inverted target-normal predicate produced a unit failure (147 pass / 1 fail); the original source was restored before final validation. The ray/GUI/lifecycle old implementations also failed the new regressions before fixes.
7. Native Studio and actual client evidence are described separately above. No Roblox place was saved/published. Desktop Commander was online, and native Windows UI Automation reached Potassium's file selector and Run control. Terminal access alone was not treated as graphical proof.
8. Performance measurements are reported above with limitations; no estimated/rendered FPS claims are substituted for engine timings.
9. Final source commits are recorded per phase. The artifact/documentation commit and **exact immutable loader URL** are recorded in [release verification](../docs/RELEASE_VERIFICATION_3_2_0.md) after push. Later documentation-only tips may differ without changing the bundle.
10. Final bundle SHA-256 is `6eb609a7dc0ef0bb8998ff6bbfd7a459bae49c760fdece5908699a79511a2443`.
11. Both `%LOCALAPPDATA%\Potassium\scripts\Ervi_Hub.luau` and `%LOCALAPPDATA%\Potassium\workspace\Ervi_Hub.luau` were copied and hash-verified after backups. [Deployment manifest](evidence/continuation/deployment.json) records paths, backups and original/new hashes.
12. Existing setting values survived testing; ten new defaults across two configs reflect schema migration. Bundle deployment itself left settings bytes unchanged. Autoexec was verified empty. The user's unsaved Potassium tab was preserved.
13. The final exact installed build was executed through the separate Ervi_3_2_0 entry. Its bounded runtime export confirms target place/universe, boot, visible main window, zero group transparency, unanchored character, inactive preview and no captured hub errors. Existing user ESP preferences were retained.
14. Stable `main`, repository visibility, security protections and unrelated files were not changed. Source history and local installed-build backups provide rollback; nothing was force-pushed or reset away.
15. Remaining limitations: physical target-game UI/capture, live label appearance, representative long-run performance and server-authoritative arbitrary movement/protection. CFrame Speed/Fly and automated PvP bypasses remain unsupported. These do not prevent shipping the independently verified native UI and targeting preview.

All runtime probes are bounded diagnostics, not a permanent command listener. Player names in retained metadata are redacted before repository publication. Temporary Studio play and localhost source bridge are stopped before handoff.
