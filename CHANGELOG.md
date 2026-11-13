# Changelog

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
