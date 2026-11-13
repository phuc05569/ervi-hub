# Local functional development candidate

Current local candidate: **3.5.0-dev+b391196c1bb3**, on `dev/functional-audit-3.4`. Published **v3.4.0 remains unchanged**. No development push, Potassium deployment or new release is authorized yet.

Read [functional audit](reports/FEATURE_FUNCTIONAL_AUDIT.md), [movement evidence](reports/MOVEMENT_AND_SAFEZONE_TESTS.md), and [Claude UI handoff](reports/CODEX_TO_CLAUDE_UI_HANDOFF.md). The candidate adds native Click TP, configurable A/B zones, low-health emergency movement, avatar ESP, corrected Set/Multiply speed, scoped Fly/Noclip, position tools, key modes, Visibility Mode migration, color/background controls and independent viewport notifications. UI design is preserved. Target-game movement/protection and automated combat are **not** newly verified. Build/test instructions below still apply; use `python build.py --test`, Luau unit runner, `--smoke`, smoke runner and compile both artifacts.

The remaining README describes the **published 3.4 baseline**. Its older feature limitations/defaults are superseded only in the local candidate by the linked audit; do not use historical claims as current live evidence.

---

> 14 Nov 2026: current **development checkpoint 3.3.0+5ba5f7088681**, 161 unit / 527 smoke passing. Release remains incomplete. See [checkpoint report](reports/CONTINUATION_3_3_CHECKPOINT.md).

> **Current development checkpoint: 3.2.0+4e59db554fde.** 148 unit tests / 494 smoke checks pass; both artifacts compile and rebuild deterministically. See [current handoff](docs/LOCAL_CODEX_HANDOFF.md), [phase report](reports/CONTINUATION_3_2_0.md), and [release verification](docs/RELEASE_VERIFICATION_3_2_0.md) for exact commit/loader and evidence. Bundle SHA-256: `6eb609a7dc0ef0bb8998ff6bbfd7a459bae49c760fdece5908699a79511a2443`.

Current navigation is Auto Roll, Styles, Home, Combat, Visuals, Player, World, Safe Zone, Teleports, Utility, Settings (3.4 removed Config; settings save automatically). Settings stays docked at the bottom. Friends/Sounds/Triggerbot/Freecam remain removed. Saved keys and settings remain compatible; RightShift is the default menu key. Auto Roll retains one worker/request, terminal results, ordinary readiness/respawn handling and no blind retry. Custom N stays integer 1–5000.

**Teleports → Click TP preview:** enable, bind a hold key (default NONE), then hold to aim, click to select and release to hide. Size, percentage opacity and color are configurable. One reusable indicator rejects invalid/steep/over-range/humanoid destinations and suppresses GUI input. Rebinding, disable, focus/character changes and unload clean up the preview. No permitted arbitrary server teleport adapter exists; selecting never moves the character or reports teleport success.

The official logo now has adaptive alpha-covered scanlines and a width-led aspect constraint, fixing native size quantization. Dropdowns use native strokes to avoid missing font glyphs. Overlays cache player discovery, ray parameters/candidates and bounded drawing records. The owner-requested Through Walls toggle (3.3, default on) draws client-replicated characters regardless of occlusion; turning it off restores line-of-sight-only drawing with Occluded highlights. Invisible-headed/dead targets remain suppressed. Labels retain white text/black outlines. No general rendered-FPS improvement is claimed from the short Heartbeat/CPU benchmarks.

Safe Zone remains the place-scoped local A→B→A transaction. Explicit OFF/unload returns before releasing anchoring; corrections/death release without return/retry. A distinct Studio server still saw A during the client's local hold at B. Target-game server position/protection remains unverified; a replicated SafeZoneShield ForceField is not evidence of permission to create protection or teleport arbitrarily.

