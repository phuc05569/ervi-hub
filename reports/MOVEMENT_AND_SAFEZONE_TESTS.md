## Current movement contract — 3.5.0-dev+cf9fd777b960

**IMPLEMENTED — OWNER TESTING PENDING.** No tests or game automation run. Owner reported the previous B root anchor delayed server-observed position, so that controller is removed.

B now runs one explicit transaction: move through shared transport; after local arrival and about 0.1s, create a separate AlignPosition hover for about one second; destroy it; after a known first-move result and an idle transport, make exactly one final B move. Failed/uncertain/displaced/anchored/changed characters stop the transaction. New B requests supersede old observers/resources; an already delivered owned-server command cannot be retracted, so the new transaction waits for readiness with a bounded deadline. No endless teleports or anchor writes. The owned Studio server/protocol is unchanged and was not run.

[AlignPosition reference](https://create.roblox.com/docs/reference/engine/classes/AlignPosition): ZoneHover uses a non-rigid one-attachment position goal with bounded force/12-stud/s velocity and responsiveness 12. It never writes CFrame or network ownership. The user's actual Fly/Noclip controllers are suspended with settings/keys unchanged, then restored from current intent. The temporary controller does not simulate F or turn Fly preferences on/off. Native replication still requires owner confirmation.

A is now Auto Roll Safe Zone, a logical toggle in Auto Roll directly below Start/Stop/Continue. ON captures the activation origin once and makes one A move, then continuous low-overhead hover. OFF releases hover and attempts one return to that origin (finite/place/death-height/character checks); no arbitrary fallback. The original origin survives death/respawn, and ready living new roots re-enter A once without re-toggling. It never starts or stops Auto Roll and never forces roll readiness. Runtime session state is not auto-enabled across a full hub reload.

Emergency B cancels A physics while retaining its toggle/origin. A resumes only after health clears (or emergency is disabled) and the B sequence completes. Manual B suspends A until B OFF. A OFF during a continuing low-health emergency suppresses the dangerous return. Explicit Click TP suspends A while retaining its logical toggle/origin, without returning; correction releases hover and waits for OFF/ON or respawn rather than fighting the server. Death/root/Humanoid replacement/unload remove controllers and scoped listeners. Movement lifecycle checks and transaction sequencing share one cheap active-only Heartbeat callback; constraints handle hover without per-frame teleport writes.

Coordinates are unchanged: A `(350.647675,-435.796021,26.535965)`, B `(296.613495,59.0999985,-100.878853)`, place `119338513416973`, stored overrides first. No coordinate editors/named positions restored. None of this proves rollability, immunity or server-observed arrival. All owner acceptance remains pending.

### Historical movement evidence follows

---

## Current movement implementation — 3.5.0-dev+6abfd1dd3905

**IMPLEMENTED — OWNER TESTING PENDING.** Owner now handles all testing. No tests or live automation were run for these changes. Existing evidence below belongs to earlier builds.

A now shares Click TP/B's native MoveTo or existing owned-server adapter instead of persistent anchored PivotTo. Only explicit A OFF attempts a one-shot return to its activation origin; unload/death/correction have no return. A is never stabilized. No InFFA/roll/protection attributes or target-game remotes are modified. Roll status is displayed read-only. Owner's recovered A position is `(350.647675,-435.796021,26.535965)` and remains unchanged even though rollability is unresolved.

B `(296.613495,59.0999985,-100.878853)` has one two-second hold after local arrival, with velocity clearing and owned anchor restoration. It never counter-teleports. A calm observation below 20 studs/s rearms a fresh fling edge above 60 studs/s while within 12 studs of B. Moving beyond that distance releases the zone. External unanchoring/position correction also releases without retry. No permanent anchor or overlapping timer tasks. The feature scopes/lifecycle close all hold watchers. Manual B while already within six studs does not issue another move. Emergency retains its low-health recovery latch and gains the same stabilization.

The established defaults are place-scoped to 119338513416973; saved overrides have precedence. Coordinate-editing/capture/save/reset and named Saved Positions controls are gone. Legacy data stays in persistence; no settings/backups were overwritten. Flight/Noclip and a successful Click TP release zone ownership before taking over. Toggle Fly remains on when unfocused with neutral input; Hold release behavior is retained. The authorized Studio server fixture was not modified or run.

Owner reports Click TP/emergency working and B protected/unrollable on the previous dev script. This is not fresh verification of the new stabilization or A rollability. Original acceptance instructions below about approval/configuring B are historical and superseded by manual owner testing.

### Historical evidence follows

---

# Movement and Safe Zone verification — 14 November 2026

Development candidate: **3.5.0-dev+b391196c1bb3**. Published v3.4.0 is unchanged. No new build was deployed to Potassium or pushed.

## Evidence boundaries

`evidence/functional-3.4/` names the baseline release being repaired; its new files contain both intermediate and final development evidence. Mock results are not live tests. Studio is the owner's unpublished `ErviUITest.rbxlx`, PlaceId/GameId 0. It is not RNG RollAttacks. No new combat or other-player movement was initiated.

| Feature / test | Environment, action and expected behavior | Actual result / evidence | Status |
|---|---|---|---|
| Click TP, one shot | Real bundle in mock engine: aim, click, rapid second click | One native MoveTo, busy exclusion, no duplicate move; marker lifecycle assertions pass | WORKING — HEADLESS VERIFIED ONLY for integration |
| Ctrl + M1 | Owned Studio client, actual Studio input events; hold Ctrl and click floor | Local displacement 6.918 studs; observer reported local evidence; `studio-click-client.json` | WORKING — LIVE VERIFIED in Studio |
| Replication | Independently read owned Studio server after native click | Immediate read still had old position; a later read was `(6.2170, 3.5191, -3.0420)`, matching client `(6.2157, 3.5227, -3.0417)` within 0.004 studs | Studio replication only; target game UNVERIFIED |
| GUI / sky suppression | Same Studio session, click owned GUI barrier, then sky while Ctrl held | Both had 0 displacement, no marker; `studio-click-gui.json`, `studio-click-sky.json` | WORKING — LIVE VERIFIED in Studio |
| Modifier release / cleanup | Release Ctrl, dispose feature scope | Marker disappeared; no owned marker remained | WORKING — LIVE VERIFIED in Studio |
| Correction, death, respawn | Pure observer + integration lifecycle | Position correction cancels without retry; changed/dead character cannot finish an old attempt; character caches reset | WORKING — HEADLESS VERIFIED ONLY |
| Owned server protocol | Final native acceptance uses saved B root coordinates and fixture adapter | First investigation failed `Invalid landing surface`; fixed root-vs-ground payload mismatch and max-500 range. Final test acknowledges move and keeps selection active | WORKING — LIVE VERIFIED in Studio |
| Zone A | Existing scoped hold/origin-return suite retained; configurable coordinates added | OFF/unload return once before releasing anchor; death/removal/correction release without return. Correct original anchor and zeroed velocities retained | WORKING — HEADLESS VERIFIED ONLY for new build |
| Zone A rollability | Historical `(278.78, -16.30, 7.82)` in target place | Owner-reported historical behavior; not retested in RNG RollAttacks | UNVERIFIED in this build |
| Zone B setup | Capture/manual finite XYZ, save/reset/test; PlaceId persisted | Named B destination round trips; missing/wrong-place data cannot move | WORKING — HEADLESS VERIFIED ONLY for controls |
| Emergency | 30% inclusive default, 0–100 range; configure B while low; repeated damage, recovery, already-at-B, move away, new low event | One movement per recovery cycle; no missing-destination move, no spam, no unnecessary request while already at B | WORKING — HEADLESS VERIFIED ONLY for all edge cases |
| Emergency native | Final `FunctionalAcceptance.client.luau` | Missing B refused, configured B moved locally, continued low health did not repeat, OFF did not return | WORKING — LIVE VERIFIED in Studio |
| Zone B protection | Target game's roll prohibition / protection | No coordinates supplied and no protection API established. No invulnerability or ForceField created | UNVERIFIED / requires owner configuration |
| WalkSpeed | Set 16/25/50/100; Multiply 1.5; external change | Exact requested values observed on Humanoid in Studio; external 23 clears enabled/active state without retry. Actual travel speed remains separately observed | WORKING — LIVE VERIFIED in Studio |
| Fly | Modern native constraints, direction input, stopping | W produced 21.934 studs displacement; after disable mover removed, speed ~0.056 studs/s on floor. `studio-flight-direction.json` | WORKING — LIVE VERIFIED in Studio; target replication UNVERIFIED |
| Fly + Noclip | Independently and together, original true/false collision values, active unload | Native Studio flags/constraints observed; headless tests confirm original values, cached-part maintenance, no leaked scopes or forces | WORKING — LIVE VERIFIED for activation in Studio; passage through server geometry UNVERIFIED |
| Key modes | Toggle/Hold/Always/NONE, repeat, key release, focus loss, rebind | Central dispatcher unit tests pass. Actual Studio down/up RightShift minimizes/reopens centered; F creates and removes owned-server flight mover | Mixed live/headless; `studio-key-toggle-*.json` |
| Position tools | Save, display, rename, delete, copy | Data-only named entries with place IDs; copy produces `Vector3.new(x, y, z)`; fallback displays expression | WORKING — HEADLESS VERIFIED ONLY |

## Mechanics and limits

Native `MoveTo` is one attempt followed by an 0.8-second bounded observer, not a server API. A six-stud acceptance tolerance accommodates native landing adjustment; explicit correction after an observation cancels, with no counter-teleport. Observation does not establish game protection. The owned fixture repeats landing/range/cooldown validation on the server.

Zone A retains the legacy local hold because the requested original feature stays available. Zone B never automatically returns to its activation origin. The emergency latch rearms after health exceeds the threshold or a new character begins; recovery while disabled is recognized. A missing root waits for character loading rather than consuming the event.

Native Noclip maintains only cached local character collision flags during PreSimulation, as the reference's collision mechanism requires. It does not set server collision groups, change map geometry, rewrite position to defeat corrections, or prove passage through server-controlled geometry. The existing authorized Studio server's independent collision-group controller remains unchanged.

## Exact owner-assisted target-game acceptance

First approve loading this development candidate; do not replace the published release yet. In RNG RollAttacks, enable Click TP, hold Ctrl and click nearby clear ground once. Confirm the destination on another consenting client and check the game's own location indicator. Then configure B using **Safe Zone → Zone B → Capture Current Position → Save Location**, or supply XYZ. Independently verify whether rolling is prohibited and protection is actually recognized there. No combat is required for the UI/movement tests. Do not intentionally risk a valued aura to establish protection.

Remaining: target-game acceptance, second-client flight/noclip replication, full physical drag/rebind/dropdown/resize regression, actual B protection and rollability. These are not silently treated as passed.

An earlier final-candidate run detected one post-flight/startup movement correction. A later isolated move and traced full run succeeded; the cause is unestablished. Both the failed assertion and successful trace are retained. Disabling prevents new requests and cancels observation; a request already delivered to the owned server cannot be retracted through the existing protocol.

## Client-visible zone indicators

Historical read-only evidence in `reports/CONTINUATION_3_2_0.md` and `reports/evidence/continuation/live-client-checks.json` includes character `SafeZoneShield` ForceFields. Their names/presence are candidate client-visible indicators, not a verified immunity contract. Existing `Game.rollStatus()` observes `InFFA`, `RollReadyAt`, reveal/confirmation and alive state without making a roll request. These normal roll gates can help compare A/B after an approved target-game move; they do not identify B or establish protection. No new target-game observation was made in this continuation and no shield was manufactured.
