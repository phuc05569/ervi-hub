## 3.4.0 interface redesign — 2026-11-14 (development branch, not a release)
- Liquid-glass-inspired look: specular gradient rims re-derived on every theme change, soft luminance gradients, 16/14/12/8 px radii, glass nav pill, title chips, search, cards, dropdowns, notifications, tooltips and profile card. No backdrop blur is claimed (Roblox UI has none).
- Exact Ervi logo as an antialiased PNG rendered from `LogoGeometry`; Lucide (ISC) icon atlas with a distinct icon per section. Both PNGs are embedded in the bundle, written to the executor workspace at start and used via `getcustomasset` only after `ContentProvider:PreloadAsync` reports Success; otherwise the native logo/icons are used.
- Motion: named easings on the existing Motion owner; 240 ms open / 160 ms close, gliding nav pill, page slide, spring toggles, notification slide-in/out; reduced-motion and speed preferences respected.
- Config page and slot manager removed. The previously effective profile (per-game autoload, global autoload, Default) auto-saves: writes are debounced (350 ms) and flushed on unload/teleport; other named profiles and autoload lines stay in the file; the original file is copied once to `RNG_Hub_settings.pre-autosave-backup.txt`. Sidebar shows save status.
- Sliders accept typed values (percent sliders take the shown percent); values are rounded to remove float noise.
- Skeleton thickness 0.1–3.0 px in 0.1 steps. Studio showed Frames under 1 px are not drawn (the old 0.5 px minimum was invisible) and fractional widths snap to pixels, so sub-pixel values use a 1 px line with matching opacity and 1 px+ rounds to whole pixels (stated in the readout).
- Live acceptance fixes (Potassium, RNG RollAttacks): a double-attached executor runs every script in two contexts with separate `_G`, which started two hubs (two status pills, M1 HUDs and autosave writers). Each hub now owns a shared `ErviHubStopSignal` BindableFunction in PlayerGui that a new run invokes synchronously, and startup removes every stale copy of hub GUIs. The status pill no longer keeps a drag armed after a missed release (Esc menu/focus loss/hidden pill), which had moved and saved the pill on unrelated clicks; the pill now uses the liquid-glass rim and sheen.
- Tests: 173 unit / 554 smoke. Details and evidence: reports/UI_REDESIGN_3_4.md, reports/evidence/ui-3.4/, reports/evidence/live-3.4/.

## 3.3.0 development integration — 2026-11-14 (development branch, not a release)
- Owner-requested Auto update rate is 60 Hz (manual 10/20/30/60 kept); `VisualPolicy.rate` centralizes it.
- Main window: centered AnchorPoint, inset-aware viewport bounds, session-local center; reopening recenters; drag ignores the window's own UIScale. Fresh-config appearance defaults: 75% opacity, 85% scale, Midnight/Indigo/Gotham, White text at 140%. Explicit saved values win.
- Visuals: persisted White tracer color; skeleton thickness setting with a black outline under a white core; owner-requested **Through Walls** toggle (default on; disabling restores line-of-sight-only overlays, Occluded highlights). Uses client-replicated characters only; dead/invisible-headed/distant/filtered players stay excluded. Visibility checks run at the update rate while projection follows each rendered frame; overlay roots are non-interactive (DisplayOrder 1000).
- Minimized status bar: drag gestures never restore the menu on release (travel-based suppression).
- M1 HUD: compact, size-responsive text and a cooldown bar from observed deadlines (clock interpretation unverified; no attack or cooldown remote is called).
- Verification at the paused checkpoint: 167 unit / 543 smoke, both artifacts compile. Live/Studio evidence and its limits are in docs/PAUSED_HANDOFF_2026_11_14.md and reports/evidence/live-3.3/.

# Changelog

## 3.2.0 development checkpoint (2026-11-13)
- Build `3.2.0+4e59db554fde`; bundle SHA-256 `6eb609a7dc0ef0bb8998ff6bbfd7a459bae49c760fdece5908699a79511a2443`.
- Added persisted/searchable Click TP targeting preview: held binding/default NONE, reusable circle, size/color/percentage opacity, target validation and input/lifecycle cleanup. No server teleport is implemented or claimed.
- Fixed native coordinate defects: raw mouse rays use ViewportPointToRay; GUI hit tests subtract GuiService inset. Clearing a held binding and re-enabling correctly reset the preview and character exclusions.
- Fixed actual small-logo aspect drift with a width-led constraint. Adaptive sampling/alpha coverage reduces combined logo descendants from 700 to 230. Replaced a missing dropdown disclosure glyph with animated native strokes.
- Cache player discovery/friend queries, candidates/ray parameters/bones and bounded drawing records through temporary occlusion. Visibility restrictions and budgets remain intact.
- Safe Zone status explicitly identifies local hold and unverified server position/protection; a client/server sandbox comparison demonstrated differing positions.
- Verification: 148 unit / 494 smoke pass, both artifacts compile, deterministic outputs. Native Studio screenshots and bounded actual Potassium/RNG reports are retained. Physical live input/rendering and a contradictory virtual hover probe remain explicit limitations; benchmark noise does not establish an FPS gain.
- Both Potassium bundle paths deployed after backups; existing setting values preserved; autoexec empty. Exact published commit/loader are in docs/RELEASE_VERIFICATION_3_2_0.md.