Both verified Potassium scripts/workspace Ervi_Hub.luau paths contain this build after backups. Existing setting values were preserved and autoexec is empty. Local execution remains `loadstring(readfile("Ervi_Hub.luau"))()`. The separate Ervi_3_2_0.luau entry was executed through Potassium UI Automation without replacing the user's unsaved tab. Its bounded runtime export is Ervi_3_2_0_Runtime.json.

Native Studio screenshots/input verified logo scales, status appearance, a dropdown, resize, preview selection/release and GUI suppression. Potassium executed the hub in the actual target game and exported runtime data. A virtual hover probe initially targeted a clipped sidebar item; a corrected visible-control query hit the expected button with the marker absent. A complete live show-to-hide transition, physical desktop input and rendered live capture remain unverified.

## Historical 3.0 reference below

The remaining text records an older release, including removed tabs and tools. Use the current handoff and phase report for current behavior, tests and deployment.

# Ervi Hub — RNG RollAttacks

Current build: **3.0.0+e31b35baa4a4**. Bundle SHA-256: `f89dc4a883316313cc21499fa844c1be7b9bfc7d339cf0a737cef1e0c9a0f3b1`.

Run `build/Ervi_Hub.luau` in the existing Windows Roblox/Potassium workflow. This cloud build has not been copied into the Windows script/workspace folders. **Live Roblox rendering, executor permissions and server acceptance remain unverified.**

## 3.0 interface

Original dark-purple **Bloom** theme with rose accents, an original native logo/gradient, fixed navigation sidebar, profile footer, tab header, global search, rounded cards, shared controls and an adaptive Visuals preview. No HANAMIHUB name, artwork, invitation or source was copied.

The twelve main tabs are **Home, Combat, Triggerbot, Sounds, Friends, Visuals, Player, World, Teleports, Utility, Config, Settings**. Existing **Auto Roll, Styles, Diagnostics and Session** tools remain accessible in the scrolling sidebar.

- **Home:** avatar/game thumbnails through Roblox-native URLs, player/server information, hub-session duration, FPS ring/ping, session actions, actual active-feature chips, capability presence checks, and copy/clear logs. Community UI appears only after a user configures a link.
- **Settings persistence (3.4):** no Config page; every change auto-saves (debounced, flushed on unload) to the profile that was effective at upgrade. Legacy named profiles and autoload lines are kept, and the original file is backed up once.
- **Player:** local WalkSpeed with Set/Multiply modes and a rebindable key; a themed, menu-controlled movement panel with saved drag/corner-resize geometry and size control. Disabling or replacing the character restores owned values. Server speed updates are not fought in a loop.
- **World:** Fullbright, No Fog (including late Atmosphere), No Shadows, selected time, Freecam and Reset Camera. Owned properties restore without overwriting subsequent game changes. Freecam uses RMB + WASD / Q E, owns its camera/input state and releases it on disable, character/camera replacement or unload.
- **Visuals:** native GUI overlays for visibly headed players; line-of-sight filtering follows the Through Walls toggle. Boxes/corners/none, health, names, distance, skeleton, head dot, Occluded chams, tracers, clear-line off-screen arrows, team/friend filtering, palettes/hex colors and a responsive native mannequin preview. Fully hidden players are suppressed. Behind Wall color and hidden-target demonstration are preview-only.
- **Performance controls:** motion-adaptive Auto rate (10 Hz stationary / 30 Hz camera changes), explicit 10/20/30 Hz rates, 2-projection cheap boxes or full bounding-box projection, maximum targets, skeleton budget, full-rate ranks, far update interval, distance, text size and vertical offset. Overlay records are bounded and cleaned up; skeleton resources are created only when needed.
- **Utility:** existing Anti AFK/reconnect/local-file auto-execute controls remain in Session; Utility adds Rejoin, Server Hop, Copy Job ID, Check Reinjection and compatible FPS-cap control. FPS **0** restores/leaves the prior cap unchanged. Positive caps require getter + setter so unload can restore the prior value.
- **Settings:** 0–100% menu background opacity, theme/accent/font/text controls, main-window geometry, blur while open, GUI/search/panic keys and EN/RU interface labels. Player names, diagnostic evidence, API errors and untranslated descriptions remain verbatim.

