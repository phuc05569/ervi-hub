## Current manual-feedback candidate — 3.5.0-dev+cf9fd777b960

**IMPLEMENTED — OWNER TESTING PENDING.** Continues local checkpoint `0443e7b`; no unit/smoke/compile/Studio/Potassium/live testing, benchmark, deployment, push or publication. Normal `python build.py` generation only. Earlier evidence below is historical.

Owner reports B's two-second anchor delayed server-observed movement until release. This report is not an independently reproduced server trace. The anchor implementation is removed, not extended.

| Change | Implementation / remaining boundary |
|---|---|
| Zone B | Existing transport first move → ~0.1s settle after local arrival → separate bounded-force one-second physics hover → release → one final move, after the first result is known. No root anchoring, movement retry loop, network-ownership edits or server guarantee |
| User Fly independence | LocalFlight/Flight suspend and resume physical controllers without changing desired settings/key modes; current user changes while suspended win. Death/unload keep existing cleanup policy |
| Auto Roll Safe Zone | Toggle directly below Run buttons, separate from Auto Roll. Captures one original return point; enters A and hovers without anchoring. OFF cleans up then requests one finite/place/death-height-validated return; invalid/dead/emergency returns are suppressed |
| A respawn/emergency | Logical toggle/original origin survive respawn. Ready living root re-enters A once; emergency B suspends A until health clears and B sequence finishes. Manual B holds A suspended until B OFF. External correction suspends without looping; explicit Click TP suspends A without returning or losing its origin |
| Notifications | Independent per-entry hard deadline removes the frame/scope; optional fade no longer owns removal. Reflow skips expiring entries. Max three, bottom-right, minimized-menu independence and one-second default retained |
| ESP colors | Shared existing Chams relation palette drives skeleton cores and Head Dot, including friend colors/factory-white behavior; preview matches. Black underlays, text defaults and separate tracers preserved |
| Transformed avatar ESP | Cached nested Character geometry/root/body bounds replace mandatory visible Head gating. Missing health hides the bar. Real Motor6D links support nested/custom rigs; no invented skeleton for mesh-only bodies. Cached parts ≤96, links ≤32; existing target/rate/ray/visibility budgets remain |
| Auto Kill | Explicitly UNSUPPORTED / deferred in UI; no attacks investigated, implemented or sent |

Preserved working-owner reports for Click TP, emergency B and WalkSpeed; speed default remains 50 Set/NONE. Existing settings/destinations/backups/release stay untouched. Source files: SafeZone, new ZoneHover, Flight/LocalFlight, MovementTransport, App/Expansion/LocationControls, Ui, new AvatarGeometry, RigSkeleton, Visuals/VisualPreview, plus build.py. Existing reports/task ledger and generated bundle/map/loader updated; no test suites changed.

Limitations: native hover/MoveTo do not establish target-game server acceptance, protection or A rollability. B's last move is withheld after uncertainty/correction. Physics correction >16 studs cancels stabilization. Original-return surface availability is still subject to normal transport/game behavior. Transformed models must be within the associated replicated Player.Character; detached proxies and Bone-only mesh skeletons are not guessed. The previous automated evidence/catalog does not validate this build.

Pre-edit preservation: `C:\Users\ASUS\ervi-manual-feedback-20261114-075732` (all-ref checkpoint bundle and source/build/docs/evidence). Owner tests all new behavior.

### Earlier checkpoint notes follow

---

## Owner-testing continuation — 14 November 2026

Current candidate: **3.5.0-dev+6abfd1dd3905**. All changes below are **IMPLEMENTED — OWNER TESTING PENDING**. This section supersedes the previous candidate's feature status. No tests, compile checks, benchmarks, Roblox/Studio/Potassium input, deployment, push or publication were performed in this continuation. Only the normal build command is authorized. Old automated results are historical and do not validate this build.

Owner-reported results before these changes: Click TP works; emergency teleport works very well; B is protected/unrollable; WalkSpeed works; A teleports but remains unrollable. These are owner reports, not new agent observations.

