# Combat feasibility — 14 November 2026

Status: **UNSUPPORTED for automatic target-game attacks; investigation incomplete for live combat.** No automated combat was executed in this continuation.

`src/Game.luau` reads the equipped style and cached replicated `AttackData`; this is descriptive data, not damage authority. `src/M1.luau` observes `AttackReadyAt` against server time. The timestamp's cross-style cooldown meaning remains unverified. Cyborg V6 has a historical owner-verified effect proxy; that does not establish universal attack readiness. Existing target selection reads replicated Humanoid Health/MaxHealth and does not validate server damage eligibility.

No supported normal attack adapter, consenting second test account, target-game damage acknowledgement, safe-zone eligibility API, or per-style skill initiation contract is established in the repository. The owned Studio movement protocol has no combat action. Native character movement does not prove damage validation or protection behavior. Therefore no remotes were guessed, hooked, spammed, or added, and no fake functional Auto Kill switch was created. Existing request-only preference is explicitly described as unsupported.

To advance: in an authorized game/test fixture, observe one ordinary manual M1 and one E skill per tested style, record equipped style/readiness/target distance and a separately observed target-health result, then implement an adapter only against an established normal mechanic. Use a consenting account or owned dummy. Preserve ordinary cooldowns, safe-zone and target validation. A missing or uncertain result must stop rather than retry.

Live target-game attacks and movement-plus-hit registration were **not tested**. No combat support claim is made.

## Client-visible zone indicators

Historical read-only evidence in `reports/CONTINUATION_3_2_0.md` and `reports/evidence/continuation/live-client-checks.json` includes character `SafeZoneShield` ForceFields. Their names/presence are candidate client-visible indicators, not a verified immunity contract. Existing `Game.rollStatus()` observes `InFFA`, `RollReadyAt`, reveal/confirmation and alive state without making a roll request. These normal roll gates can help compare A/B after an approved target-game move; they do not identify B or establish protection. No new target-game observation was made in this continuation and no shield was manufactured.