## Controls and preserved behavior

- **RightShift:** show/hide the main window by default. **End:** panic/unload by default. **Ctrl+K:** focus search; arrows select, Enter opens and highlights a result, Esc closes. Search, panic, speed and visualization keys are configurable.
- Main window: drag the header; resize from its bottom-right corner. Position/size persist in the active config and fit the viewport. Floating M1/movement panels follow the same contract and are controlled from the menu.
- **Combat → Show M1 cooldown HUD:** the only M1 HUD. The candidate `AttackReadyAt` clock interpretation remains visibly **UNVERIFIED**; missing evidence shows UNKNOWN. The standalone Cyborg HUD does not return.
- **Teleports → Enable Safe Zone:** existing fixed XYZ **278.78, −16.30, 7.82** local move and hold. OFF/death/root or character removal/unload/rerun releases its owned anchor state. External correction releases instead of retrying. Key default remains **NONE**; Backspace clears a captured binding. No automatic respawn activation is added.
- **Auto Roll → Resume Auto Roll After Death:** retains the existing worker and target while waiting for normal readiness. At most one request is in flight. Qualifying results are terminal; uncertain/error results pause without blind retry.
- The existing local loader remains: `loadstring(readfile("Ervi_Hub.luau"))()`. The generated `build/loader.lua` distribution template remains unconfigured. No autoexec-folder file is installed.

## Unsupported reference operations

CFrame speed/correction fallback, noclip, fly (including its key/modes/speed), Triggerbot/aim automation and automated PvP attacks are unavailable because no game-authorized mechanic is established and the task excludes bypasses. Since 3.3 the owner-requested Through Walls toggle controls occlusion (AlwaysOnTop chams when on, Occluded when off); dim-behind-wall remains unimplemented. A separate Mobile Renderer toggle is unnecessary because the implementation already uses native GUI rendering.

Sounds and detailed Friends contents were not shown, so those tabs contain honest scope/compatibility information rather than speculative controls. Friendship filtering uses Roblox's cached friendship query. Capability checks report **presence**, not guaranteed permission. FPS adjustment is disabled when restoration APIs are unavailable.

The existing local Safe Zone hold is preserved as previously requested; it is not proof of a server-designated protected area or server-approved movement.

## Build and tests

From `/workspace/ervi-hub` in the cloud (use the pinned Windows `.exe` tools on Windows):

```bash
python3 build.py
python3 build.py --test && tools/luau/luau build/tests.luau
python3 -I tests/smoke/gen_rbx_api.py tools/rbxapi/API-Dump.json build/rbx_api.luau
python3 build.py --smoke && tools/luau/luau build/smoke.luau
tools/luau/luau-compile --null build/Ervi_Hub.luau
tools/luau/luau-compile --null build/loader.lua
```

Current validation: **127 unit tests / 423 smoke checks pass**; release and loader compile. Tests include the full mounted settings catalog, search, import/export, lighting/camera restoration, movement state/respawn, rendering occlusion and budgets, supported/unsupported API paths, concurrent features and resource cleanup. These are headless tests, not a live FPS benchmark or graphical validation.

Source is authoritative under `src/`; `build.py` generates the bundle/map/loader deterministically. Settings retain `RNG_Hub_settings.txt`. Imported `ERVI_CONFIG_V1` text is capped at 64 KiB. Original baseline remains at `baseline/baseline_v1_original.luau`; pre-3.0 rollback archive is in ignored `backups/`.

Complete screenshot/control inventory: [UI_FEATURE_CHECKLIST](reports/UI_FEATURE_CHECKLIST.md). Architecture, evidence, performance limits and deployment status: [3.0 continuation](reports/CONTINUATION_3_0_0.md). Read [AGENTS.md](AGENTS.md) and [HANDOFF.md](HANDOFF.md) before future changes.
