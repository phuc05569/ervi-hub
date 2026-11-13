> **Current 3.1 handoff:** See [LOCAL_CODEX_HANDOFF](docs/LOCAL_CODEX_HANDOFF.md). Build **3.1.0+5e9595329868**, 144 unit tests / 476 smoke checks passing. The material below records 3.0 and is historical: 3.1 removes Freecam/Friends/Sounds/Triggerbot, reorganizes navigation, defaults speed to Multiply, adds the logo/status pill, fixes search/key capture, and returns Safe Zone to its activation origin on explicit OFF.

# Ervi Hub — handoff for Codex (2026-11-13)

Client-side GUI hub for the Roblox game **RNG RollAttacks** (place `119338513416973`, universe `10768634654`), run by the owner through the **Potassium** executor on Windows 11. The owner is a beginner at scripting. Keep the steps you ask them to do short and exact (for example "paste X, press Run, roll 3 times, press Copy report").

Current cloud build: **3.0.0+e31b35baa4a4**, `build/Ervi_Hub.luau`, sha256 `f89dc4a883316313cc21499fa844c1be7b9bfc7d339cf0a737cef1e0c9a0f3b1`.

**3.0 continuation:** Read [reports/CONTINUATION_3_0_0.md](reports/CONTINUATION_3_0_0.md), [reports/UI_FEATURE_CHECKLIST.md](reports/UI_FEATURE_CHECKLIST.md), AGENTS.md and the rewritten README first. Original Bloom/rose UI, 12 main tabs plus retained Ervi tools, shared catalog/search, expanded Home/Config, local speed/movement panel, lighting/freecam, visible-only native overlays/preview, session actions and supported FPS-cap management are implemented. Existing Auto Roll/M1/Safe Zone/settings/session safeguards remain. Forbidden/unsupported reference operations are disabled/documented, not fake active controls. Totals: 127 unit / 423 smoke checks. No live rendering/game validation or Windows deployment occurred.

New source modules: BootLog, FeatureSchema, Registry, Locale, PropertyOverrides, VisualPolicy, World, PlayerTools, RuntimeActions, Visuals, VisualPreview, Expansion. Shared controls remain in Ui; all real controls register for search. Config import is data-only schema v1, bounded to 64 KiB; legacy named/plain configs remain compatible. Per-game autoload lives in autoloadGames. Default window 880×580; legacy geometry is retained.

The owner authorized pushing updates to the existing GitHub repository. Version 2.5.0 was pushed in commit `1374017`; use the current remote/ref for newer commits. Visibility must remain unchanged. Windows-installed copies and current repository visibility are unverified. Earlier private-repository claims are historical. Raw branch URLs have served cached old builds; verify an immutable commit URL after pushing.

## 1. Where things are

| What | Where |
|---|---|
| Source modules | `src/*.luau` (edit these, never the bundle) |
| Built single-file script | `build/Ervi_Hub.luau` (+ `.map.json` mapping bundle lines to modules) |
| Unit tests | `tests/*.spec.luau`, runner `tests/run.luau` |
| Headless smoke test | `tests/smoke/MockEngine.luau`, `tests/smoke/driver.luau`, `tests/smoke/gen_rbx_api.py` |
| Original user-verified script | `baseline/baseline_v1_original.luau` (Modular Hub v1, Cyborg V6), sha256 `584c4f5b…fb4aa` |
| Audit + evidence ledger | `reports/AUDIT_AND_EVIDENCE.md` |
| History | `CHANGELOG.md` |
| Installed copies on the owner's PC | `%LOCALAPPDATA%\Potassium\scripts\Ervi_Hub.luau` and `%LOCALAPPDATA%\Potassium\workspace\Ervi_Hub.luau` |
| Owner's one-line loader (local file, not a URL) | `loadstring(readfile("Ervi_Hub.luau"))()` |
| In-game settings file | `RNG_Hub_settings.txt` in Potassium's workspace (name kept for compatibility) |
| Auto-execute flag file | `Ervi_Hub_autoexec.txt` in Potassium's workspace (`on`/`off`) |

The autoexec folder `%LOCALAPPDATA%\Potassium\autoexec` is intentionally **empty**: the owner asked that nothing be placed there.

Earlier, unrelated work lives in `Documents/Codex/2026-11-13/files-pasted-by-the-user-rng/`. That includes decompiled client modules from place version 969 and older hub candidates v2–v5. Treat it as untrusted evidence and never execute it. The two failed "Auto Roll" builds from before this project must not be used as a base.