- A: replaced persistent anchored PivotTo path with the shared one-attempt movement transport used by Click TP/B. No A stabilization. Explicit OFF retains one observed origin-return attempt; unload/death/correction do not move back. Game readiness is never forced.
- B: two-second arrival hold clears residual linear/angular velocity, restores its owned anchor state, and releases automatically. One lock at a time; calm rearm permits a new fling-edge hold near B. Leaving B, external correction/unanchoring, other movement, death, character replacement and unload cancel it. No return/correction-fighting loop. A fling already carrying the character beyond 12 studs is released rather than teleported back.
- Auto Roll: known arena/cooldown/reveal/confirm gates wait without the old 180-second terminal timeout, retaining target/session. Missing arena metadata remains an error gate. Preflight refusal sends no roll and is distinct from an uncertain server reply; Stop/Found, one request in flight, timeout/uncertain pause and death preference remain.
- Removed XYZ/capture/save/reset controls and the entire Saved Positions interface/worker code. Codec and legacy savedPositions persistence remain to avoid deleting existing data. Both established destinations are available internally with stored overrides and PlaceId validation.
- Fresh WalkSpeed default: 50, Set, NONE. Explicit saved values/modes/keys are retained.
- Added feature keybind notifications for WalkSpeed/Fly/Noclip/Safe Zone, including Hold release; ESP retains its existing toggle notice path. Notification settings/duration/minimized-menu independence remain.
- Fly/Noclip Toggle state survives focus loss; Fly sends neutral input while unfocused and resumes input on return. Hold bindings still release on focus loss. Safe Zone stabilization and flight/noclip release each other before activation; Click TP releases an active zone before a valid move.
- ESP avatar/visibility/update budgets, colors/backgrounds/shared keys, M1 and the UI design are preserved. Auto Kill remains deferred.

Zone coordinates recovered read-only from the current active DEFAULT profile: A `(350.647675, -435.796021, 26.535965)`; B `(296.613495, 59.0999985, -100.878853)`; place `119338513416973`. These replace the old fallback only; stored overrides still win. No settings file or backup was edited. A's negative-Y destination is preserved as requested; removing its hold does not prove the game will set InFFA there. Rollability requires owner confirmation; no guessed coordinate fallback or attribute spoofing was added.

Preservation before edits: `C:\Users\ASUS\ervi-owner-continuation-20261114-071700` (all-ref bundle, source/build/reports/tasks/docs and read-only current-settings snapshot). Existing local commits and evidence remain.

Owner acceptance still needed for all new behavior: A rolling/readiness, A/B transitions, the two-second hold/fling edges and cleanup, indefinite unavailable-roll waiting/resumption, GUI removals, new-config defaults, keybind ON/OFF notices and unfocused Fly. No agent-run testing is scheduled.

### Historical prior checkpoint follows

---

# Complete functional audit — 14 November 2026

## Outcome and development identification

Functional development candidate: **3.5.0-dev+b391196c1bb3** on **dev/functional-audit-3.4**, based on published v3.4.0 / `2b93389`. Updated script: `C:\Users\ASUS\ervi-hub\build\Ervi_Hub.luau`.

SHA-256: `bd93a2e1bb8f3a47efb219d6356858b02504b2e85268d5df8d9814b664e7bf1f`.

Implemented native Click TP, configurable A/B destinations, one-event emergency teleport, avatar ESP, corrected WalkSpeed, native Fly/Noclip lifecycle, named position tools, shared keyboard modes, Visibility Mode migration/removals, functional color picking, background inputs and viewport notifications. The existing UI design remains.

The target-game acceptance gate is still open. No new development build was loaded into Potassium, installed, pushed or released. Do not confuse the native Studio fixture with RNG RollAttacks.

## Feature inventory and classification

"Live" below explicitly means the owned unpublished Studio fixture unless a historical target-game result is identified. Automated headless results execute real emitted hub code against the repository's mock engine.

