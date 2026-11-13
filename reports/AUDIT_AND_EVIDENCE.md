# Audit, evidence ledger and test record — 2026-11-13

## 1. Baseline

No Lua file was attached (only the two prompt files). The baseline was found at
`Documents/Codex/2026-11-13/files-pasted-by-the-user-rng/work/rng/baseline-v1.luau`: **"RNG RollAttacks | Modular Hub v1 — Feature 1: Cyborg M1 Cooldown (V6)"**, 467 lines.
Copied byte-for-byte to `baseline/baseline_v1_original.luau`, sha256 `584c4f5babfccf407487a8569eb8f4a7309a9029975e9fa5f5269d67227fb4aa` (identical to the source). The source file was not modified. Candidates v2–v5 Jan and the two failed Auto Roll builds were **not** used as code.

**v1 structure:** cleanup of `_G.RNG_HUB_STOP` / `RNG_CYBORG_V6_STOP` / `RNG_DIAG_V5_STOP` and old GUIs → `connect()` buckets → Cyborg overlay (`startM1`/`stopM1`) → 340×245 hub with an M1 toggle, two "Coming Soon" slots, minimize and X.

**User-proven:** the Cyborg V6 overlay (own `Beam` under `HumanoidRootPart.SmearFX`, 0.5 s debounce, 6.07 s estimate) and the hub X / overlay X behaviour.

**Defects found in v1 (all addressed in v2):**
| # | Defect | Impact | v2 |
|---|---|---|---|
| 1 | `workspace.DescendantAdded` listener for one effect | Fires for every VFX part from every player: wasted CPU in busy fights | Listens on the local HumanoidRootPart only; same match rules |
| 2 | `RenderStepped` rewrites every label each frame | Needless property writes even while idle | Heartbeat, writes only when text or value changes |
| 3 | Heartbeat poll to sync the hub button | Per-frame work for a state that changes on click | Event callback (`onChanged`) |
| 4 | `Frame.Draggable` | Deprecated API | Custom mouse/touch drag |
| 5 | Fixed pixel sizes | Small screens clip the window | Viewport-fitted UIScale + user scale |
| 6 | "Coming Soon" placeholder buttons | Unfinished look | Removed |

## 2. Evidence ledger

| Claim | Level | Source |
|---|---|---|
| Cyborg V6 overlay works | **USER-VERIFIED** | Baseline v1 report |
| v2 root-scoped Cyborg listener matches the same events | INFERRED + mock-tested | Same predicate. The smoke test fires an own and an other-player Beam. Not run in game |
| Roll = `Remotes.RollAttack:InvokeServer()` with **no arguments**, returning `(name, chance, ?, ?, fakeOutName)`; `nil` name = "TRY AGAIN" | CONFIGURED (client code) | UIController `doRoll`, Potassium decompile at placeVersion 969 (untrusted reconstruction) |
| Client-side roll gate: alive, `InFFA`, `RollReadyAt - GetServerTimeNow() <= 0.05` | CONFIGURED | UIController line 557 |
| Game asks "You will lose X" when equipped Chance > 125 | CONFIGURED | UIController `doRoll` |
| Server enforces the cooldown independently | UNKNOWN | Server code is not visible; never probed |
| Tiers: ≤3 Common, ≤5 Uncommon, ≤8 Rare, ≤12 Epic, else Legendary; `RarityName` overrides need `RarityColor` | CONFIGURED | AttackData `Tier()` |
| Larger Chance = rarer, so "1/500 or better" = `Chance >= 500` | CONFIGURED | `Tier()` ordering, "1 in N" panel text |
| Displayed 1/N values are not final probabilities (21 named fractions sum to 113%) | LOCALLY OBSERVED | Prior live scans (place v946). No probability calculator was built |
| `RollCooldown = 8`, `MinRollCooldown = 3.5`, `LoseAttackOnDeath = true` | CONFIGURED | AttackData |
| Cyborg configured `Cooldown = 6`, observed effect interval ≈ 6.07 s | CONFIGURED / USER-OBSERVED | AttackData; v1 diagnostic |
| `RollReadyAt` advances on every accepted roll | INFERRED | The game's cooldown display reads it. **The roll observer report will confirm** |
| `UnlockedAttacks` format (JSON or comma list) | INFERRED | Parser tries both |
| Live place version still matches 969 data | UNKNOWN | Dashboard shows live vs 969 |
| Teleport near target is allowed | **BLOCKED** | The game offers no player teleport. A client-side CFrame jump would bypass movement rules, so it won't be built |