## 2. Build and test

Tools are not committed (`tools/` is gitignored). Re-download them:
- **Luau 0.746:** `github.com/luau-lang/luau/releases/download/0.746/luau-windows.zip`, sha256 `e149fdb4fe78a52ce457fbd40741484eaab1dbf9907e7f878c6d8a9a3dac2ddd`. Extract to `tools/luau/`.
- **Roblox API dump:** `https://setup.rbxcdn.com/versionQTStudio` gives the version; then fetch `https://setup.rbxcdn.com/<version>-API-Dump.json` into `tools/rbxapi/`.

```bash
python build.py                                    # build/Ervi_Hub.luau (deterministic: same source = same bytes)
python build.py --test && tools/luau/luau.exe build/tests.luau
python -I tests/smoke/gen_rbx_api.py tools/rbxapi/API-Dump.json build/rbx_api.luau
python build.py --smoke && tools/luau/luau.exe build/smoke.luau
tools/luau/luau-compile.exe --null build/Ervi_Hub.luau
```

Current results: **40/40 unit tests, 184/184 smoke checks**, the bundle compiles, and `luau-analyze` has only known noise. The mock engine rejects unknown members, unknown enums and writes to read-only properties, using the real API dump. It cannot show rendering, Potassium behaviour or real server replies.

Release steps: bump `VERSION` in `build.py`, rebuild, run all tests, and copy `build/Ervi_Hub.luau` to both Potassium paths above. Update `CHANGELOG.md` and `README.md`, then commit and push.

**Line endings:** `.gitattributes` forces LF, so the checksum stays stable.

## 3. Architecture