| Navigation / feature | Current classification | Evidence and remaining limit |
|---|---|---|
| Home identity, native/bundled logo/icons, game/server labels, active chips | WORKING — HEADLESS VERIFIED ONLY for this candidate | Existing render/search/single-instance suite retained; native Home screenshot on intermediate candidate. No design rewrite |
| Auto Roll stop target/custom N | WORKING — HEADLESS VERIFIED ONLY for current candidate | One in flight, terminal result stops, uncertain reply never retried; historical target-game results remain historical |
| Auto Roll death recovery | WORKING — HEADLESS VERIFIED ONLY | Existing gates/lifecycle suite preserved; does not silently activate Zone A |
| Styles, equipped style, AttackData | WORKING — HEADLESS VERIFIED ONLY | Client-visible reads retained; no new per-style combat test |
| Universal M1 HUD, adaptive text/bar | PARTIALLY WORKING | Lifecycle/layout/state tests preserved; AttackReadyAt's universal clock/cooldown meaning remains UNVERIFIED; old Cyborg result is historical, not universal proof |
| Low-health player selection | WORKING — HEADLESS VERIFIED ONLY | Existing TargetState/Targets health, leave/death/selection coverage retained; no automatic attacks or other-player teleport |
| Auto Kill / Auto M1 | UNSUPPORTED | No established normal attack adapter or independent damage result; request-only preference remains labeled unsupported. See COMBAT_FEASIBILITY |
| ESP box/corners/none, names, distance, skeleton, head dot, tracers, colors, chams state | WORKING — HEADLESS VERIFIED ONLY for complete option matrix; PARTIALLY WORKING live acceptance | Native outlined skeleton/text/health/avatar screenshots on owned dummies; actual target-game/rendering at all options not retested |
| Icon ESP | WORKING — LIVE VERIFIED in Studio | Correct native headshot IDs loaded for two owned fixture identities; cached URLs, circular GUI, fallback, target budgets; final event-based readiness also smoke-tested |
| Visibility Mode | WORKING — LIVE VERIFIED in Studio | On hides both wall-occluded fixtures (2 rays); off shows both (0 rays), including icons. Exact legacy inversion and explicit-key precedence tested |
| Health colors/outlines | WORKING — LIVE VERIFIED in Studio | Bright green/red, dark track underlays; >50% green, <=50% red. Configurable colors persist |
| Friend marking and color | WORKING — HEADLESS VERIFIED ONLY | Cached friend checks retained; team and obsolete hidden-preview controls removed from catalog/search |
| ESP update budgets | WORKING — HEADLESS VERIFIED ONLY plus measured Studio sampling | Auto → 60; 10/20/30/60 preserved. Short intermediate measurement ~56–57 presentations/s at Auto/60; no locked-60 or 120/144Hz claim |
| WalkSpeed Set/Multiply | WORKING — LIVE VERIFIED in Studio | 16/25/50/100, Multiply baseline, external change releases override and desired state. Requested property is distinct from observed velocity |
| Movement floating panel | WORKING — HEADLESS VERIFIED ONLY | Correct mode/slider visibility, scoped resize/position and persistence. Final physical resize not retested |
| Fly | PARTIALLY WORKING | Native constraints, camera-relative input, observed movement and cleanup verified in Studio; default F works via real input on owned-server controller. RNG replication/acceptance unverified |
| Noclip | PARTIALLY WORKING | Native flags, cached PreSimulation maintenance, original true/false restoration, death/disable/unload tested. Passage through server geometry and target replication unverified |
| Player Tracker filter/sort/select | WORKING — HEADLESS VERIFIED ONLY | Existing cached model, player events, sort/filter/selection and row removal tests retained |
| Tracker teleport action | UNSUPPORTED | Existing disabled player-teleport action remains; no teleport to other players is added |
| World lighting/time/fog/shadows, Reset Camera, optional background blur | WORKING — HEADLESS VERIFIED ONLY | Existing ownership/restoration and camera replacement coverage retained; no new permanent render loop |
| Click TP | PARTIALLY WORKING | Actual Ctrl + M1, local observation, later independent Studio server position, GUI/sky suppression, release/cleanup; target-game gate not passed |
| Zone A | PARTIALLY WORKING | Configurable, historical preset retained for correct place; scoped hold and origin return suite passes. Rolling at that location is not newly verified |
| Zone B configuration/movement | PARTIALLY WORKING | Configuration/persistence and native/server-fixture movement tested. Correct target-game coordinates/protection not supplied or verified |
| Automatic local low-health teleport | PARTIALLY WORKING | Default 30%, 0–100, once per recovery event; MaxHealth/threshold/root-loading/already-there cases tested. Native fixture success; real B protection unverified |
| Position save/copy/rename/delete | WORKING — HEADLESS VERIFIED ONLY | Bounded data, PlaceId, named entries, expression clipboard/fallback. No saved-position teleport added |
| GUI toggle, recenter, drag/search/inputs/dropdowns/sliders | WORKING — HEADLESS VERIFIED ONLY for full regression matrix | Native Studio navigation/search/icon toggle, explicit RightShift down/up and centered reopening verified. Complete physical resize/drag/numeric/rebind regression remains incomplete |
| Key modes | WORKING — HEADLESS VERIFIED ONLY for complete mode matrix | Central Toggle/Hold/Always/NONE, key release/focus loss/rebind. Native RightShift and F on/off evidence retained |
| Menu/font/outline/opacity/design settings | WORKING — HEADLESS VERIFIED ONLY | Existing look preserved; named explicit preferences retained; background presets added. No visual redesign |
| HSV color picker and swatches | WORKING — HEADLESS VERIFIED ONLY | Existing HSV wheel reused lazily for all catalog colors; brightness/hex/persistence, fixed swatch press/release and selected state tested; final circular presentation belongs to Claude |
| Background image | PARTIALLY WORKING | Validated Roblox asset inputs, load success/failure/timeout and native fallback implemented; arbitrary HTTPS/local-asset downloading not supported. Actual chosen background asset still needs live acceptance |
| Notifications | WORKING — LIVE VERIFIED in Studio for viewport lifetime | Independent bottom-right ScreenGui, default 1s expiry and cleanup observed; max-three queue, disabling immediately clears, theme root and unload smoke-tested |
| Anti AFK | WORKING — HEADLESS VERIFIED ONLY | Existing Idled/VirtualUser compatibility handling preserved; no real idle-duration test this session |
| Auto reconnect | PARTIALLY WORKING / capability dependent | Existing permitted disconnect handling retained; real disconnect/rejoin not induced |
| Auto execute | PARTIALLY WORKING / capability dependent | Existing queue-on-teleport flag support retained; no fresh-process autoexec-folder mechanism added, no directory changes |
| Instant prompts | PARTIALLY WORKING | Local hold-time ownership/restoration covered; target-game server prompt acceptance not retested |
| Rejoin / Server Hop / Copy Job / FPS Cap | WORKING — HEADLESS VERIFIED ONLY; capability dependent where indicated | Existing bounded actions and reversible FPS-cap tests preserved; no live rejoin/server hop/cap change performed |
| Diagnostics, boot logs, bounded export | WORKING — HEADLESS VERIFIED ONLY | Existing export/search instrumentation retained; temporary QA runs only in fixture, not bundled runtime |
| Settings profiles/autoload/autosave | WORKING — HEADLESS VERIFIED ONLY for this candidate | Existing format, profiles and protected backup retained; new keys serialize/migrate. Config page remains removed |
| Panic/unload, early stop signal, cross-context singleton | WORKING — HEADLESS VERIFIED ONLY plus native scoped cleanup | Existing duplicate-context tests retained; final active native movement unload removes owned forces/properties. Native functional scopes clean up |
| Removed teams/hidden preview/Config page | NOT APPLICABLE | Removed intentionally; obsolete keys ignored, controls absent from search. Friend functionality preserved |