## 3. Auto Roll design

States: `Idle → Checking → WaitingReady → Requesting → Confirming → (loop) | Found | Paused`.
Guarantees (unit-tested): one request in flight, no automatic retry, current style checked before the first roll, a qualifying result (normal, late, or after Stop) ends the run with zero further requests, timeouts and empty or uncertain results pause, a roll cap applies, double start is rejected, and hub close disposes listeners and late watchers.
Known limitation: hub-initiated rolls skip the game's roll animation. The result appears on the game's Roll button label (from `EquippedAttack`) and in the hub.

## 4. Tests run (all on this PC, offline)

| Gate | Tool | Result |
|---|---|---|
| Baseline backup + hash | sha256sum | Match |
| Toolchain integrity | Luau 0.746 official release zip, sha256 `e149fdb4…2ddd` (matches the recorded value) | OK |
| Luau parse/compile of the release bundle | `luau-compile --null` | OK, 2,184 lines |
| Static analysis | `luau-analyze` | No real issues. Remaining notes are Roblox globals unknown to the CLI and two type-inference false positives on `string.format` |
| Unit tests (AutoRoll 18, Rarity 5, Scope 5) | `luau.exe build/tests.luau` | **28/28 pass** |
| Headless GUI and lifecycle smoke test | Real bundle in a mock engine validated against the Roblox API dump `version-d0e8cfcd943d4ae2` (unknown members, unknown enums and read-only writes all error) | **62/62 pass**: all tabs, Auto Roll end to end, rare-style pause and Continue, Stop, death gate, Cyborg own vs other beam, READY timing, overlay X, diagnostics capture, copy and username redaction, minimize, RightShift, X cleanup with 0 leaked connections and threads, rerun idempotence |
| Mutation checks | 7 injected bugs | 6 caught. The 7th ("no return after Found") is harmless because a second guard already stops the loop |
| Determinism | Rebuild | Identical sha256 |
| Live game / Potassium | — | **NOT LIVE TESTED.** No Roblox Studio instance was connected, and this session can't drive the Roblox client |

What the mock cannot prove: real rendering and layout, Potassium specifics (its `require` of game modules, clipboard, PlayerGui parenting), real server replies, and timing under network lag.

## 5. Feature opportunity matrix (next phases)

| Feature | Value | Evidence | Feasibility / dependency | Policy | Cost | Status |
|---|---|---|---|---|---|---|
| Low-HP target list (HP threshold, nearest or lowest, manual pick) | High | Humanoid health replicates to clients | Client-only read | OK as information; no auto-attack, no teleport | Low at 4 Hz | Phase 3 |
| Teleport near target | — | — | Would bypass movement | **Not built** | — | Blocked |
| Per-style M1 timers for more styles (effect proxies like Cyborg) | High | AttackData cooldowns + per-style VFX names | Needs one short capture per style | OK | Low | Needs data |
| Roll statistics (results per tier per session) | Medium | Auto Roll history, observer | Easy | OK | None | Ready |
| Ability timers from `AbilityReadyAt` / `Ability2ReadyAt` | High | Attributes seen in prior scans | Needs live confirmation of the time base | OK | Low | Needs observer data |
| Settings persistence | Low | `writefile` availability unknown | Executor-dependent | OK | None | After capability report |
| Style comparison (damage, cooldown, range) | Medium | AttackData | Easy | OK | None | Ready |