## 3.1.0 development handoff (2026-11-13), NOT LIVE TESTED
- Verified checkpoint build 3.1.0+5e9595329868; bundle SHA-256 `40b200576e75bb56f176c6df6fc25cecf611351bd9faabeff446f6cd209c1bc5`.
- Added persisted Status Bar Opacity control with immediate updates to the minimized pill background.
- ESP name/distance labels now share white text and visible black outlines through a reusable style helper.
- Added Auto Roll Custom N integer slider (1–5000) and synchronized exact input; values clamp at bounds, reject decimal/text input, persist, and update the active rarity target.
- Added dedicated regression tests for schema defaults/ranges, save/load and legacy compatibility, actual pill updates, rendered ESP styling, and Custom N synchronization/clamping/target application.
- Verification: **144 unit tests, 0 failures; 476 smoke checks, 0 failures; both Luau artifacts compile; two consecutive bundles are byte-identical**. Roblox Studio and live-game behavior were not verified.
- The original 3.1 features remain on the development branch. CFrame Speed/Fly and live Windows/Roblox verification remain unfinished.
- Logo source audit found a clean 1024×1087 transparent PNG and matching SVG, but Roblox cannot consume these local files without an uploaded asset ID. Native geometry now uses 2× scanline sampling (276 rows for the 138-row viewbox) and exact 130:138 sizing at each logo location. Added geometry and multi-size aspect regression tests.
- GUI visual source pass also made minimized status fill, border and feature-chip backgrounds respond together across 0–100% opacity, displayed opacity as a percent, and made notifications smaller and translucent.
- Roblox Studio MCP was unavailable for screenshots: Studio opened and responded, but MCP listed zero connected places and the previous instance ID was disconnected. No actual Studio screenshots or live GUI verification were produced; remaining rendering quality is not marked visually verified.
- Transparent owner-logo assets and native mark; independent draggable minimized status pill with real feature chips/FPS/ping/roll state and click-to-restore.
- Auto Roll/Styles first, Settings last; removed Friends/Sounds/Triggerbot/Freecam. Multiply default preserves saved Set.
- Safe Zone key controls in its own tab and Settings; typing/conflict guards; explicit OFF returns to per-activation origin before releasing hold. Corrections/death release without return.
- Search reveals target ancestors and waits for layout before scrolling/highlighting. Removed optional Auto Roll safety UI/rare pause/default roll cap while retaining request protocol guarantees.
- Earlier baseline: 131 unit tests and 441 smoke checks passed; both artifacts compiled and rebuilt deterministically. CFrame Speed/Fly and live Windows/Roblox verification remain unfinished.


## 3.0.0 (2026-11-13), build 3.0.0+e31b35baa4a4, NOT LIVE TESTED
- Original Bloom/rose interface foundation: 12 main navigation tabs, retained Ervi tools, profile footer, tab header, native logo/gradient, scrolling/responsive controls and persisted/clamped main geometry.
- Shared feature schema, native control registry, bilingual settings search, Ctrl+K/keyboard navigation and highlighting. EN/RU interface labels and optional lightweight native tween transitions.
- Expanded Home with native thumbnails, game/server/session data, reusable FPS ring, active-feature chips, configured-only community link, capability checks and logs.
- Named config selection/save/load/delete/rename, per-game autoload and validated bounded schema-v1 clipboard import/export, retaining legacy configs.
- Local WalkSpeed Set/Multiply with keybind and restore-safe respawn support; persistent movement panel. No CFrame fallback, noclip or fly bypass.
- Restore-safe lighting/time/atmosphere overrides, camera/input-owned Freecam, Reset Camera and owned background blur.
- Visible-player native overlays and original live preview: boxes/corners, health/name/distance/skeleton/head dot, Occluded highlights, tracers/arrows, cached friend/team filters, colors and actual scheduling/resource budgets. No hidden-player/wallhack drawing.
- Session quick actions, bounded public server-hop request/selection, reinjection check and restore-safe FPS cap when getter/setter are available.
- 127 unit tests / 423 smoke checks pass, including all mounted schema controls and concurrent cleanup. Both artifacts compile. Unsupported reference operations and live-test limits are tracked individually in reports/UI_FEATURE_CHECKLIST.md.