## Validation and important defects

Current automated suites: **181 unit / 602 smoke checks, zero failures**. Both Luau artifacts compile. Deterministic build verification and exact hashes are in `evidence/functional-3.4/validation.json` once the final verification command finishes.

Final owned Studio controller suite: **20 checks passed** on `3.5.0-dev+b391196c1bb3`, with native constraint and notification cleanup true. See `studio-functional-release-candidate.json`. Earlier 18-check files and intermediate benchmark/screenshots are retained with their original build identity; they are not relabeled as final-bundle tests.

One earlier run of this same final candidate detected a post-flight/startup correction and failed its local-success assertion. The failed trace is retained in `studio-final-correction-detected.json`; an isolated move and a later traced 20-check run succeeded without changing the movement code. The cause remains unestablished, so reliability across every transition is not claimed. The observer stopped and did not retry the corrected movement.

Actual defects fixed: preview-only Click TP gating; stale click destination risk; concurrent movement requests; root-coordinate vs ground-coordinate mismatch and 503-vs-500 range in the owned protocol; B acknowledgement being inferred from text; emergency triggering without a root or repeatedly after damage; already-at-B redundant requests; stale WalkSpeed enabled flag; wrong fresh speed default/slider context; fixed swatches overwritten by button animation; menu-relative notifications; missing image-load failure handling.