`build.py` concatenates the modules into one file. Inside the bundle, `require("Name")` loads a module; `require(Instance)` goes through to the real `require` (used only for the game's `ReplicatedStorage.AttackData`).

| Module | Role |
|---|---|
| `Scope` | Owns cleanup (connections, instances, threads, child scopes). Every feature lives in a scope; `hub:close()` disposes everything. |
| `Rarity` | Tier names and target matching (`Chance >= N`, or exact style names). Pure; unit-tested. |
| `AutoRoll` | Roll-until-target state machine (Checking → WaitingReady → Requesting → Confirming → Found/Paused/Idle). Pure; all game access goes through an injected adapter. 18 unit tests. |
| `RollAdapter` | Live adapter: the zero-argument roll request the game's own Roll button sends, only when the game itself would allow a roll. |
| `Game` | Nil-safe reads of client-visible state (attributes, AttackData, MainUI, remotes). |
| `Settings` | Named configs in one text file (`autoload=`, `[Name]` sections, validated `key=value`). Migrates 2.1.x files. Pure; unit-tested. |
| `Theme` | Design tokens, 6 designs, accents, fonts, text colors, custom `#hex` colors. `Theme.apply` changes the colors in place and returns an old→new color map. |
| `Ui` | Component kit: card, button, toggle, slider, grid, color wheel, drag. Also holds the appearance state (opacity, text size, transparency, outline) and `applyLook`, which repaints the UI. |
| `Cyborg` | Cyborg M1 overlay. Its detection logic is the user-verified V6 (own `Beam` under `HumanoidRootPart.SmearFX`, 0.5 s debounce, 6.07 s estimate). |
| `RollObserver` | Read-only roll diagnostic: 90 s, ring buffer, Copy report, excludes the username, UserId and JobId. |
| `Session` | Anti-AFK (VirtualUser on `Player.Idled`), auto-reconnect (rejoins only after connection or server errors, never after kicks, bans or security disconnects), auto-execute (`queue_on_teleport` loading the workspace file while the flag file is `on`). |
| `Prompts` | Instant proximity prompts. Sets HoldDuration to 0 on `PromptShown` / `PromptButtonHoldBegan`; restores the original hold times when turned off or when the hub closes. |
| `App` | Window, tabs (Dashboard, Auto Roll, Combat, Styles, Diagnostics, Session, Utility, Settings), configs UI, lifecycle. |

### Rules that break things if ignored

- **Register the stop handle first.** `_G.RNG_HUB_STOP` is registered at the very start of a run, before anything can pause. If it's registered later, pressing Run twice leaves an orphan copy running (seen live; a smoke test covers it).
- **Repainting matches colors by value.** Every token in a design must have a distinct color, different from the fixed status colors. `Theme.apply` nudges clashes by one RGB step; keep that.
- **Mark color previews as fixed.** Preview elements carry `FixedBackground` or `FixedTextColor` attributes so the repaint skips them. Fonts follow the `FontRole` attribute. Text size scales from the `BaseTextSize` attribute, so don't set `TextSize` after creating an element; pass it at creation instead.
- **Keep the 10 Hz refresh cheap.** It only updates the visible tab and uses `Ui.set`, which writes a property only when it changed. Don't add per-frame work.
- **Keep `AutoRoll` safe.** At most one request may be in flight, with no automatic retry. A qualifying result (normal, late, or after Stop) ends the run with zero further requests. Uncertain results pause instead of rolling again.

## 4. Evidence status

| Feature | Status |
|---|---|
| Cyborg V6 overlay (v1) | **USER-VERIFIED** |
| 2.1.0 loads in game; Auto Roll ran 31 rolls and paused on Cyborg (1/195) as designed | **LOCALLY OBSERVED** (Roblox F9 console, place version 969) |
| Configs, appearance, color wheel, resize grip, Session tab, Utility tab | Mock-tested only, **NOT LIVE TESTED** |
| Potassium support for `readfile`/`writefile`, `queue_on_teleport`, VirtualUser, and teleport after a disconnect | **UNKNOWN**. The Session and Settings tabs show the status of each. |
| Roll protocol and gating, tier table, `LoseAttackOnDeath` | **CONFIGURED** (from the game's client code, decompiled at place version 969) |

**Next permitted steps:**
1. Get the owner's Roll Observer report (Diagnostics → Start capture → 3 manual rolls → Copy report) to confirm the roll signals.
2. Do a live pass over each 2.x feature, using the checklist in `README.md`.

## 5. Automation notes

- **Potassium:** desktop automation can click inside it, but it **ignores synthetic keyboard input and mouse-wheel scrolling**, and its window drops behind Roblox when focus changes. Pressing Run, and opening files when the list needs scrolling, are left to the owner.
- **Stale tabs:** a Potassium tab keeps its text after its file is deleted. Overwriting an existing file does refresh its open tab. The owner once ran a stale 2.2.0 tab by mistake.
- **Reading game logs:** the Roblox developer console (F9) shows the hub's log lines (`[Ervi Hub] …`). It's the quickest way to see which build actually ran.
- **GitHub:** pushes used a portable official GitHub CLI (v2.104.0, checksum-verified) with a credential helper set only for this repo. The owner signed in themselves through the device flow. Never handle their password or codes.

## 6. Requests the owner made that Claude declined or did not finish

This is a record so nothing is lost. These items were deliberately **not** built, and this file gives no implementation guidance for them. Any agent continuing the project should apply its own policies and Roblox's Terms of Use.

| # | Request (owner's words, summarised) | Status | Reason given |
|---|---|---|---|
| 1 | "Auto Kill": target low-HP players | Declined | Automating PvP kills on real players |
| 2 | Teleport to low-HP players (later also asked as "so I can heal them") | Declined | Client-side teleport that gets around the game's movement rules, aimed at weakened players |
| 3 | Teleport back to a saved safe-zone position | Declined | Same teleport method; escaping fights through a movement-rule bypass |
| 4 | Low-health target tracker (players under an adjustable HP %, list, manual target selection) | Declined | The targeting part of the auto-kill request |
| 5 | Visual tab: player ESP with distance in studs | Declined | Wallhack in a PvP arena |
| 6 | Universal M1 cooldown for every fighting style | Not finished | A safety check stopped the analysis of the game's combat code; it was not resumed. The Cyborg-only V6 tracker remains. |
| 7 | Host the script on GitHub behind a public `loadstring(game:HttpGet(raw link))` loader "so people can't steal it" | Declined as asked | Public distribution of the hub; also, a public raw link exposes the full source. Done instead: a private repo plus the local loader `loadstring(readfile("Ervi_Hub.luau"))()`. |
| 8 | Sign in to GitHub for the owner | Not possible | Passwords and one-time codes stay with the account owner. Claude opened the page and the owner authorized. |

Built at the owner's request, with notes:
- **Auto Roll:** uses the game's own roll request at its normal cooldown.
- **Anti-AFK.**
- **Auto-reconnect:** limited to connection and server errors.
- **Instant proximity prompts:** a lighter version of the owner's pasted snippet.
- **Auto-execute:** first built as an autoexec-folder file. The owner then asked for it to be removed and turned into a menu toggle.
