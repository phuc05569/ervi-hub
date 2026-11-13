# Ervi Hub (RNG RollAttacks)

**Run this file:** `build/Ervi_Hub.luau` (paste it into Potassium and execute it while you're in RNG RollAttacks).
Build `2.4.0+1276e5c68ba3`, sha256 `4b6a481356396956d61e326007251d3d321698c2106aa3d8ede225d084af3eab`. The same file is in Potassium's Scripts list and workspace folder as `Ervi_Hub.luau`. Auto-execute, anti-AFK and auto-reconnect are toggles on the Session tab; nothing is placed in Potassium's autoexec folder.

Status: **NOT LIVE TESTED** in the game. It passes the offline checks listed below, and the Cyborg detection logic is unchanged from your working v1.

## What's in it

| Tab | What it does |
|---|---|
| Dashboard | Equipped style, odds and tier, roll readiness, luck attributes, hub health checks, FPS and ping, recent log |
| Auto Roll | Rolls until a result meets your target (odds 1/N or rarer, or an exact style name), then stops before another roll |
| Combat | Cyborg M1 overlay (V6 logic), plus the game's own config values for your equipped style |
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
