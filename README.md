# Ervi Hub — RNG RollAttacks

Current build: **3.0.0+e31b35baa4a4**. Bundle SHA-256: `f89dc4a883316313cc21499fa844c1be7b9bfc7d339cf0a737cef1e0c9a0f3b1`.

Run `build/Ervi_Hub.luau` in the existing Windows Roblox/Potassium workflow. This cloud build has not been copied into the Windows script/workspace folders. **Live Roblox rendering, executor permissions and server acceptance remain unverified.**

## 3.0 interface

Original dark-purple **Bloom** theme with rose accents, an original native logo/gradient, fixed navigation sidebar, profile footer, tab header, global search, rounded cards, shared controls and an adaptive Visuals preview. No HANAMIHUB name, artwork, invitation or source was copied.

The twelve main tabs are **Home, Combat, Triggerbot, Sounds, Friends, Visuals, Player, World, Teleports, Utility, Config, Settings**. Existing **Auto Roll, Styles, Diagnostics and Session** tools remain accessible in the scrolling sidebar.

- **Home:** avatar/game thumbnails through Roblox-native URLs, player/server information, hub-session duration, FPS ring/ping, session actions, actual active-feature chips, capability presence checks, and copy/clear logs. Community UI appears only after a user configures a link.
- **Config:** compatible named slots, save/load/delete/rename, selected-slot workflow, per-PlaceId autoload, legacy autoload, and versioned clipboard import/export. Import is bounded data, never Lua execution.
- **Player:** local WalkSpeed with Set/Multiply modes and a rebindable key; a themed, menu-controlled movement panel with saved drag/corner-resize geometry and size control. Disabling or replacing the character restores owned values. Server speed updates are not fought in a loop.
- **World:** Fullbright, No Fog (including late Atmosphere), No Shadows, selected time, Freecam and Reset Camera. Owned properties restore without overwriting subsequent game changes. Freecam uses RMB + WASD / Q E, owns its camera/input state and releases it on disable, character/camera replacement or unload.
- **Visuals:** native GUI overlays for **clear-line, visibly headed players only**. Boxes/corners/none, health, names, distance, skeleton, head dot, Occluded chams, tracers, clear-line off-screen arrows, team/friend filtering, palettes/hex colors and a responsive native mannequin preview. Fully hidden players are suppressed. Behind Wall color and hidden-target demonstration are preview-only.
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

CFrame speed/correction fallback, noclip, fly (including its key/modes/speed), Triggerbot/aim automation and automated PvP attacks are unavailable because no game-authorized mechanic is established and the task excludes bypasses. Through-wall chams/drawing and live dim-behind-wall behavior are excluded; highlights use **Occluded** depth and hidden players are not drawn. A separate Mobile Renderer toggle is unnecessary because the implementation already uses native GUI rendering.

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
