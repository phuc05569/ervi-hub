# Ervi Hub (RNG RollAttacks)

**Run this file:** `build/Ervi_Hub.luau` (paste it into Potassium and execute it while you're in RNG RollAttacks).
Build `2.6.0+d4bd70143994`, sha256 `d30cc337d164f382504e4c50b6194792aabdd1ce626120e07f6cb0620cab22b5`. This cloud build has **not** been copied to the Windows Potassium installation. Auto-execute, anti-AFK and auto-reconnect are toggles on the Session tab; nothing is placed in Potassium's autoexec folder.

Status: **NOT LIVE TESTED** in the game. It passes the offline checks listed below, and the M1 timing remains based on a candidate client-visible attribute.

## What's in it

| Tab | What it does |
|---|---|
| Dashboard | Equipped style, odds and tier, roll readiness, luck attributes, hub health checks, FPS and ping, recent log |
| Auto Roll | Rolls until a result meets your target (odds 1/N or rarer, or an exact style name), then stops before another roll |
| Combat | One resizable M1 HUD, current health, equipped-style config, low-health target selection for manual combat |
| Safe Zone | Save/replace/clear a place-specific position and orientation reference; F6 opens its coordinates and distance |
| Styles | Searchable list of every style from the game's data: odds, tier, cooldown, owned |
| Diagnostics | Read-only roll observer (90 s max), environment snapshot, hub log, Copy buttons |
| Settings | Show/hide key (rebindable), menu opacity slider, window size, reset settings and position, emergency unload |

Controls: drag the title bar to move the window. `–` minimizes it, the show/hide key (**RightShift** by default, changeable in Settings) hides or shows it, and `×` unloads everything. From the console, `_G.RNG_HUB_STOP()` does the same. Settings are saved to `RNG_Hub_settings.txt` in Potassium's workspace folder when file access is available.

## Your first test (about 2 minutes)

1. Run the hub. **Dashboard → Hub health** should show `found` or a style count on every line. If any line says `missing`, tell me which one.
2. **Diagnostics → Start capture.** Roll **manually 3 times** with the game's Roll button, waiting for each result.
3. Press **Copy report** and paste the text into the chat. If Copy fails, click inside the report box, press Ctrl+A, then Ctrl+C.

That report confirms the roll signals Auto Roll depends on: `RollReadyAt`, `EquippedAttack` and the reveal panel text.

**Optional Auto Roll test** (only if you're holding a common style you don't mind losing). Go to Auto Roll, enter Custom N = `20`, and press Start. It should stop on the first result that is 1/20 or rarer and say why it stopped. Press Copy log under Diagnostics and send that too.

## Rolling rules the hub follows

- It sends the same no-argument roll request the game's Roll button sends. It only does that when the game itself would allow a roll: you're alive, you're in the arena (`InFFA`), the cooldown is finished, and no game roll animation or confirm dialog is open.
- There is never more than one request in flight, and it never retries. A timeout, an empty result or a cooldown that doesn't restart all pause the run instead of rolling again.
- It checks your current style first and won't roll it away if it already meets the target. If it's rarer than 1/125 (the game's own "You will lose X" warning), it waits for you to press **Continue**.
- The game is configured with `LoseAttackOnDeath = true`, so dying after a good roll can still lose it. That's the game's rule, not the hub's.

## For developers

```bash
python build.py
```
```bash
python build.py --test && tools/luau/luau.exe build/tests.luau
```
```bash
python -I tests/smoke/gen_rbx_api.py tools/rbxapi/API-Dump.json build/rbx_api.luau && python build.py --smoke && tools/luau/luau.exe build/smoke.luau
```

- Source lives in `src/*.luau`. `build.py` concatenates it into the single bundle and writes a `.map.json` that maps bundle lines back to modules.
- Restore the original: `baseline/baseline_v1_original.luau` (sha256 `584c4f5b…fb4aa`) is a byte-for-byte copy of Modular Hub v1. Run that file to go back.

Details: [reports/AUDIT_AND_EVIDENCE.md](reports/AUDIT_AND_EVIDENCE.md), [CHANGELOG.md](CHANGELOG.md).


## 2.6.0 controls and behavior

- **Combat → Show M1 cooldown HUD** controls the only M1 HUD. There is no standalone Cyborg HUD or Close button. Drag its title and resize from the bottom-right corner. Its enabled state, normalized screen position and dimensions save in the active config; Reset M1 HUD layout restores defaults. Long content scrolls and the title truncates rather than overlapping. Layout adapts when the viewport changes.
- **Settings → Menu opacity** accepts 0–100% background opacity; text remains readable. Existing theme, font, text and config controls remain available.
- **Safe Zone → Set Current Position as Safe Zone** captures your current character CFrame, including orientation. Coordinates persist per PlaceId and can be replaced or cleared. This is a reference, not a server-protected zone.
- **F6** opens Safe Zone and refreshes its coordinates/distance. Rebind in Settings. It never moves your character, ignores text-field input, and cannot share the menu toggle key. Persisted conflicts are repaired on load.
- **Combat → Auto Kill · manual combat → Enable target selection** observes replicated health at 4 Hz and selects a player strictly below the HP threshold (slider or numeric input). It requires a saved reference and a living local character. You approach, attack and return manually. Dead, missing, departed or no-longer-eligible targets are cleared. An eligible target remains stable rather than switching every refresh. No world overlays are drawn.
- **Auto M1 (request only)** records your preference. OFF means manual attacks and skills. ON explicitly reports unsupported and sends no attacks. No authorized movement, holding/floating, return or automated-M1 API is established in the available evidence; no character CFrame/physics writes or invented remotes are used.
- **Auto Roll → Resume Auto Roll After Death** persists your choice. ON keeps the existing worker waiting through death, then checks normal character/arena/cooldown readiness. OFF pauses for manual continuation. It retains the rarity/style target, rechecks equipped styles after waiting, and never treats respawn as a roll result. Uncertain or failed in-flight requests still pause without retry; enabling recovery does not bypass that safeguard.

The M1 HUD still labels the `AttackReadyAt` server-clock interpretation **UNVERIFIED** and displays UNKNOWN without usable evidence. Removal of the Cyborg fallback does not establish live universal support.

Version 2.6.0 validation: **99 unit tests and 245 smoke checks pass**, both artifacts compile, and repeat builds match. The original baseline remains in `baseline/`. See [the current continuation report](reports/CONTINUATION_2_6_0.md). Windows/Potassium copies remain unverified; cloud tests are not live Roblox validation.

## Historical 2.5.0 cooldown evidence and loader (superseded by 2.6.0)

Combat → **Show M1 cooldown HUD** displays the style and a candidate remaining timer from the local player's `AttackReadyAt`, interpreted against `workspace:GetServerTimeNow()`. Its note explicitly marks that interpretation **UNVERIFIED**. This is an all-style implementation, **not evidence of universal live support**. It requires the matching style Tool in the current character. Missing/invalid attributes show UNKNOWN; missing Tools show UNEQUIPPED; death shows UNAVAILABLE. Style changes, re-equipping and respawns wait for a fresh attribute change, preventing an old READY result from carrying over. Positive samples outside a ±120-second window are rejected as a possible clock mismatch. Configured cooldowns and Tool activation never substitute for an observed attack deadline.

The Cyborg V6 overlay remains separate and unchanged. Its 6.07-second timer is an effect-based **estimate**. The new HUD does not silently combine the two sources. Use Diagnostics → Start capture while manually attacking with two styles, then Copy report to validate the player attribute's meaning and clock. Character/Tool attributes are not currently interpreted as cooldowns.

`python3 build.py` also emits `build/loader.lua` from `src/Loader.luau` and `loader.json`. The default URL is blank, so the template makes no requests. The local loader still works unchanged:

```lua
loadstring(readfile("Ervi_Hub.luau"))()
```

Preferred future distribution: keep development private and publish approved release artifacts in a separate public repository. **No repository or public release has been created, pushed, or published by this change.** After explicit publication approval and a secret/history review, set `loader.json`'s URL to an HTTPS `raw.githubusercontent.com/<owner>/<distribution-repo>/<full-40-character-commit>/Ervi_Hub.luau` URL and rebuild. Do not use a private-repository token in a loader. The template checks PlaceId, release banner and a 2 MiB size limit; it retries downloads three times at most, compiles/executes only once, guards duplicate/concurrent loads, returns the unload handle and cleans up a failed startup. Existing instances remain until download/compilation succeeds. A new version or URL triggers a fresh load. The banner is not a cryptographic signature; trust depends on GitHub HTTPS and the pinned commit. No cache or network-based teleport loader is installed; existing local-file teleport behavior remains.

Linux cloud checks (use `.exe` paths from the earlier examples on Windows):

```bash
python3 build.py --test && tools/luau/luau build/tests.luau
python3 -I tests/smoke/gen_rbx_api.py tools/rbxapi/API-Dump.json build/rbx_api.luau
python3 build.py --smoke && tools/luau/luau build/smoke.luau
tools/luau/luau-compile --null build/Ervi_Hub.luau
tools/luau/luau-compile --null build/loader.lua
```

Current results: **68 unit tests, 210 smoke checks**, both bundles compile. Smoke tests intentionally verify that the distribution template remains unconfigured. See [the continuation report](reports/CONTINUATION_2_5_0.md) for evidence, tool limitations and pending deployment.