## 2.6.2 (2026-11-13), build 2.6.2+3bd3d5e499ce, NOT LIVE TESTED
- Fix Safe Zone falling after its one-shot move: ON now holds the root anchored and clears falling/spin velocity. OFF restores its previous anchor state without replaying old velocity.
- Transactional PositionHold helper rolls back physics on move failure. Hold listeners/physics release on death, root/character removal, unload and rerun.
- External unanchor or position correction disables the hold without a retry or correction-fighting loop. Key defaults to NONE; existing bindings remain supported.
- Tests: 106 unit / 271 smoke checks, both artifact compilations and deterministic build verification. Real game/server acceptance remains unverified.

## 2.6.1 (2026-11-13), build 2.6.1+e630a2ff0ebf, NOT LIVE TESTED
- Owner's screenshot coordinates are now the fixed Safe Zone: X 278.78, Y -16.30, Z 7.82. Removed setup/capture/replace/clear controls.
- Enable Safe Zone performs one local PivotTo translation, preserving facing direction. OFF does not move. No holding, retries, server-correction counteraction or automatic respawn movement; wrong-place/dead/missing-character/error paths fail visibly.
- New Safe Zone toggle key defaults to NONE. Old reference bindings are ignored for this changed action. Rebind in Settings; Backspace unbinds; typing/conflict guards and config persistence remain.
- Manual target selection now uses the fixed place-scoped destination without setup.
- Tests: 101 unit / 256 smoke checks; both artifacts compile. Live server acceptance remains unverified.

## 2.6.0 (2026-11-13), build 2.6.0+d4bd70143994, NOT LIVE TESTED
- Removed the standalone Cyborg module/HUD/menu controls. Only the M1 HUD remains; it has no Close button and is controlled from Combat.
- Shared FloatingWindow + WindowGeometry provide themed title dragging, corner resizing, viewport bounds, scrolling content and persisted layout. Added the permanent floating-window contract to AGENTS.md.
- Menu background opacity range expanded to 0–100%.
- New Safe Zone section captures/replaces/clears position and orientation, scoped to PlaceId. F6 opens coordinates/distance; rebindable with conflict and typing guards. No movement or physics changes.
- Auto Kill manual-combat alternative: stable selection below an adjustable HP percentage, lifecycle-safe read-only observation, explicit unsupported Auto M1 request setting. No movement, floating, return or automated attacks.
- Persistent Resume Auto Roll After Death waits in the same worker, preserving readiness checks and target. Newly qualifying/rare styles are rechecked after waiting. Uncertain requests never retry.
- Tests: 99 unit / 245 smoke, release and loader compilation, deterministic output, persistence, viewport resizing and integrated respawn/lifecycle checks.

## 2.5.0 (2026-11-13), build 2.5.0+c99431989fa5, NOT LIVE TESTED
- New optional M1 HUD observes player AttackReadyAt for any equipped style, explicitly labels the server-clock assumption as unverified, and clears stale evidence on style changes, re-equips, death and respawn. Does not assume Tool.Activated proves an accepted attack.
- Combat shows current health percentage. Existing Cyborg V6, keybinding, opacity, appearance, resize, Auto Roll and local teleport loader behavior are preserved.
- New original loader core and generated build/loader.lua template: exact-commit GitHub URL, place routing, bounded download retries, version/banner checks, duplicate/concurrent-load guards and failure cleanup. URL is intentionally blank; no cache, publication or credentials.
- Tests: 68 unit tests and 210 smoke checks pass, including interruption during initialization, HUD lifecycle and generated loader fail-closed behavior. Both artifacts compile; baseline remains byte-identical.
- Cloud-only build; Windows/Potassium copies and GitHub were not updated. See reports/CONTINUATION_2_5_0.md.

## 2.4.0 (2026-11-13), build 2.4.0+1276e5c68ba3, NOT LIVE TESTED
- Corner resize grip (bottom-right): drag to resize between 520x360 and 1100x820; size saved in the active config; hidden while minimized.
- Configs: per-row Overwrite button (asks once) copies the current settings into that saved config.
- New Utility tab: Instant proximity prompts toggle. Sets HoldDuration to 0 when a prompt is shown or held (event-driven, no workspace scan) and restores the original hold times when turned off or when the hub closes.
- Not built: player ESP (positions and distance through walls).
- Tests: 40 unit, 184 smoke checks; 2 planted bugs caught.