## References, settings and performance

Source mechanisms studied and attribution/content hashes are in FEATURE_REPAIR_LOG. No external script is executed or downloaded at runtime. No new dependency is installed. New keys/default changes and the UI callback contract are fully listed in CODEX_TO_CLAUDE_UI_HANDOFF and the exported settings catalog.

Auto → 60 preserves the selected sampling budget; it does not guarantee a 60Hz presentation on a slower frame loop. In the short two-dummy intermediate Studio sample, Off mean/p95/p99 were 16.661/18.391/18.593ms; Auto were 17.635/21.496/22.019ms, ~56.47 geometry/presentation Hz, mean geometry CPU 0.564ms, zero default visibility rays. These are not GPU measurements or a controlled before/after previous-release comparison. 120/144Hz were not benchmarked.

## Preservation, owner tests and Claude handoff

All-ref/source/evidence/settings backup: `C:\Users\ASUS\ervi-functional-preservation-20261114-052242`. Installed Potassium copies remain v3.4.0 hash `e27fe7f83d2c2abf9625e5eb30092a762b7acb1331208559f747197aebd8d26c`; autoexec remains empty. The protected pre-autosave backup and autoexec flag hash are unchanged. The current settings file changed in **statusX/statusY/winW/winH** during this session; its newer geometry is retained, not replaced by the starting backup.

Required owner acceptance: approve loading this concrete candidate, verify one nearby Ctrl + M1 move in RNG RollAttacks with an independent observer, then capture or supply Zone B coordinates. Verify roll/protection indicators separately. See MOVEMENT_AND_SAFEZONE_TESTS for exact steps and remaining gates. No release should be published merely because the fixture succeeds.

Claude functional/UI handoff: **prepared**, `reports/CODEX_TO_CLAUDE_UI_HANDOFF.md`. Final visual redesign, circular picker polish and complete physical UI regression remain for the next approved stage. Files changed are recorded by the local development commits; source changes are in modular controllers, App/Expansion/schema/settings/Ui/Visuals, with matching tests, generated artifacts and reports. Main and release history are not modified.

## Files and local checkpoints

Code checkpoint: `b5c9c8f7c9edcb6ff15b03b883b443236059bbf2`, preceded by `e037c91` for Click TP/destination foundations. Both are local on the development branch.

- Source: `App`, `Background`, `ClickTP`, `EmergencyState`, `Expansion`, `FeatureSchema`, `Flight`, `ImageSource`, `Keybinds`, `LocalFlight`, `LocationControls`, `MovementAttempt`, `MovementTransport`, `PlayerTools`, `PositionData`, `SafeZone`, `Settings`, `Ui`, `VisualPolicy`, `VisualPreview`, `Visuals` (`src/*.luau`).
- Build: `build.py`, generated `build/Ervi_Hub.luau`, its map, and `build/loader.lua`.
- Tests: `Expansion`, `ImageSource`, `Keybinds`, `MovementAttempt`, `MovementPolicy`, `PositionData`, `RequestedControls` specs; `tests/run.luau`; smoke driver/engine; Studio functional acceptance script and source snapshot helper.
- Documentation: AGENTS, README, HANDOFF, CHANGELOG, task ledger, UI checklist, the five functional reports and verified evidence directory.