## 2.3.0 (2026-11-13), build 2.3.0+e063092eff8d, NOT LIVE TESTED
- Renamed to **Ervi Hub**: silver Merriweather title with a dark outline (stays the same in every look). Script file is now `Ervi_Hub.luau`.
- Auto-execute is now a Session-tab toggle using `queue_on_teleport`: Ervi Hub re-runs after teleports and rejoins from `Ervi_Hub.luau` in Potassium's workspace folder. The autoexec-folder file is gone. A fresh Roblox launch still needs one manual Run.
- Anti-AFK toggle: on Player.Idled, one VirtualUser right-click (the widely used method).
- Auto-reconnect toggle: watches the error event and the on-screen error prompt; rejoins after connection/server errors only (5 tries, 10 s apart), never after kicks, bans or security disconnects.
- Color circle (hue by angle, saturation by distance, brightness slider, hex box) for custom accent, text and background colors. A custom background derives lighter panel shades automatically.
- Tests: 39 unit, 164 smoke checks; 3 planted session bugs caught.

## 2.2.0 (2026-11-13), build 2.2.0+a94ef520f8d5, NOT LIVE TESTED
- Configs: named configs in one file; the active config auto-saves; Save as (asks before overwriting), Load, Delete (asks once), Auto marks the config that loads on start. A 2.1.x settings file migrates into "Default".
- Appearance: 6 designs (Midnight, Graphite, Ocean, Crimson, Forest, Light), 7 accent colors + Auto, 8 fonts (only ones in Enum.Font), text color, text size 80–140%, text outline Auto/On/Off, text transparency 0–60%. Applies instantly to the hub and the Cyborg overlay, including UI built later.
- Window size presets now include 80%.
- Auto-execute: `build/RNG_Hub_autoexec.luau` installed to Potassium's autoexec folder; it starts the hub only in RNG RollAttacks (place 119338513416973 / universe 10768634654). Remove that file to turn it off.
- Not built: teleport to low-health players and teleport back to a saved safe-zone position.
- Tests: 38 unit, 138 smoke checks; spot-checked with planted bugs.

## 2.1.1 (2026-11-13), build 2.1.1+7c256081fa4e
- Fix: pressing Run twice quickly left an invisible second copy running (seen in the live console at 08:06:22). The stop handle is now registered before anything can pause, so a new run always stops the old one. A smoke test reproduces the old bug (114 orphaned connections) and passes with the fix.
- First live evidence (Roblox console, place version 969): 2.1.0 loaded, and Auto Roll ran 31 rolls then paused on Cyborg (1/195) as designed.

## 2.1.0 (2026-11-13), build 2.1.0+59021e637713, NOT LIVE TESTED
- Rebindable show/hide key (default RightShift): Settings → click the key button, then press a key; Esc cancels. Ignored while typing.
- Menu opacity slider (35–100%, 5% steps) applied to the window, panels, cards and the Cyborg overlay. Text gets a soft outline below 60% to stay readable.
- Settings (key, opacity, window size) saved to `RNG_Hub_settings.txt` in the executor workspace when file access exists; Reset settings button.
- Tests: 33 unit tests (5 new for Settings) and 88 smoke checks (26 new). The v2.0.0 build is backed up in `backups/`.

## 2.0.0 (2026-11-13), build 2.0.0+53de84095b94, NOT LIVE TESTED
- New modular source (`src/`) and a deterministic single-file bundle with a source map.
- Full UI redesign: design tokens, one draggable window with 6 tabs, scaling that fits the screen, minimize, RightShift hide, a reliable × and an emergency unload.
- Lifecycle: every connection, GUI and thread belongs to a cleanup scope. Rerunning cleans up the old instance, including baseline v1 GUIs and globals.
- Cyborg M1 tracker: same V6 detection rules, now listening on your own HumanoidRootPart instead of all of workspace, rebinding on respawn, and only repainting labels whose text changed.
- New: Auto Roll state machine (start, stop, continue; stop on target; pause on uncertainty).
- New: read-only roll observer diagnostic, environment snapshot and hub log, each with a Copy button.
- New: Styles browser and Dashboard, both driven by the game's own AttackData.
- Tests: 28 unit tests, a 62-check headless smoke test validated against the Roblox API dump, and mutation checks.

## 1.0 (baseline, user-verified Cyborg V6)
- Preserved unchanged in `baseline/baseline_v1_original.luau`.
